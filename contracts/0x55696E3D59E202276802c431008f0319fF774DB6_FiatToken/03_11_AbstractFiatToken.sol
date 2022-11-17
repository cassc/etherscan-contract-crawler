// SPDX-License-Identifier: MIT
// Forked from https://github.com/centrehq/centre-tokens/blob/master/contracts/v1/AbstractFiatTokenV1.sol

pragma solidity ^0.8.0;

import {IERC20} from "IERC20.sol";

abstract contract AbstractFiatToken is IERC20 {
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal virtual;

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual;
}