// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IPool {
    function getTokens() external view returns (address[] memory);

    function addressOfAsset(address token) external view returns (address);

    function deposit(
        address token,
        uint256 amount,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external returns (uint256 liquidity);

    function withdraw(
        address token,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function withdrawFromOtherAsset(
        address fromToken,
        address toToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);

    function quotePotentialDeposit(address token, uint256 amount)
    external
    view
    returns (uint256 liquidity, uint256 reward);

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        int256 fromAmount
    ) external view returns (uint256 potentialOutcome, uint256 haircut);

    function quotePotentialWithdraw(address token, uint256 liquidity)
    external
    view
    returns (uint256 amount, uint256 fee);

    function quoteAmountIn(
        address fromToken,
        address toToken,
        int256 toAmount
    ) external view returns (uint256 amountIn, uint256 haircut);
}


interface IAsset is IERC20 {
    function underlyingToken() external view returns (address);

    function pool() external view returns (address);

    function cash() external view returns (uint120);

    function liability() external view returns (uint120);

    function decimals() external view returns (uint8);

    function underlyingTokenDecimals() external view returns (uint8);

    function setPool(address pool_) external;

    function underlyingTokenBalance() external view returns (uint256);

    function transferUnderlyingToken(address to, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function burn(address to, uint256 amount) external;

    function addCash(uint256 amount) external;

    function removeCash(uint256 amount) external;

    function addLiability(uint256 amount) external;

    function removeLiability(uint256 amount) external;
}


interface IMasterWombatV2 {
    function userInfo(uint256 _pid, address account) external view returns(uint128 amount, uint128 factor, uint128 rewardDebt, uint128 pendingWom);

    function getAssetPid(address asset) external view returns (uint256 pid);

    function poolLength() external view returns (uint256);

    function pendingTokens(uint256 _pid, address _user)
    external
    view
    returns (
        uint256 pendingRewards,
        IERC20[] memory bonusTokenAddresses,
        string[] memory bonusTokenSymbols,
        uint256[] memory pendingBonusRewards
    );

    function rewarderBonusTokenInfo(uint256 _pid)
    external
    view
    returns (IERC20[] memory bonusTokenAddresses, string[] memory bonusTokenSymbols);

    function massUpdatePools() external;

    function updatePool(uint256 _pid) external;

    function deposit(uint256 _pid, uint256 _amount) external returns (uint256, uint256[] memory);

    function multiClaim(uint256[] memory _pids)
    external
    returns (
        uint256 transfered,
        uint256[] memory rewards,
        uint256[][] memory additionalRewards
    );

    function withdraw(uint256 _pid, uint256 _amount) external returns (uint256, uint256[] memory);

    function emergencyWithdraw(uint256 _pid) external;

    function migrate(uint256[] calldata _pids) external;

    function depositFor(
        uint256 _pid,
        uint256 _amount,
        address _user
    ) external;

    function updateFactor(address _user, uint256 _newVeWomBalance) external;
}


interface IWombatRouter {
    function getAmountOut(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        int256 amountIn
    ) external view returns (uint256 amountOut, uint256[] memory haircuts);

    /**
     * @notice Returns the minimum input asset amount required to buy the given output asset amount
     * (accounting for fees and slippage)
     * Note: This function should be used as estimation only. The actual swap amount might
     * be different due to precision error (the error is typically under 1e-6)
     */
    function getAmountIn(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 amountOut
    ) external view returns (uint256 amountIn, uint256[] memory haircuts);

