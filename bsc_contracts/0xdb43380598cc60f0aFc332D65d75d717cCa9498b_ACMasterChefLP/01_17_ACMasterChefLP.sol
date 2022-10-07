// SPDX-License-Identifier: MIT

//// _____.___.__       .__       ._____      __      .__   _____  ////
//// \__  |   |__| ____ |  |    __| _/  \    /  \____ |  |_/ ____\ ////
////  /   |   |  |/ __ \|  |   / __ |\   \/\/   /  _ \|  |\   __\  ////
////  \____   |  \  ___/|  |__/ /_/ | \        (  <_> )  |_|  |    ////
////  / ______|__|\___  >____/\____ |  \__/\  / \____/|____/__|    ////
////  \/              \/           \/       \/                     ////

pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import './AutoCompoundVault.sol';

interface IFarm {
    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function userInfo(uint256 _pid, address _user) external view returns (uint256, uint256);

    function emergencyWithdraw(uint256 _pid) external;
}

/**
 * @title AutoCompound MasterChef
 * @notice vault for auto-compounding LPs on pools using a standard MasterChef contract
 * @author YieldWolf
 */
contract ACMasterChefLP is AutoCompoundVault {
    IUniswapV2Router02 public immutable liquidityRouter; // router used for adding liquidity to the LP token
    IERC20 public immutable token0; // first token of the lp
    IERC20 public immutable token1; // second token of the lp

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _pid,
        address[6] memory _addresses,
        IUniswapV2Router02 _liquidityRouter
    ) ERC20(_name, _symbol) AutoCompoundVault(_pid, _addresses) {
        token0 = IERC20(IUniswapV2Pair(_addresses[1]).token0());
        token1 = IERC20(IUniswapV2Pair(_addresses[1]).token1());
        liquidityRouter = _liquidityRouter;
        token0.approve(address(liquidityRouter), type(uint256).max);
        token1.approve(address(liquidityRouter), type(uint256).max);
    }

    function _earnToStake(uint256 _earnAmount) internal override {
        uint256 halfEarnAmount = _earnAmount / 2;
        if (earnToken != token0) {
            _safeSwap(halfEarnAmount, address(earnToken), address(token0));
        }
        if (earnToken != token1) {
            _safeSwap(_earnAmount - halfEarnAmount, address(earnToken), address(token1));
        }
        uint256 token0Amt = token0.balanceOf(address(this));
        uint256 token1Amt = token1.balanceOf(address(this));
        liquidityRouter.addLiquidity(
            address(token0),
            address(token1),
            token0Amt,
            token1Amt,
            1,
            1,
            address(this),
            block.timestamp
        );
    }

    function _farmDeposit(uint256 amount) internal override {
        IFarm(masterChef).deposit(pid, amount);
    }

    function _farmWithdraw(uint256 amount) internal override {
        IFarm(masterChef).withdraw(pid, amount);
    }

    function _farmEmergencyWithdraw() internal override {
        IFarm(masterChef).emergencyWithdraw(pid);
    }

    function _totalStaked() internal view override returns (uint256 amount) {
        (amount, ) = IFarm(masterChef).userInfo(pid, address(this));
    }

    function _addAllawences() internal override {
        IERC20(stakeToken).approve(masterChef, type(uint256).max);
        token0.approve(address(liquidityRouter), type(uint256).max);
        token1.approve(address(liquidityRouter), type(uint256).max);
    }

    function _removeAllawences() internal override {
        IERC20(stakeToken).approve(masterChef, 0);
        token0.approve(address(liquidityRouter), 0);
        token1.approve(address(liquidityRouter), 0);
    }
}