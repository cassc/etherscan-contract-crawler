// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;

import { IERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts-0.8/token/ERC20/utils/SafeERC20.sol";
import { AuraMath } from "../utils/AuraMath.sol";
import { IAuraDepositor } from "../interfaces/IAuraDepositor.sol";
import { IAuraLocker } from "../interfaces/IAuraLocker.sol";

interface IDepositForPool {
    function depositFor(uint256 _amount, address _account) external returns (bool);
}

/**
 * @title   AuraDepositZap
 * @author  KaiFinance
 * @notice  Zap to deposit to KaiLocker and deposit to Reward Pool.
 */
contract AuraDepositZap {
    using SafeERC20 for IERC20;
    using AuraMath for uint256;

    constructor() {}

    function convertAndStake(
        IERC20 token,
        uint256 amount,
        IERC20 convertedToken,
        IAuraDepositor depositor,
        IDepositForPool rewardPool
    ) external {
        require(amount > 0, "!amt");

        token.transferFrom(msg.sender, address(this), amount);
        token.approve(address(depositor), amount);
        depositor.depositFor(msg.sender, amount);

        uint256 newBalance = convertedToken.balanceOf(address(this));
        require(newBalance > 0, "Failed to deposit");

        convertedToken.approve(address(rewardPool), newBalance);
        rewardPool.depositFor(newBalance, msg.sender);
    }
}