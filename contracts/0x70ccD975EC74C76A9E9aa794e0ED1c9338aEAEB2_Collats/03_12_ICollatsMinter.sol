// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface ICollatsMinter {
    function swapEthForBackUpAsset(address to)
        external
        payable
        returns (uint256);

    function swapTokenForBackUpAsset(
        address to,
        address token,
        uint256 amount
    ) external returns (uint256);

    function backUpAsset() external view returns (address);

    function backUpAssetDecimals() external view returns (uint256);

    function getAmountIn(address from, uint256 amountOut)
        external
        view
        returns (uint256);

    function getAmountOut(address from, uint256 amountIn)
        external
        view
        returns (uint256);
}