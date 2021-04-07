// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777.sol";

contract TokenVotingUpgradeProxy is ERC1967Proxy, IERC777Recipient {
    using SafeMath for uint;

    IERC777 votingToken;
    address developer;
    address previousImplementation;
    address proposedImplementation;
    mapping(address => uint) public votesInFavor;
    mapping(address => uint) public votesAgainst;
    mapping(address => uint) public tokenBalance;

    enum Vote {NotVoted, InFavor, Against}
    mapping(bytes32 => Vote) votes;
    enum State {Deployed, Voting}
    State state;

    constructor(IERC777 _votingToken, address _firstImplementation) ERC1967Proxy(_firstImplementation, new bytes(0)) {
        developer = msg.sender;
        votingToken = _votingToken;
    }

    modifier onlyDev() {
        require(msg.sender == developer);
        _;
    }

    modifier voting() {
        require(state == State.Voting);
        _;
    }

    modifier notVoting() {
        require(state != State.Voting);
        _;
    }

    function vote(bool inFavor) voting external {
        bytes32 voterId = keccak256(abi.encodePacked(proposedImplementation, msg.sender));
        if (inFavor) {
            votes[voterId] = Vote.InFavor;
        } else {
            votes[voterId] = Vote.Against;
        }
    }
    
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) override voting external {
        require(msg.sender == address(votingToken), "Only the voting token is accepted");
        bytes32 voterId = keccak256(abi.encodePacked(proposedImplementation, from));
        Vote senderVote = votes[voterId];
        require(senderVote != Vote.NotVoted, "Please have the token holder submit their vote before sending tokens.");

        if (senderVote == Vote.InFavor) {
            votesInFavor[proposedImplementation] = votesInFavor[proposedImplementation].add(amount);
        } else {
            votesAgainst[proposedImplementation] = votesAgainst[proposedImplementation].add(amount);
        }

        tokenBalance[from] = tokenBalance[from].add(amount);
    }

    function reclaimTokensFor(address holder) notVoting external {
        votingToken.send(holder, tokenBalance[holder], new bytes(0));
    }

    function proposeUpgrade(address _proposedImplementation) onlyDev notVoting public {
        require(votesAgainst[_proposedImplementation] == 0, "Proposed implementation was already voted on and rejected.");
        previousImplementation = _implementation();
        _upgradeTo(address(0));
        proposedImplementation = _proposedImplementation;
        state = State.Voting;
    }

    // TODO: callable by anyone after voting ends
    function applyOrRejectUpgrade() onlyDev voting public {
        state = State.Deployed;
        if (votesInFavor[proposedImplementation] > votesAgainst[proposedImplementation]) {
            _upgradeTo(proposedImplementation);
        } else {
            _upgradeTo(previousImplementation);
        }
    }
}