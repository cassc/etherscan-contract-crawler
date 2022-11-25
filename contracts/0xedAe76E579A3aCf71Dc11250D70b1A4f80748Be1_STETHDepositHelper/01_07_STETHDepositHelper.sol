// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import {ICurveETHSTETHPool} from "../interfaces/ICurveETHSTETHPool.sol";
import {IRibbonEarnVault} from "../interfaces/IRibbonEarnVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract STETHDepositHelper {
    using SafeERC20 for IERC20;

    ICurveETHSTETHPool public immutable curveETHSTETHPool;
    IRibbonEarnVault public immutable stETHEarnVault;
    IERC20 public immutable stETH;

    constructor(
        address _curveETHSTETHPool,
        address _stETHEarnVault,
        address _stETH
    ) {
        require(_curveETHSTETHPool != address(0), "!curveETHSTETH Pool");
        require(_stETHEarnVault != address(0), "!stETHEarnVault");
        require(_stETH != address(0), "!_stETH");

        curveETHSTETHPool = ICurveETHSTETHPool(_curveETHSTETHPool);
        stETHEarnVault = IRibbonEarnVault(_stETHEarnVault);
        stETH = IERC20(_stETH);
    }

    /**
     * Swaps ETH -> stETH on Curve ETH-stETH pool, and deposits into stETH vault
     */
    function deposit(uint256 minSTETHAmount) external payable {
        curveETHSTETHPool.exchange{value: msg.value}(
            0,
            1,
            msg.value,
            minSTETHAmount
        );
        uint256 balance = stETH.balanceOf(address(this));
        stETH.safeApprove(address(stETHEarnVault), balance);
        stETHEarnVault.depositFor(balance, msg.sender);
    }
}