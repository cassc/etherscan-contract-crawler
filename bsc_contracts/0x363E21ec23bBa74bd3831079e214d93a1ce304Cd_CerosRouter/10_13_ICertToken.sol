// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface ICertToken is IERC20 {

    function burn(address account, uint256 amount) external;

    function mint(address account, uint256 amount) external;

    function balanceWithRewardsOf(address account) external returns (uint256);

    function isRebasing() external returns (bool);

    function ratio() external view returns (uint256);
}