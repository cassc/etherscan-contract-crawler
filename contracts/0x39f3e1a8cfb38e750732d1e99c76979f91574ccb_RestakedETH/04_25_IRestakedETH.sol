// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRestakedETH is IERC20 {

    function stakedTokenAddress() external view returns (address);

    function scaledBalanceOf(address who) external view returns (uint256);

    function scaledBalanceToBalance(uint256 scaledBalance) external view returns (uint256);

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function rebase(uint256 epoch, bool isRebasePositive, uint256 supplyDelta) external returns (uint256);

}