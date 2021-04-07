// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/escrow/ConditionalEscrow.sol";

contract VotingEscrow is ConditionalEscrow {
    function withdrawalAllowed(address) public pure override returns (bool) {
        return false;
    }
}