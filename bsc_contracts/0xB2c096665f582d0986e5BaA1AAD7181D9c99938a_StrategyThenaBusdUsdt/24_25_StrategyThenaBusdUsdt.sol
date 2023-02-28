// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@overnight-contracts/core/contracts/Strategy.sol";
import "@overnight-contracts/connectors/contracts/stuff/Chainlink.sol";
import "@overnight-contracts/connectors/contracts/stuff/Thena.sol";
import "@overnight-contracts/connectors/contracts/stuff/Wombat.sol";

import "hardhat/console.sol";

contract StrategyThenaBusdUsdt is Strategy {

    // --- structs

    struct StrategyParams {
        address busd;
        address usdt;
        address the;
        address pair;
        address router;
        address gauge;
        address wombatPool;
        address wombatRouter;
        address oracleBusd;
        address oracleUsdt;
    }

    // --- params

    IERC20 public busd;
    IERC20 public usdt;
    IERC20 public the;

    IPair public pair;
    IRouter public router;
    IGaugeV2 public gauge;
    IPool public wombatPool;

    IWombatRouter public wombatRouter;

    IPriceFeed public oracleBusd;
    IPriceFeed public oracleUsdt;

    uint256 public busdDm;
    uint256 public usdtDm;

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
        usdt = IERC20(params.usdt);
        the = IERC20(params.the);

        pair = IPair(params.pair);
        router = IRouter(params.router);
        gauge = IGaugeV2(params.gauge);
        wombatPool = IPool(params.wombatPool);

        wombatRouter = IWombatRouter(params.wombatRouter);

        oracleBusd = IPriceFeed(params.oracleBusd);
        oracleUsdt = IPriceFeed(params.oracleUsdt);

        busdDm = 10 ** IERC20Metadata(params.busd).decimals();
        usdtDm = 10 ** IERC20Metadata(params.usdt).decimals();

        emit StrategyUpdatedParams();
    }

    // --- logic

    function _stake(
        address _asset,
        uint256 _amount
    ) internal override {

        require(_asset == address(busd), "Some token not compatible");

        // calculate amount to swap
        (uint256 reserveUsdt, uint256 reserveBusd,) = pair.getReserves();
        uint256 busdBalance = busd.balanceOf(address(this));
        uint256 amountBusdToSwap = WombatLibrary.getAmountToSwap(
            wombatRouter,
            address(busd),
            address(usdt),
            address(wombatPool),
            busdBalance,
            reserveBusd,
            reserveUsdt,
            busdDm,
            usdtDm
        );

        // swap busd to usdt
        uint256 usdtBalanceOracle = ChainlinkLibrary.convertTokenToToken(
            amountBusdToSwap,
            busdDm,
            usdtDm,
            oracleBusd,
            oracleUsdt
        );
        WombatLibrary.swapExactTokensForTokens(
            wombatRouter,
            address(busd),
            address(usdt),
            address(wombatPool),
            amountBusdToSwap,
            OvnMath.subBasisPoints(usdtBalanceOracle, swapSlippageBP),
            address(this)
        );

        // add liquidity
        uint256 usdtBalance = usdt.balanceOf(address(this));
        busdBalance = busd.balanceOf(address(this));
        usdt.approve(address(router), usdtBalance);
        busd.approve(address(router), busdBalance);
        router.addLiquidity(
            address(usdt),
            address(busd),
            pair.isStable(),
            usdtBalance,
            busdBalance,
            OvnMath.subBasisPoints(usdtBalance, swapSlippageBP),
            OvnMath.subBasisPoints(busdBalance, swapSlippageBP),
            address(this),
            block.timestamp
        );

        // deposit to gauge
        uint256 lpBalance = pair.balanceOf(address(this));
        pair.approve(address(gauge), lpBalance);
        gauge.deposit(lpBalance);
    }

    function _unstake(
        address _asset,
        uint256 _amount,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(busd), "Some token not compatible");

        // get amount LP tokens to unstake
        uint256 totalLpBalance = pair.totalSupply();
        (uint256 reserveUsdt, uint256 reserveBusd,) = pair.getReserves();
        uint256 lpTokensToWithdraw = WombatLibrary.getAmountLpTokens(
            wombatRouter,
            address(busd),
            address(usdt),
            address(wombatPool),
            // add 1e13 to _amount for smooth withdraw
            _amount + 1e13,
            totalLpBalance,
            reserveBusd,
            reserveUsdt,
            busdDm,
            usdtDm
        );
        uint256 lpBalance = gauge.balanceOf(address(this));
        if (lpTokensToWithdraw > lpBalance) {
            lpTokensToWithdraw = lpBalance;
        }

        // withdraw from gauge
        gauge.withdraw(lpTokensToWithdraw);

        // remove liquidity
        (uint256 usdtLpBalance, uint256 busdLpBalance) = router.quoteRemoveLiquidity(
            address(usdt),
            address(busd),
            pair.isStable(),
            lpTokensToWithdraw
        );
        pair.approve(address(router), lpTokensToWithdraw);
        router.removeLiquidity(
            address(usdt),
            address(busd),
            pair.isStable(),
            lpTokensToWithdraw,
            OvnMath.subBasisPoints(usdtLpBalance, swapSlippageBP),
            OvnMath.subBasisPoints(busdLpBalance, swapSlippageBP),
            address(this),
            block.timestamp
        );

        // swap usdt to busd
        uint256 usdtBalance = usdt.balanceOf(address(this));
        uint256 busdBalanceOut = WombatLibrary.getAmountOut(
            wombatRouter,
            address(usdt),
            address(busd),
            address(wombatPool),
            usdtBalance
        );
        if (busdBalanceOut > 0) {
            uint256 busdBalanceOracle = ChainlinkLibrary.convertTokenToToken(
                usdtBalance,
                usdtDm,
                busdDm,
                oracleUsdt,
                oracleBusd
            );
            WombatLibrary.swapExactTokensForTokens(
                wombatRouter,
                address(usdt),
                address(busd),
                address(wombatPool),
                usdtBalance,
                OvnMath.subBasisPoints(busdBalanceOracle, swapSlippageBP),
                address(this)
            );
        }

        return busd.balanceOf(address(this));
    }

    function _unstakeFull(
        address _asset,
        address _beneficiary
    ) internal override returns (uint256) {

        require(_asset == address(busd), "Some token not compatible");

        uint256 lpBalance = gauge.balanceOf(address(this));

        // withdraw from gauge
        gauge.withdraw(lpBalance);

        // remove liquidity
        (uint256 usdtLpBalance, uint256 busdLpBalance) = router.quoteRemoveLiquidity(
            address(usdt),
            address(busd),
            pair.isStable(),
            lpBalance
        );
        pair.approve(address(router), lpBalance);
        router.removeLiquidity(
            address(usdt),
            address(busd),
            pair.isStable(),
            lpBalance,
            OvnMath.subBasisPoints(usdtLpBalance, swapSlippageBP),
            OvnMath.subBasisPoints(busdLpBalance, swapSlippageBP),
            address(this),
            block.timestamp
        );

        // swap usdt to busd
        uint256 usdtBalance = usdt.balanceOf(address(this));
        uint256 busdBalanceOut = WombatLibrary.getAmountOut(
            wombatRouter,
            address(usdt),
            address(busd),
            address(wombatPool),
            usdtBalance
        );
        if (busdBalanceOut > 0) {
            uint256 busdBalanceOracle = ChainlinkLibrary.convertTokenToToken(
                usdtBalance,
                usdtDm,
                busdDm,
                oracleUsdt,
                oracleBusd
            );
            WombatLibrary.swapExactTokensForTokens(
                wombatRouter,
                address(usdt),
                address(busd),
                address(wombatPool),
                usdtBalance,
                OvnMath.subBasisPoints(busdBalanceOracle, swapSlippageBP),
                address(this)
            );
        }

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
        uint256 usdtBalance = usdt.balanceOf(address(this));

        uint256 lpBalance = gauge.balanceOf(address(this));
        if (lpBalance > 0) {
            (uint256 usdtLpBalance, uint256 busdLpBalance) = router.quoteRemoveLiquidity(
                address(usdt),
                address(busd),
                pair.isStable(),
                lpBalance
            );
            usdtBalance += usdtLpBalance;
            busdBalance += busdLpBalance;
        }

        if (usdtBalance > 0) {
            if (nav) {
                busdBalance += ChainlinkLibrary.convertTokenToToken(
                    usdtBalance,
                    usdtDm,
                    busdDm,
                    oracleUsdt,
                    oracleBusd
                );
            } else {
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
        uint256 lpBalance = gauge.balanceOf(address(this));
        if (lpBalance > 0) {
            gauge.getReward();
        }

        // sell rewards
        uint256 totalBusd;

        uint256 theBalance = the.balanceOf(address(this));
        if (theBalance > 0) {
            uint256 theAmountOut = ThenaLibrary.getAmountOut(
                router,
                address(the),
                address(busd),
                false,
                theBalance
            );
            if (theAmountOut > 0) {
                totalBusd += ThenaLibrary.swap(
                    router,
                    address(the),
                    address(busd),
                    false,
                    theBalance,
                    OvnMath.subBasisPoints(theAmountOut, 10),
                    address(this)
                );
            }
        }

        if (totalBusd > 0) {
            busd.transfer(_to, totalBusd);
        }

        return totalBusd;
    }

}