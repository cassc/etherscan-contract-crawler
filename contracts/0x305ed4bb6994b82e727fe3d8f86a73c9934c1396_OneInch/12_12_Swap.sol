// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "../errors.sol";
import {ISwapFactory} from "../interfaces/ISwapFactory.sol";
import {DefiOp} from "../DefiOp.sol";

abstract contract Swap is DefiOp {
    modifier checkToken(address token) {
        if (!ISwapFactory(factory).isTokenWhitelisted(token))
            revert UnsupportedToken();
        _;
    }
}