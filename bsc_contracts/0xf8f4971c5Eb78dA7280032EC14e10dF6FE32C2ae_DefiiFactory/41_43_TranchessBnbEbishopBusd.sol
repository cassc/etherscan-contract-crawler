// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Defii} from "../Defii.sol";

contract TranchessBnbEbishopBusd is Defii {
    IERC20 constant BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IERC20 constant CHESS = IERC20(0x20de22029ab63cf9A7Cf5fEB2b737Ca1eE4c82A6);
    IERC20 constant USDC = IERC20(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);
    IERC20 constant lpToken =
        IERC20(0x00d150c057F5d66107Dfdb9d6d97F8B53eBd4D7A);

    IStableSwap constant pool =
        IStableSwap(0x87585A84E0A04b96e653de3DDA77a3Cb1fdf5B6a);
    IFund constant fund = IFund(0x1F18cC2b50575A71dD2EbF58793d4e661a7Ba0e0);
    IClaimRewards constant shareStaking =
        IClaimRewards(0xaF098f9AAdAd3bD8C9fc17CA16C7148f992Aa1b4);
    IClaimRewards constant liquidityGauge =
        IClaimRewards(0x00d150c057F5d66107Dfdb9d6d97F8B53eBd4D7A);
    IRouter constant pancakeSwapRouter =
        IRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    uint256 constant TRANCHE_B = 1;

    function harvestParams() external view returns (bytes memory params) {
        address[] memory path = new address[](2);
        path[0] = address(CHESS);
        path[1] = address(USDC);

        // Price for 1.0 CHESS
        uint256[] memory prices = pancakeSwapRouter.getAmountsOut(1e18, path);
        params = abi.encode((prices[1] * 99) / 100);
    }

    function hasAllocation() external view override returns (bool) {
        return lpToken.balanceOf(address(this)) > 0;
    }

    function _enter() internal override {
        BUSD.transfer(address(pool), BUSD.balanceOf(address(this)));
        pool.addLiquidity(fund.getRebalanceSize(), address(this));
    }

    function _exit() internal override {
        uint256 version = fund.getRebalanceSize();

        (uint256 baseOut, ) = pool.removeLiquidity(
            version,
            lpToken.balanceOf(address(this)),
            0,
            0
        );

        fund.trancheTransfer(TRANCHE_B, address(pool), baseOut, version);
        uint256 realQuoteOut = pool.sell(
            version,
            pool.getQuoteOut(baseOut),
            address(this),
            bytes("")
        );

        // Slippage: 0.05%
        uint256 minQuoteOut = (baseOut * pool.getOraclePrice() * 995) /
            1000 /
            1e18;
        require(realQuoteOut >= minQuoteOut, "Slippage BISHOP -> BUSD");
    }

    function _harvestWithParams(bytes memory params) internal override {
        uint256 minPrice = abi.decode(params, (uint256));

        _claim();
        _sellReward(minPrice);
    }

    function _withdrawFunds() internal override {
        _withdrawERC20(BUSD);
    }

    function _claim() internal {
        shareStaking.claimRewards(address(this));
        liquidityGauge.claimRewards(address(this));
    }

    function _sellReward(uint256 minPrice) internal {
        uint256 chessBalance = CHESS.balanceOf(address(this));
        uint256 amountOutMin = (chessBalance * minPrice) / 1e18;

        if (minPrice > 0 && amountOutMin == 0) {
            return;
        }

        address[] memory path = new address[](2);
        path[0] = address(CHESS);
        path[1] = address(USDC);
        CHESS.approve(address(pancakeSwapRouter), chessBalance);
        pancakeSwapRouter.swapExactTokensForTokens(
            chessBalance,
            amountOutMin,
            path,
            address(this),
            block.timestamp
        );
        _withdrawERC20(USDC);
    }
}

interface IStableSwap {
    function addLiquidity(uint256 version, address recipient)
        external
        returns (uint256 lpOut);

    function removeLiquidity(
        uint256 version,
        uint256 lpIn,
        uint256 minBaseOut,
        uint256 minQuoteOut
    ) external returns (uint256 baseOut, uint256 quoteOut);

    function sell(
        uint256 version,
        uint256 quoteOut,
        address recipient,
        bytes calldata data
    ) external returns (uint256 realQuoteOut);

    function getQuoteOut(uint256 baseIn)
        external
        view
        returns (uint256 quoteOut);

    function getOraclePrice() external view returns (uint256);

    function currentVersion() external returns (uint256);
}

interface IClaimRewards {
    function claimRewards(address account) external;
}

interface IFund {
    function getRebalanceSize() external returns (uint256);

    function trancheTransfer(
        uint256 tranche,
        address recipient,
        uint256 amount,
        uint256 version
    ) external;
}

interface IRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] memory path)
        external
        view
        returns (uint256[] memory amounts);
}