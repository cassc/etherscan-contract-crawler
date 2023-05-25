// SPDX-License-Identifier: BUSL-1.1
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.0;

interface IGrainLGE {
    function userShares(address user) external view returns (uint256, uint256, uint256, uint256, address, uint256);
    function whitelistedBonuses(address nft) external view returns (uint256);
    function grain() external view returns (IERC20);
    function lgeEnd() external view returns (uint256);
}