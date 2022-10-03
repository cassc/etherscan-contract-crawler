//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IStakeDaoGauge.sol";

interface IStakeDaoVault is IERC20 {
    function liquidityGauge() external view returns (IStakeDaoGauge);
    function withdraw(uint256 amount) external;
    function deposit(address staker, uint256 amount, bool earn) external;
}