// SPDX-License-Identifier: Playchain
pragma solidity 0.8.13;

import "../CommonERC20.sol";


contract RootTokenERC20 is CommonERC20 {

    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");

    constructor(string memory name, string memory symbol) CommonERC20(name, symbol) {
        _setupRole(PREDICATE_ROLE, _msgSender());
    }

    function mint(address user, uint256 amount) external only(PREDICATE_ROLE) {
        _mint(user, amount);
    }

}