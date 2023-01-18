// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IABNBC is IERC20 {
    function ratio() external view returns (uint256);
    function mint(address, uint256) external;
    function sharesToBonds(uint256 amount) external view returns (uint256);
    function bondsToShares(uint256 amount) external view returns (uint256);
    function burn(address, uint256) external;
}