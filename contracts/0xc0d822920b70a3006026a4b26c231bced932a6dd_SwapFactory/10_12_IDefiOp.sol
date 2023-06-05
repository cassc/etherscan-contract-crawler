// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IDefiOp {
    function init(address owner_) external;

    function withdrawERC20(address token) external;

    function withdrawNative() external;
}