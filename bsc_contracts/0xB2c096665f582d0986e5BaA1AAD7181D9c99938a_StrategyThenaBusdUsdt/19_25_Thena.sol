// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IPair {

    // Structure to capture time period obervations every 30 minutes, used for local oracles
    struct Observation {
        uint timestamp;
        uint reserve0Cumulative;
        uint reserve1Cumulative;
    }

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    // Used to denote stable or volatile pair, not immutable since construction happens in the initialize method for CREATE2 deterministic addresses
    function stable() external view returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function fees() external view returns (address);

    function reserve0() external view returns (uint);

    function reserve1() external view returns (uint);

    function blockTimestampLast() external view returns (uint);

    function reserve0CumulativeLast() external view returns (uint);

    function reserve1CumulativeLast() external view returns (uint);

    function observationLength() external view returns (uint);

    function lastObservation() external view returns (Observation memory);

    function metadata() external view returns (uint dec0, uint dec1, uint r0, uint r1, bool st, address t0, address t1);

    function tokens() external view returns (address, address);

    function isStable() external view returns(bool);

    // claim accumulated but unclaimed fees (viewable via claimable0 and claimable1)
    function claimFees() external returns (uint claimed0, uint claimed1);

    function claimStakingFees() external;

    function getReserves() external view returns (uint _reserve0, uint _reserve1, uint _blockTimestampLast);

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices() external view returns (uint reserve0Cumulative, uint reserve1Cumulative, uint blockTimestamp);

    // gives the current twap price measured from amountIn * tokenIn gives amountOut
    function current(address tokenIn, uint amountIn) external view returns (uint amountOut);

    // as per `current`, however allows user configured granularity, up to the full window size
    function quote(address tokenIn, uint amountIn, uint granularity) external view returns (uint amountOut);

    // returns a memory set of twap prices
    function prices(address tokenIn, uint amountIn, uint points) external view returns (uint[] memory);

    function sample(address tokenIn, uint amountIn, uint points, uint window) external view returns (uint[] memory);

    // this low-level function should be called by addLiquidity functions in Router.sol, which performs important safety checks
    // standard uniswap v2 implementation
    function mint(address to) external returns (uint liquidity);

    // this low-level function should be called from a contract which performs important safety checks
    // standard uniswap v2 implementation
    function burn(address to) external returns (uint amount0, uint amount1);

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;

    // force balances to match reserves
    function skim(address to) external;

    // force reserves to match balances
    function sync() external;

    function getAmountOut(uint amountIn, address tokenIn) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    function transfer(address dst, uint amount) external returns (bool);

    function transferFrom(address src, address dst, uint amount) external returns (bool);

}


interface IRouter {

    struct route {
        address from;
        address to;
        bool stable;
    }

    function factory() external pure returns (address);

    function weth() external pure returns (address);

    function pairCodeHash() external pure returns (bytes32);

    function sortTokens(address tokenA, address tokenB) external pure returns (address token0, address token1);

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address tokenA, address tokenB, bool stable) external view returns (address pair);

    // fetches and sorts the reserves for a pair
    function getReserves(address tokenA, address tokenB, bool stable) external view returns (uint reserveA, uint reserveB);

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amount, bool stable);

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(uint amountIn, route[] memory routes) external view returns (uint[] memory amounts);

    function isPair(address pair) external view returns (bool);

    function quoteAddLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired
    ) external view returns (uint amountA, uint amountB, uint liquidity);

    function quoteRemoveLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity
    ) external view returns (uint amountA, uint amountB);

    function addLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        bool stable,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        bool stable,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        bool stable,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokensSimple(
        uint amountIn,
        uint amountOutMin,
        address tokenFrom,
        address tokenTo,
        bool stable,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        route[] calldata routes,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, route[] calldata routes, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, route[] calldata routes, address to, uint deadline)
    external
    returns (uint[] memory amounts);

}


interface IGaugeV2 {

    function isForPair() external view returns (bool);

    function rewardToken() external view returns (address);

    function _VE() external view returns (address);

    function TOKEN() external view returns (address);

    function DISTRIBUTION() external view returns (address);

    function gaugeRewarder() external view returns (address);

    function internal_bribe() external view returns (address);

