// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Defii} from "../Defii.sol";

contract WombexBnbBusd is Defii {
    IERC20 constant BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 constant WOM = IERC20(0xAD6742A35fB341A9Cc6ad674738Dd8da98b94Fb1);
    IERC20 constant WMX = IERC20(0xa75d9ca2a0a1D547409D82e1B06618EC284A2CeD);

    IAsset constant lpBusd = IAsset(0xF319947eCe3823b790dd87b0A509396fE325745a);
    IBooster constant booster = IBooster(0x9Ac0a3E8864Ea370Bf1A661444f6610dd041Ba1c);
    IPoolDepositor constant poolDepositor = IPoolDepositor(0xBc502Eb6c9bAD77929dabeF3155967E0ABfA9209);

    function hasAllocation() external view override returns (bool) {
        uint256 pid = poolDepositor.lpTokenToPid(address(lpBusd));
        IBooster.PoolInfo memory poolInfo = booster.poolInfo(pid);
    
        IRewards rewardPool = IRewards(poolInfo.crvRewards);
        return rewardPool.balanceOf(address(this)) > 0;
    }

    function _enter() internal override {
        uint256 busdAmount = BUSD.balanceOf(address(this));
        IPool pool = IPool(lpBusd.pool());
        BUSD.approve(address(pool), busdAmount);
        uint256 liquidity = pool.deposit(
            address(BUSD),
            busdAmount,
            (busdAmount * 9995) / 10000,
            address(this),
            block.timestamp,
            false
        );

        uint256 pid = poolDepositor.lpTokenToPid(address(lpBusd));
        require(address(lpBusd) == booster.poolInfo(pid).lptoken);
        lpBusd.approve(address(booster), liquidity);
        booster.deposit(pid, liquidity, true);
    }

    function _exit() internal override {
        _harvest();
        uint256 pid = poolDepositor.lpTokenToPid(address(lpBusd));
        IBooster.PoolInfo memory poolInfo = booster.poolInfo(pid);
        IRewards rewardPool = IRewards(poolInfo.crvRewards);

        uint256 lpAmount = rewardPool.balanceOf(address(this));
        rewardPool.approve(address(poolDepositor), lpAmount);
        poolDepositor.withdraw(
            address(lpBusd),
            rewardPool.balanceOf(address(this)),
            0,
            address(this)
        );
    }

    function _harvest() internal override {
        uint256 pid = poolDepositor.lpTokenToPid(address(lpBusd));
        IBooster.PoolInfo memory poolInfo = booster.poolInfo(pid);
        IRewards rewarder = IRewards(poolInfo.crvRewards);
        rewarder.getReward();
        withdrawERC20(WOM);
        withdrawERC20(WMX);
    }

    function _withdrawFunds() internal override{
        withdrawERC20(BUSD);
     }

}

interface IPool {
    function deposit(
        address token,
        uint256 amount,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external returns (uint256);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);
 
}

interface IPoolDepositor {
    function deposit(
        address _lptoken,
        uint256 _amount,
        uint256 _minLiquidity,
        bool _stake
    ) external;

    function withdraw(
        address _lptoken,
        uint256 _amount,
        uint256 _minOut,
        address _recipient
    ) external;

    function lpTokenToPid(address lpToken) external view returns(uint256);

}

interface IAsset is IERC20 {
    function pool() external view returns (address);
}

interface IBooster {
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        bool shutdown;
    }

    function poolInfo(uint256 _pid) external view returns(PoolInfo memory);
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns(bool);
}

interface IRewards is IERC20 {
    function getReward() external returns(bool);
}