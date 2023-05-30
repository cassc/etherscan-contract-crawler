// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISfrxEth is IERC20 {
    function previewRedeem(uint256 shares) external view returns (uint256);

    function previewWithdraw(uint256 assets) external view returns (uint256);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256);

    function syncRewards() external;

    function rewardsCycleEnd() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function pricePerShare() external view returns (uint256);
}