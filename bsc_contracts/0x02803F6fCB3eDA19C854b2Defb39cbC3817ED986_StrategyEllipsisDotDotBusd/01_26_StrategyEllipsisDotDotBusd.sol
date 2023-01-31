// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@overnight-contracts/core/contracts/Strategy.sol";
import "@overnight-contracts/connectors/contracts/stuff/Chainlink.sol";
import "@overnight-contracts/connectors/contracts/stuff/Ellipsis.sol";
import "@overnight-contracts/connectors/contracts/stuff/DotDot.sol";
import "@overnight-contracts/connectors/contracts/stuff/PancakeV2.sol";
import "@overnight-contracts/connectors/contracts/stuff/Wombat.sol";


contract StrategyEllipsisDotDotBusd is Strategy {

    // --- structs

    struct StrategyParams {
        address busd;
        address usdc;
        address usdt;
        address wBnb;
        address ddd;
        address epx;
        address valas;
        address val3EPS;
        address pool;
        address lpDepositor;
        address pancakeRouter;
        address wombatRouter;
        address wombatPool;
        address oracleBusd;
        address oracleUsdc;
        address oracleUsdt;
    }

    // --- params

    IERC20 public busd;
    IERC20 public usdc;
    IERC20 public usdt;
    IERC20 public wBnb;
    IERC20 public ddd;
    IERC20 public epx;
    IERC20 public valas;

    IERC20 public val3EPS;

    IEllipsisPool public pool;
    ILpDepositor public lpDepositor;

    IPancakeRouter02 public pancakeRouter;

    IWombatRouter public wombatRouter;
    address public wombatPool;

    IPriceFeed public oracleBusd;
    IPriceFeed public oracleUsdc;
    IPriceFeed public oracleUsdt;

    uint256 public dm18;

    // --- events

    event StrategyUpdatedParams();

    // ---  constructor

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() initializer public {
        __Strategy_init();
    }

    // --- Setters

    function setParams(StrategyParams calldata params) external onlyAdmin {
        busd = IERC20(params.busd);
        usdc = IERC20(params.usdc);
        usdt = IERC20(params.usdt);
        wBnb = IERC20(params.wBnb);
        ddd = IERC20(params.ddd);
        epx = IERC20(params.epx);
        valas = IERC20(params.valas);

        val3EPS = IERC20(params.val3EPS);

        pool = IEllipsisPool(params.pool);
        lpDepositor = ILpDepositor(params.lpDepositor);

        pancakeRouter = IPancakeRouter02(params.pancakeRouter);

        wombatRouter = IWombatRouter(params.wombatRouter);
        wombatPool = params.wombatPool;

        oracleBusd = IPriceFeed(params.oracleBusd);
        oracleUsdc = IPriceFeed(params.oracleUsdc);
        oracleUsdt = IPriceFeed(params.oracleUsdt);

        dm18 = 1e18;

        emit StrategyUpdatedParams();
    }

    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(busd), "Some token not compatible");

        // calculate amount to stake
        WombatLibrary.CalculateParams memory params;
        params.wombatRouter = wombatRouter;
        params.token0 = address(busd);
        params.token1 = address(usdc);
        params.token2 = address(usdt);
        params.pool0 = wombatPool;
        params.amount0Total = busd.balanceOf(address(this));
        params.totalAmountLpTokens = 0;
        params.reserve0 = pool.balances(0);
        params.reserve1 = pool.balances(1);
        params.reserve2 = pool.balances(2);
        params.denominator0 = dm18;
        params.denominator1 = dm18;
        params.denominator2 = dm18;
        params.precision = 0;
        (uint256 amountUsdcToSwap, uint256 amountUsdtToSwap) = WombatLibrary.getAmountToSwap(params);

        // swap
        _swapInWombat(address(busd), address(usdc), oracleBusd, oracleUsdc, amountUsdcToSwap);
        _swapInWombat(address(busd), address(usdt), oracleBusd, oracleUsdt, amountUsdtToSwap);

        // calculate min amount to mint
        uint256[3] memory amounts;
        amounts[0] = busd.balanceOf(address(this));
        amounts[1] = usdc.balanceOf(address(this));
        amounts[2] = usdt.balanceOf(address(this));
        // sub 4 bp to calculate min amount
        uint256 minToMint = OvnMath.subBasisPoints(pool.calc_token_amount(amounts, true), stakeSlippageBP);

        // add liquidity
        busd.approve(address(pool), amounts[0]);
        usdc.approve(address(pool), amounts[1]);
        usdt.approve(address(pool), amounts[2]);
        uint256 val3EPSBalance = pool.add_liquidity(amounts, minToMint);

        // stake
        val3EPS.approve(address(lpDepositor), val3EPSBalance);
        lpDepositor.deposit(address(this), address(val3EPS), val3EPSBalance);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(busd), "Some token not compatible");

        // calculate amount to unstake
        uint256 totalAmountLpTokens = val3EPS.totalSupply();
        uint256 reserve0 = pool.balances(0);
        uint256 reserve1 = pool.balances(1);
        uint256 reserve2 = pool.balances(2);

        WombatLibrary.CalculateParams memory params;
        params.wombatRouter = wombatRouter;
        params.token0 = address(busd);
        params.token1 = address(usdc);
        params.token2 = address(usdt);
        params.pool0 = wombatPool;
        params.amount0Total = OvnMath.addBasisPoints(_amount, stakeSlippageBP) + 10;
        params.totalAmountLpTokens = totalAmountLpTokens;
        params.reserve0 = reserve0;
        params.reserve1 = reserve1;
        params.reserve2 = reserve2;
        params.denominator0 = dm18;
        params.denominator1 = dm18;
        params.denominator2 = dm18;
        params.precision = 0;

        uint256 val3EPSAmount = WombatLibrary.getAmountLpTokens(params);
        uint256 val3EPSBalance = lpDepositor.userBalances(address(this), address(val3EPS));
        if (val3EPSAmount > val3EPSBalance) {
            val3EPSAmount = val3EPSBalance;
        }

        // unstake
        lpDepositor.withdraw(address(this), address(val3EPS), val3EPSAmount);

        // calculate min amount to burn
        uint256[3] memory minAmounts;
        minAmounts[0] = OvnMath.subBasisPoints(reserve0 * val3EPSAmount / totalAmountLpTokens, stakeSlippageBP);
        minAmounts[1] = OvnMath.subBasisPoints(reserve1 * val3EPSAmount / totalAmountLpTokens, stakeSlippageBP);
        minAmounts[2] = OvnMath.subBasisPoints(reserve2 * val3EPSAmount / totalAmountLpTokens, stakeSlippageBP);

        // remove liquidity
        val3EPS.approve(address(pool), val3EPSAmount);
        pool.remove_liquidity(val3EPSAmount, minAmounts);

        // swap
        _swapInWombat(address(usdc), address(busd), oracleUsdc, oracleBusd, usdc.balanceOf(address(this)));
        _swapInWombat(address(usdt), address(busd), oracleUsdt, oracleBusd, usdt.balanceOf(address(this)));

        return busd.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(busd), "Some token not compatible");

        // calculate amount to unstake
        uint256 val3EPSBalance = lpDepositor.userBalances(address(this), address(val3EPS));

        // unstake
        lpDepositor.withdraw(address(this), address(val3EPS), val3EPSBalance);

        // calculate min amount to burn
        uint256 totalAmountLpTokens = val3EPS.totalSupply();
        uint256[3] memory minAmounts;
        minAmounts[0] = OvnMath.subBasisPoints(pool.balances(0) * val3EPSBalance / totalAmountLpTokens, stakeSlippageBP);
        minAmounts[1] = OvnMath.subBasisPoints(pool.balances(1) * val3EPSBalance / totalAmountLpTokens, stakeSlippageBP);
        minAmounts[2] = OvnMath.subBasisPoints(pool.balances(2) * val3EPSBalance / totalAmountLpTokens, stakeSlippageBP);

        // remove liquidity
        val3EPS.approve(address(pool), val3EPSBalance);
        pool.remove_liquidity(val3EPSBalance, minAmounts);

        // swap
        _swapInWombat(address(usdc), address(busd), oracleUsdc, oracleBusd, usdc.balanceOf(address(this)));
        _swapInWombat(address(usdt), address(busd), oracleUsdt, oracleBusd, usdt.balanceOf(address(this)));

        return busd.balanceOf(address(this));
    }

    function netAssetValue() external view override returns (uint256) {
        return _totalValue(true);
    }

    function liquidationValue() external view override returns (uint256) {
        return _totalValue(false);
    }

    function _totalValue(bool nav) internal view returns (uint256) {
        uint256 busdBalance = busd.balanceOf(address(this));
        uint256 usdcBalance = usdc.balanceOf(address(this));
        uint256 usdtBalance = usdt.balanceOf(address(this));

        uint256 val3EPSBalance = lpDepositor.userBalances(address(this), address(val3EPS));
        if (val3EPSBalance > 0) {
            uint256 totalSupply = val3EPS.totalSupply();
            for (uint256 i = 0; i < 3; i++) {
                uint256 coinBalance = val3EPSBalance * pool.balances(i) / totalSupply;
                if (address(busd) == pool.coins(i)) {
                    busdBalance += coinBalance;
                } else if (address(usdc) == pool.coins(i)) {
                    usdcBalance += coinBalance;
                } else if (address(usdt) == pool.coins(i)) {
                    usdtBalance += coinBalance;
                }
            }
        }

        if (nav) {
            if (usdcBalance > 0) {
                busdBalance += ChainlinkLibrary.convertTokenToToken(
                    usdcBalance,
                    dm18,
                    dm18,
                    oracleUsdc,
                    oracleBusd
                );
            }
            if (usdtBalance > 0) {
                busdBalance += ChainlinkLibrary.convertTokenToToken(
                    usdtBalance,
                    dm18,
                    dm18,
                    oracleUsdt,
                    oracleBusd
                );
            }
        } else {
            if (usdcBalance > 0) {
                busdBalance += WombatLibrary.getAmountOut(
                    wombatRouter,
                    address(usdc),
                    address(busd),
                    address(wombatPool),
                    usdcBalance
                );
            }
            if (usdtBalance > 0) {
                busdBalance += WombatLibrary.getAmountOut(
                    wombatRouter,
                    address(usdt),
                    address(busd),
                    address(wombatPool),
                    usdtBalance
                );
            }
        }

        return busdBalance;
    }

    function _claimRewards(address _to) internal override returns (uint256) {

        // claim rewards
        uint256 val3EPSBalance = lpDepositor.userBalances(address(this), address(val3EPS));
        if (val3EPSBalance > 0) {
            address[] memory tokens = new address[](1);
            tokens[0] = address(val3EPS);
            lpDepositor.claim(address(this), tokens, 0);
            lpDepositor.claimExtraRewards(address(this), address(val3EPS));
        }

        // sell rewards
        uint256 totalBusd = _swapInPancakeSwap(address(ddd), address(wBnb), address(busd));
        totalBusd += _swapInPancakeSwap(address(epx), address(wBnb), address(busd));
        totalBusd += _swapInPancakeSwap(address(valas), address(wBnb), address(busd));

        if (totalBusd > 0) {
            busd.transfer(_to, totalBusd);
        }

        return totalBusd;
    }

    function _swapInWombat(
        address token0,
        address token1,
        IPriceFeed oracleToken0,
        IPriceFeed oracleToken1,
        uint256 amountToken0ToSwap
    ) internal {
        uint256 token1BalanceOracle = ChainlinkLibrary.convertTokenToToken(
            amountToken0ToSwap,
            dm18,
            dm18,
            oracleToken0,
            oracleToken1
        );
        WombatLibrary.swapExactTokensForTokens(
            wombatRouter,
            token0,
            token1,
            address(wombatPool),
            amountToken0ToSwap,
            OvnMath.subBasisPoints(token1BalanceOracle, swapSlippageBP),
            address(this)
        );
    }

    function _swapInPancakeSwap(
        address token0,
        address token1,
        address token2
    ) internal returns (uint256) {
        uint256 token0Balance = IERC20(token0).balanceOf(address(this));
        if (token0Balance > 0) {
            uint256 token2AmountOut = PancakeSwapLibrary.getAmountsOut(
                pancakeRouter,
                token0,
                token1,
                token2,
                token0Balance
            );
            if (token2AmountOut > 0) {
                return PancakeSwapLibrary.swapExactTokensForTokens(
                    pancakeRouter,
                    token0,
                    token1,
                    token2,
                    token0Balance,
                    token2AmountOut * 99 / 100,
                    address(this)
                );
            }
        }

        return 0;
    }
}