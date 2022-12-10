// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@uniswap/lib/contracts/libraries/Babylonian.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol';

import "./../interface/ILiquidCVaultV6.sol";
import "./../interface/curve/ICurveSwap.sol";
import "./../interface/curve/IStrategyCurveLP.sol";


contract LiquidCZapCurve {
    using LowGasSafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for ILiquidCVaultV6;

    uint256 public constant minimumAmount = 1000;

    constructor() {}

    receive() external payable {}

    function LiquidCIn (address liquidCVault, uint256 tokenAmountOutMin, address tokenIn, uint256 tokenInAmount) external {
        require(tokenInAmount >= minimumAmount, 'LiquidC: Insignificant input amount');
        require(IERC20(tokenIn).allowance(msg.sender, address(this)) >= tokenInAmount, 'LiquidC: Input token is not approved');

        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), tokenInAmount);
        uint256 depositBal = IERC20(tokenIn).balanceOf(address(this));

        ILiquidCVaultV6 vault = ILiquidCVaultV6(liquidCVault);
        IStrategyCurveLP strategy = IStrategyCurveLP(vault.strategy());
        address pool = strategy.pool();
        address lpToken = vault.want();
        bool useUnderlying = strategy.useUnderlying();
        bool useMetapool = strategy.useMetapool();
        uint256 poolSize = strategy.poolSize();
        uint256 depositIndex = 0;
        for (uint256 x=0; x<poolSize; x++) {
            if (strategy.inputTokens(x) == tokenIn) {
                depositIndex = x;
                break;
            }
        }

        _approveTokenIfNeeded(tokenIn, pool);

        if (poolSize == 2) {
            uint256[2] memory amounts;
            amounts[depositIndex] = depositBal;
            ICurveSwap(pool).add_liquidity(amounts, 0, true);
        } else if (poolSize == 3) {
            uint256[3] memory amounts;
            amounts[depositIndex] = depositBal;
            if (useUnderlying) ICurveSwap(pool).add_liquidity(amounts, 0, true);
            else if (useMetapool) ICurveSwap(pool).add_liquidity(lpToken, amounts, 0);
            else ICurveSwap(pool).add_liquidity(amounts, 0);
        } else if (poolSize == 4) {
            uint256[4] memory amounts;
            amounts[depositIndex] = depositBal;
            if (useMetapool) ICurveSwap(pool).add_liquidity(lpToken, amounts, 0);
            else ICurveSwap(pool).add_liquidity(amounts, 0);
        } else if (poolSize == 5) {
            uint256[5] memory amounts;
            amounts[depositIndex] = depositBal;
            ICurveSwap(pool).add_liquidity(amounts, 0);
        }

        _approveTokenIfNeeded(address(lpToken), address(liquidCVault));
        uint256 amountLiquidity = IERC20(lpToken).balanceOf(address(this));
        vault.deposit(amountLiquidity);

        vault.safeTransfer(msg.sender, vault.balanceOf(address(this)));
    }

    function LiquidCOut (address liquidCVault, uint256 withdrawAmount) external {
        ILiquidCVaultV6 vault = ILiquidCVaultV6(liquidCVault);
        IStrategyCurveLP strategy = IStrategyCurveLP(vault.strategy());
        address pool = strategy.pool();
        address lpToken = vault.want();
        uint256 poolSize = strategy.poolSize();
        address[] memory tokens = new address[](poolSize);
        for (uint256 x=0; x<poolSize; x++) {
            tokens[x] = strategy.inputTokens(x);
        }

        IERC20(liquidCVault).safeTransferFrom(msg.sender, address(this), withdrawAmount);
        vault.withdraw(withdrawAmount);

        _approveTokenIfNeeded(lpToken, pool);

        uint256 amountLiquidity = IERC20(lpToken).balanceOf(address(this));
        ICurveSwap(pool).remove_liquidity(amountLiquidity, uint256(0));

        _returnAssets(tokens);
    }

    function LiquidCOutAndSwap(address liquidCVault, uint256 withdrawAmount, address desiredToken, uint256 desiredTokenOutMin) external {
        ILiquidCVaultV6 vault = ILiquidCVaultV6(liquidCVault);
        IStrategyCurveLP strategy = IStrategyCurveLP(vault.strategy());
        address pool = strategy.pool();
        address lpToken = vault.want();
        uint256 poolSize = strategy.poolSize();
        int128 desiredIndex = 0;
        for (uint256 x=0; x<poolSize; x++) {
            if (strategy.inputTokens(x) == desiredToken) {
                desiredIndex = int128(int(x));
                break;
            }
        }

        IERC20(liquidCVault).safeTransferFrom(msg.sender, address(this), withdrawAmount);
        vault.withdraw(withdrawAmount);

        _approveTokenIfNeeded(lpToken, pool);

        uint256 amountLiquidity = IERC20(lpToken).balanceOf(address(this));
        ICurveSwap(pool).remove_liquidity_one_coin(amountLiquidity, desiredIndex, desiredTokenOutMin);

        address[] memory tokens = new address[](1);
        tokens[0] = desiredToken;

        _returnAssets(tokens);
    }

    function _returnAssets(address[] memory tokens) private {
        uint256 balance;
        for (uint256 i; i < tokens.length; i++) {
            balance = IERC20(tokens[i]).balanceOf(address(this));
            if (balance > 0) {
                IERC20(tokens[i]).safeTransfer(msg.sender, balance);
            }
        }
    }

    function _approveTokenIfNeeded(address token, address spender) private {
        if (IERC20(token).allowance(address(this), spender) == 0) {
            IERC20(token).safeApprove(spender, type(uint256).max);
        }
    }
}