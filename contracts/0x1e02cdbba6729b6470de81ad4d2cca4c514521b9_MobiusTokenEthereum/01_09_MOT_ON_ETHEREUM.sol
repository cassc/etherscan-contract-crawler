// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import '../base/Token.sol';

contract MobiusTokenEthereum is Token {
    address PREDICATE_ROLE;

    constructor(address addr) Token('Mobius Token','MOT',CONTRACT_MOBIUS_TOKEN) {
        PREDICATE_ROLE = addr;
    }

    function setPredicate(address addr) external onlyOwner {
        PREDICATE_ROLE = addr;
    }

    function mint(address account, uint256 amount) external onlyPredicateRole returns (bool) {
        _mint(account, amount);
        return true;
    }

    modifier onlyPredicateRole() {
        require(msg.sender == PREDICATE_ROLE, "msg.sender not PREDICATE_ROLE");
        _;
    }
}