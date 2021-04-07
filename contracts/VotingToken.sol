// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

contract VotingEscrow is ERC777 {
    constructor () ERC777("Voting Token", "VOT", new address[](0)) {
        _mint(msg.sender, 100, new bytes(0), new bytes(0));
    }
}