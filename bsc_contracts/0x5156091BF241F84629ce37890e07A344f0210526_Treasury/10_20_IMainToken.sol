// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMainToken is IERC20 {
    function grantRebaseExclusion(address account) external;
    function revokeRebaseExclusion(address account) external;
    function getExcluded() external view returns (address[] memory);
    function circulatingSupply() external view returns (uint256);
    function mint(address recipient, uint256 amount) external returns (bool);
    function maximumAmountSellPercent() external view returns (uint256);
}