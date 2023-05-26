// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./base/BaseERC20Token.sol";

contract StellaToken is BaseERC20Token {
    // decimals is set to 18 by default
    string private constant _NAME = "Stella";
    string private constant _SYMBOL = "ST";
    uint256 private constant _TOTAL_SUPPLY = 2_000_000_000 ether;

    /**
     * @param admin the address holds default admin permission and other roles
     * @param forwarder the address of EIP-2771 trusted forwarder for native meta transaction
     * @param initialHolder the address holds minted token
     */
    constructor(
        address admin,
        address forwarder,
        address initialHolder
    ) BaseERC20Token(_NAME, _SYMBOL, admin, forwarder) {
        require(initialHolder != address(0), "initial holder address can not be zero");
        _mint(initialHolder, _TOTAL_SUPPLY);
    }
}