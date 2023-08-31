// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

abstract contract BaseFlashloanStrategy {
    function _takeFlashloan(address asset, uint256 amount, bytes memory data) internal virtual;

    function _insideFlashloan(address asset, uint256 amount, uint256 amountOwed, bytes memory data) internal virtual;
}