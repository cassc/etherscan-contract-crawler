// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILiquidityLockerMinimalProxy {

    function createVestingSchedule(address _beneficiary, uint256 _amount)
        external;

    function transferOwnership(address newOwner) external;
}