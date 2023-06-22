// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

// I couldnt find an official interface so I added the functions we need from here:
// https://github.com/FraxFinance/frxETH-public/blob/master/src/sfrxETH.sol
interface IsFrxEth {
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external payable returns (uint256 assets);

    function approve(address spender, uint256 amount) external returns (bool);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);
}