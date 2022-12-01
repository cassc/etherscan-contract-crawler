// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


interface IUnwrapLp {
    function unwrap(address assetLp, uint256 amount) external returns (address, uint256);
    function getAssetOut(address assetIn) external view returns (address);
}