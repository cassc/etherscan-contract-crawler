// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./helpers/ERC20.sol";

import "../service/MetacryptHelper.sol";

contract Metacrypt_B_NC_X is ERC20, MetacryptHelper {
    constructor(
        address __metacrypt_target,
        string memory __metacrypt_name,
        string memory __metacrypt_symbol,
        uint256 __metacrypt_initial
    ) payable ERC20(__metacrypt_name, __metacrypt_symbol) MetacryptHelper("Metacrypt_B_NC_X", __metacrypt_target) {
        require(__metacrypt_initial > 0, "ERC20: supply cannot be zero");

        _mint(_msgSender(), __metacrypt_initial);
    }
}