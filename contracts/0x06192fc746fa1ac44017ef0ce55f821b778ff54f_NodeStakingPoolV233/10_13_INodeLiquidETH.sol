// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INodeLiquidETH is IERC20 {
    function mint(address to, uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function getSharePrice() external view returns (uint256);

    function updateSharePrice(uint256 newSharePrice) external;

    function assetsToShares(uint256 assets) external view returns (uint256);

    function sharesToAssets(uint256 shares) external view returns (uint256);
}