    function swapExactTokensForTokens(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function swapExactNativeForTokens(
        address[] calldata tokenPath, // the first address should be WBNB
        address[] calldata poolPath,
        uint256 minimumamountOut,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountOut);

    function swapExactTokensForNative(
        address[] calldata tokenPath, // the last address should be WBNB
        address[] calldata poolPath,
        uint256 amountIn,
        uint256 minimumamountOut,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function addLiquidityNative(
        IPool pool,
        uint256 minimumLiquidity,
        address to,
        uint256 deadline,
        bool shouldStake
    ) external payable returns (uint256 liquidity);

    function removeLiquidityNative(
        IPool pool,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);

    function removeLiquidityFromOtherAssetAsNative(
        IPool pool,
        address fromToken,
        uint256 liquidity,
        uint256 minimumAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amount);
}


library WombatLibrary {

    struct CalculateParams {
        IWombatRouter wombatRouter;
        address token0;
        address token1;
        address token2;
        address pool0;
        uint256 amount0Total;
        uint256 totalAmountLpTokens;
        uint256 reserve0;
        uint256 reserve1;
        uint256 reserve2;
        uint256 denominator0;
        uint256 denominator1;
        uint256 denominator2;
        uint256 precision;
    }

    function getAmountOut(
        IWombatRouter wombatRouter,
        address token0,
        address token1,
        address pool0,
        uint256 amountIn
    ) internal view returns (uint256) {

        address[] memory tokenPath = new address[](2);
        tokenPath[0] = token0;
        tokenPath[1] = token1;

        address[] memory poolPath = new address[](1);
        poolPath[0] = pool0;

        (uint256 amountOut,) = wombatRouter.getAmountOut(
            tokenPath,
            poolPath,
            int256(amountIn)
        );

        return amountOut;
    }

    function swapExactTokensForTokens(
        IWombatRouter wombatRouter,
        address token0,
        address token1,
        address pool0,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to
    ) internal returns (uint256) {

        IERC20(token0).approve(address(wombatRouter), fromAmount);

        address[] memory tokenPath = new address[](2);
        tokenPath[0] = token0;
        tokenPath[1] = token1;

        address[] memory poolPath = new address[](1);
        poolPath[0] = pool0;

        return wombatRouter.swapExactTokensForTokens(
            tokenPath,
            poolPath,
            fromAmount,
            minimumToAmount,
            to,
            block.timestamp
        );
    }

    /**
     * Get amount of token1 nominated in token0 where amount0Total is total getting amount nominated in token0
     *
     */
    function getAmountToSwap(
        IWombatRouter wombatRouter,
        address token0,
        address token1,
        address pool0,
        uint256 amount0Total,
        uint256 reserve0,
        uint256 reserve1,
        uint256 denominator0,
        uint256 denominator1
    ) internal view returns (uint256 amount0) {
        amount0 = (amount0Total * reserve1) / (reserve0 * denominator1 / denominator0 + reserve1);
        uint256 amount1 = getAmountOut(wombatRouter, token0, token1, pool0, amount0);
        amount0 = (amount0Total * reserve1) / (reserve0 * amount1 / amount0 + reserve1);
    }

    /**
     * Get amount of lp tokens where amount0Total is total getting amount nominated in token0
     *
     */
    function getAmountLpTokens(
        IWombatRouter wombatRouter,
        address token0,
        address token1,
        address pool0,
        uint256 amount0Total,
        uint256 totalAmountLpTokens,
        uint256 reserve0,
        uint256 reserve1,
        uint256 denominator0,
        uint256 denominator1
    ) internal view returns (uint256 amountLpTokens) {
        amountLpTokens = (totalAmountLpTokens * amount0Total * denominator1) / (reserve0 * denominator1 + reserve1 * denominator0);
        uint256 amount1 = reserve1 * amountLpTokens / totalAmountLpTokens;
        uint256 amount0 = getAmountOut(wombatRouter, token1, token0, pool0, amount1);
        amountLpTokens = (totalAmountLpTokens * amount0Total * amount1) / (reserve0 * amount1 + reserve1 * amount0);
    }

    /**
     * Get amount of token1 and token2 nominated in token0 where amount0Total is total getting amount nominated in token0
     *
     */
    function getAmountToSwap(CalculateParams memory params) internal view returns (uint256 amount1InToken0, uint256 amount2InToken0) {
        amount1InToken0 = (params.amount0Total * params.reserve1) / (params.reserve0 * params.denominator1 / params.denominator0
                + params.reserve1 + params.reserve2 * params.denominator1 / params.denominator2);
        amount2InToken0 = (params.amount0Total * params.reserve2) / (params.reserve0 * params.denominator2 / params.denominator0
                + params.reserve1 * params.denominator2 / params.denominator1 + params.reserve2);
        //TODO fix
        for (uint i = 0; i < params.precision; i++) {
            uint256 amount1 = getAmountOut(params.wombatRouter, params.token0, params.token1, params.pool0, amount1InToken0);
            uint256 amount2 = getAmountOut(params.wombatRouter, params.token0, params.token2, params.pool0, amount2InToken0);
            amount1InToken0 = (params.amount0Total * params.reserve1) / (params.reserve0 * amount1 / amount1InToken0
                    + params.reserve1 + params.reserve2 * amount1 / amount2);
            amount2InToken0 = (params.amount0Total * params.reserve2) / (params.reserve0 * amount2 / amount2InToken0
                    + params.reserve1 * amount2 / amount1 + params.reserve2);
        }
    }

    /**
     * Get amount of lp tokens where amount0Total is total getting amount nominated in token0
     *
     */
    function getAmountLpTokens(CalculateParams memory params) internal view returns (uint256 amountLpTokens) {
        amountLpTokens = (params.totalAmountLpTokens * params.amount0Total) / (params.reserve0
                + params.reserve1 * params.denominator0 / params.denominator1 + params.reserve2 * params.denominator0 / params.denominator2);
        //TODO fix
        for (uint i = 0; i < params.precision; i++) {
            uint256 amount1 = params.reserve1 * amountLpTokens / params.totalAmountLpTokens;
            uint256 amount2 = params.reserve2 * amountLpTokens / params.totalAmountLpTokens;
            uint256 amount1InToken0 = getAmountOut(params.wombatRouter, params.token1, params.token0, params.pool0, amount1);
            uint256 amount2InToken0 = getAmountOut(params.wombatRouter, params.token2, params.token0, params.pool0, amount2);
            amountLpTokens = (params.totalAmountLpTokens * params.amount0Total) / (params.reserve0
                    + params.reserve1 * amount1InToken0 / amount1 + params.reserve2 * amount2InToken0 / amount2);
        }
    }

}