    function external_bribe() external view returns (address);

    function rewarderPid() external view returns (uint256);

    function DURATION() external view returns (uint256);

    function periodFinish() external view returns (uint256);

    function rewardRate() external view returns (uint256);

    function lastUpdateTime() external view returns (uint256);

    function rewardPerTokenStored() external view returns (uint256);

    function fees0() external view returns (uint);

    function fees1() external view returns (uint);

    function userRewardPerTokenPaid(address account) external view returns (uint256);

    function rewards(address account) external view returns (uint256);

    function _totalSupply() external view returns (uint256);

    function _balances(address account) external view returns (uint256);

    ///@notice total supply held
    function totalSupply() external view returns (uint256);

    ///@notice balance of a user
    function balanceOf(address account) external view returns (uint256);

    ///@notice last time reward
    function lastTimeRewardApplicable() external view returns (uint256);

    ///@notice  reward for a sinle token
    function rewardPerToken() external view returns (uint256);

    ///@notice see earned rewards for user
    function earned(address account) external view returns (uint256);

    ///@notice get total reward for the duration
    function rewardForDuration() external view returns (uint256);

    ///@notice deposit all TOKEN of msg.sender
    function depositAll() external;

    ///@notice deposit amount TOKEN
    function deposit(uint256 amount) external;

    ///@notice withdraw all token
    function withdrawAll() external;

    ///@notice withdraw a certain amount of TOKEN
    function withdraw(uint256 amount) external;

    ///@notice withdraw all TOKEN and harvest rewardToken
    function withdrawAllAndHarvest() external;

    ///@notice User harvest function
    function getReward() external;

    function _periodFinish() external view returns (uint256);

    function claimFees() external returns (uint claimed0, uint claimed1);

}


interface IBribe {
    function _deposit(uint amount, uint tokenId) external;
    function _withdraw(uint amount, uint tokenId) external;
    function getRewardForOwner(uint tokenId, address[] memory tokens) external;
    function notifyRewardAmount(address token, uint amount) external;
    function left(address token) external view returns (uint);
}


library ThenaLibrary {

    function getAmountOut(
        IRouter router,
        address inputToken,
        address outputToken,
        bool isStable,
        uint256 amountInput
    ) internal view returns (uint256) {

        IRouter.route[] memory routes = new IRouter.route[](1);
        routes[0].from = inputToken;
        routes[0].to = outputToken;
        routes[0].stable = isStable;

        return router.getAmountsOut(amountInput, routes)[1];
    }

    function getAmountOut(
        IRouter router,
        address inputToken,
        address middleToken,
        address outputToken,
        bool isStable0,
        bool isStable1,
        uint256 amountInput
    ) internal view returns (uint256) {

        IRouter.route[] memory routes = new IRouter.route[](2);
        routes[0].from = inputToken;
        routes[0].to = middleToken;
        routes[0].stable = isStable0;
        routes[1].from = middleToken;
        routes[1].to = outputToken;
        routes[1].stable = isStable1;

        return router.getAmountsOut(amountInput, routes)[2];
    }

    function swap(
        IRouter router,
        address inputToken,
        address outputToken,
        bool isStable,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient
    ) internal returns (uint256) {

        IERC20(inputToken).approve(address(router), amountIn);

        IRouter.route[] memory routes = new IRouter.route[](1);
        routes[0].from = inputToken;
        routes[0].to = outputToken;
        routes[0].stable = isStable;

        return router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            routes,
            recipient,
            block.timestamp
        )[1];
    }

    function swap(
        IRouter router,
        address inputToken,
        address middleToken,
        address outputToken,
        bool isStable0,
        bool isStable1,
        uint256 amountIn,
        uint256 amountOutMin,
        address recipient
    ) internal returns (uint256) {

        IERC20(inputToken).approve(address(router), amountIn);

        IRouter.route[] memory routes = new IRouter.route[](2);
        routes[0].from = inputToken;
        routes[0].to = middleToken;
        routes[0].stable = isStable0;
        routes[1].from = middleToken;
        routes[1].to = outputToken;
        routes[1].stable = isStable1;

        return router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            routes,
            recipient,
            block.timestamp
        )[2];
    }

}