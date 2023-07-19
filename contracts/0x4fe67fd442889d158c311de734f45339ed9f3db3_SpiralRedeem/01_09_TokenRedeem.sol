// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import { IStaking } from "../interfaces/IStaking.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SpiralRedeem is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public constant spiral = IERC20(0x85b6ACaBa696B9E4247175274F8263F99b4B9180);
    IERC20 public constant coil = IERC20(0x823E1B82cE1Dc147Bbdb25a203f046aFab1CE918);
    IERC20 public constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IStaking public constant staking = IStaking(0x6701E792b7CD344BaE763F27099eEb314A4b4943);

    uint256 public spiralBacking;

    uint256 public PENALTY = 100;
    uint256 public constant PENALTY_UNITS = 1000;
    address public Treasury = 0xC47eC74A753acb09e4679979AfC428cdE0209639;
    constructor() {}

    /***************************
             RESTRICTED
    *****************************/

    //In decimals of USDC
    function setBacking(uint128 amount_) external onlyOwner {
        spiralBacking = amount_;
    }

    function setPenaltyPercent(uint256 penalty_) external onlyOwner {
        require(penalty_ <= PENALTY_UNITS);
        PENALTY = penalty_;
    }

    function withdrawERC20(address token_, uint256 amount_) external onlyOwner {
        IERC20(token_).safeTransfer(Treasury, amount_ == 0 ? IERC20(token_).balanceOf(address(this)) : amount_);
    }

    /***************************
                VIEW
    *****************************/

    function usdcRedeemAmount(uint128 amount_) external view returns(uint256) {
        uint256 usdcAmount = (amount_ * spiralBacking) / staking.index();
        uint256 penalty = (usdcAmount * PENALTY) / PENALTY_UNITS;
        uint256 redeemAmount = usdcAmount - penalty;
        return redeemAmount;
    }

    /***************************
                REDEEM
    *****************************/

    function redeem(uint128 amount_) external {
        uint256 usdcAmount = (amount_ * spiralBacking) / staking.index();
        uint256 penalty = (usdcAmount * PENALTY) / PENALTY_UNITS;
        uint256 redeemAmount = usdcAmount - penalty;

        coil.transferFrom(msg.sender, address(this), amount_);
        usdc.transfer(msg.sender, redeemAmount);
    }
}