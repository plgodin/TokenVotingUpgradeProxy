// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import "./VotingEscrow.sol";


contract TokenVotingUpgradeProxy is ERC1967Proxy {
    using SafeMath for uint;

    address developer;
    VotingEscrow escrow;
    address previousImplementation;
    address proposedImplementation;
    mapping(address => uint) tokenWeights;
    uint votesInFavor;
    uint votesAgainst;

    enum State {Deployed, Voting}
    State state;

    constructor(VotingEscrow _escrow, address _firstImplementation) ERC1967Proxy(_firstImplementation, new bytes(0)) {
        developer = msg.sender;
        escrow = _escrow;
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

    function vote(bool inFavor) voting public payable {
        escrow.deposit{value: msg.value}(msg.sender);
        if (inFavor) {
            votesInFavor.add(msg.value);
        } else {
            votesAgainst.add(msg.value);
        }
    }

    function proposeUpgrade(address _proposedImplementation) onlyDev notVoting public {
        previousImplementation = _implementation();
        _upgradeTo(address(0));
        proposedImplementation = _proposedImplementation;
        state = State.Voting;
    }

    function applyOrDismissUpgrade() onlyDev voting public {
        state = State.Deployed;
        if (votesInFavor > votesAgainst) {
            _upgradeTo(proposedImplementation);
        } else {
            _upgradeTo(previousImplementation);
        }
    }
}