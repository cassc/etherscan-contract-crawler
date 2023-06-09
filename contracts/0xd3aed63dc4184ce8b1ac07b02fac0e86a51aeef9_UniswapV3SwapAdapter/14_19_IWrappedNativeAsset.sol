//SPDX-License-Identifier: UXUY
pragma solidity ^0.8.11;
import "./IERC20.sol";

interface IWrappedNativeAsset is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 recipient) external;
}