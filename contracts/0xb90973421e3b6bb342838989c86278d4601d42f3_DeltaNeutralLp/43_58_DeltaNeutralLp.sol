// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.16;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {ILendingPool} from "../interfaces/aave.sol";
import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";
import {BaseVault} from "../BaseVault.sol";
import {AccessStrategy} from "./AccessStrategy.sol";
import {IMasterChef} from "../interfaces/sushiswap/IMasterChef.sol";
import {SlippageUtils} from "../libs/SlippageUtils.sol";

contract DeltaNeutralLp is AccessStrategy {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;
    using SlippageUtils for uint256;

    constructor(
        BaseVault _vault,
        ILendingPool _lendingPool,
        ERC20 _borrow,
        AggregatorV3Interface _borrowFeed,
        IUniswapV2Router02 _router,
        IMasterChef _masterChef,
        uint256 _masterChefPid,
        bool _useMasterChefV2,
        ERC20 _sushiToken,
        IUniswapV3Pool _pool,
        address[] memory strategists
    ) AccessStrategy(_vault, strategists) {
        canStartNewPos = true;

        borrow = _borrow;
        borrowFeed = _borrowFeed;

        router = _router;
        abPair = ERC20(IUniswapV2Factory(_router.factory()).getPair(address(asset), address(borrow)));

        // Aave info
        lendingPool = _lendingPool;
        debtToken = ERC20(lendingPool.getReserveData(address(borrow)).variableDebtTokenAddress);
        aToken = ERC20(lendingPool.getReserveData(address(asset)).aTokenAddress);

        // Sushi info
        masterChef = _masterChef;
        masterChefPid = _masterChefPid;
        sushiToken = _sushiToken;
        useMasterChefV2 = _useMasterChefV2;

        // Depositing/withdrawing/repaying debt from lendingPool
        asset.safeApprove(address(lendingPool), type(uint256).max);
        aToken.safeApprove(address(lendingPool), type(uint256).max);
        borrow.safeApprove(address(lendingPool), type(uint256).max);

        // To trade asset/borrow/sushi on uniV2
        asset.safeApprove(address(_router), type(uint256).max);
        borrow.safeApprove(address(_router), type(uint256).max);
        sushiToken.safeApprove(address(_router), type(uint256).max);

        // To trade asset/borrow on uni v3
        poolFee = _pool.fee();
        asset.safeApprove(address(v3Router), type(uint256).max);
        borrow.safeApprove(address(v3Router), type(uint256).max);

        // To remove liquidity
        abPair.safeApprove(address(_router), type(uint256).max);
        // To stake lp tokens
        abPair.safeApprove(address(_masterChef), type(uint256).max);
    }

    /// @notice Get price of WETH in USDC (borrowPrice) from chainlink. Has 8 decimals.
    function _chainlinkPriceOfBorrow() internal view returns (uint256 borrowPrice) {
        (uint80 roundId, int256 price,, uint256 timestamp, uint80 answeredInRound) = borrowFeed.latestRoundData();
        require(price > 0, "DNLP: price <= 0");
        require(answeredInRound >= roundId, "DNLP: stale data");
        require(timestamp != 0, "DNLP: round not done");
        borrowPrice = uint256(price);
    }

    /// @notice Get price of WETH in USDC (borrowPrice) from Sushiswap. Has 8 decimals.
    function _sushiPriceOfBorrow() internal view returns (uint256 borrowPrice) {
        address[] memory path = new address[](2);
        path[0] = address(borrow);
        path[1] = address(asset);

        uint256[] memory amounts = router.getAmountsOut({amountIn: 1e18, path: path});
        // We multiply to remove the 0.3% fee assessed in getAmountsOut
        return amounts[1] * 1000 / 997;
    }

    /// @notice Convert `borrow` (e.g. WETH) to `asset` (e.g. USDC). Has 6 decimals.
    function _borrowToAsset(uint256 borrowChainlinkPrice, uint256 amountB) internal pure returns (uint256 assets) {
        assets = borrowChainlinkPrice.mulWadDown(amountB) / 1e2;
    }

    /// @notice Convert `asset` (e.g. USDC) to `borrow` (e.g. WETH). Has 18 decimals.
    function _assetToBorrow(uint256 borrowChainlinkPrice, uint256 amountA) internal pure returns (uint256 borrows) {
        borrows = (amountA * 1e2).divWadDown(borrowChainlinkPrice);
    }

    /// @notice Get underlying assets (USDC, WETH) amounts from sushiswap lp token amount
    function _getSushiLpUnderlyingAmounts(uint256 lpTokenAmount)
        internal
        view
        returns (uint256 assets, uint256 borrows)
    {
        assets = lpTokenAmount.mulDivDown(asset.balanceOf(address(abPair)), abPair.totalSupply());
        borrows = lpTokenAmount.mulDivDown(borrow.balanceOf(address(abPair)), abPair.totalSupply());
    }

    function totalLockedValue() public view override returns (uint256) {
        // The below are all in units of `asset`
        // balanceOfAsset + balanceOfEth + aToken value + Uni Lp value - debt
        // lp tokens * (total assets) / total lp tokens
        uint256 borrowPrice = _chainlinkPriceOfBorrow();

        // Asset value of underlying eth
        uint256 assetsEth = _borrowToAsset(borrowPrice, borrow.balanceOf(address(this)));

        // Underlying value of sushi LP tokens
        uint256 sushiTotalStakedAmount =
            abPair.balanceOf(address(this)) + masterChef.userInfo(masterChefPid, address(this)).amount;
        (uint256 sushiUnderlyingAssets, uint256 sushiUnderlyingBorrows) =
            _getSushiLpUnderlyingAmounts(sushiTotalStakedAmount);
        uint256 sushiLpValue = sushiUnderlyingAssets + _borrowToAsset(borrowPrice, sushiUnderlyingBorrows);

        // Asset value of debt
        uint256 assetsDebt = _borrowToAsset(borrowPrice, debtToken.balanceOf(address(this)));

        return balanceOfAsset() + assetsEth + aToken.balanceOf(address(this)) + sushiLpValue - assetsDebt;
    }

    uint32 public currentPosition;
    bool public canStartNewPos;

    IMasterChef public immutable masterChef;
    uint256 public immutable masterChefPid;
    ERC20 public immutable sushiToken;
    bool public immutable useMasterChefV2;

    IUniswapV2Router02 public immutable router;
    ISwapRouter public constant v3Router = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    /// @notice The pool's fee. We need this to identify the pool.
    uint24 public immutable poolFee;
    /// @notice The address of the Uniswap Lp token (the asset-borrow pair)
    ERC20 public immutable abPair;

    /// @notice The asset we want to borrow, e.g. WETH
    ERC20 public immutable borrow;
    ILendingPool immutable lendingPool;
    /// @notice The asset we get when we borrow our `borrow` from aave
    ERC20 public immutable debtToken;
    /// @notice The asset we get deposit `asset` into aave
    ERC20 public immutable aToken;

    /// @notice Gives ratio of vault asset to borrow asset, e.g. WETH/USD (assuming usdc = usd)
    AggregatorV3Interface public immutable borrowFeed;

    event PositionStart( // chainlink price and spot price of borrow
        uint32 indexed position,
        uint256 assetCollateral,
        uint256 borrows,
        uint256[2] borrowPrices,
        uint256 assetsToSushi,
        uint256 borrowsToSushi,
        uint256 timestamp
    );

    function startPosition(uint256 slippageToleranceBps) external onlyRole(STRATEGIST_ROLE) {
        // Set position metadata
        require(canStartNewPos, "DNLP: position is active");
        currentPosition += 1;
        canStartNewPos = false;

        uint256 borrowPrice = _chainlinkPriceOfBorrow();

        // Deposit asset in aave. Then borrow at 75%
        // If x is amount we want to deposit into aave .75x = Total - x => 1.75x = Total => x = Total / 1.75 => Total * 4/7
        uint256 assetsToDeposit = asset.balanceOf(address(this)).mulDivDown(4, 7);

        lendingPool.deposit({asset: address(asset), amount: assetsToDeposit, onBehalfOf: address(this), referralCode: 0});

        uint256 borrowAmount = _assetToBorrow(borrowPrice, assetsToDeposit).mulDivDown(3, 4);
        if (borrowAmount > 0) {
            lendingPool.borrow({
                asset: address(borrow),
                amount: borrowAmount,
                interestRateMode: 2,
                referralCode: 0,
                onBehalfOf: address(this)
            });
        }

        // Provide liquidity on sushiswap
        uint256 desiredAssetsInUni = asset.balanceOf(address(this));
        uint256 desiredBorrowsInUni = borrow.balanceOf(address(this));

        router.addLiquidity({
            tokenA: address(asset),
            tokenB: address(borrow),
            amountADesired: desiredAssetsInUni,
            amountBDesired: desiredBorrowsInUni,
            amountAMin: desiredAssetsInUni.slippageDown(slippageToleranceBps),
            amountBMin: desiredBorrowsInUni.slippageDown(slippageToleranceBps),
            to: address(this),
            deadline: block.timestamp
        });

        // Stake lp tokens masterchef
        _stake();

        emit PositionStart({
            position: currentPosition,
            assetCollateral: aToken.balanceOf(address(this)),
            borrows: debtToken.balanceOf(address(this)),
            borrowPrices: [borrowPrice, _sushiPriceOfBorrow()], // chainlink price and spot price of borrow
            assetsToSushi: desiredAssetsInUni - asset.balanceOf(address(this)),
            borrowsToSushi: desiredBorrowsInUni - borrow.balanceOf(address(this)),
            timestamp: block.timestamp
        });
    }

    /// @dev This strategy should be put at the end of the WQ so that we rarely divest from it. Divestment
    /// ideally occurs when the strategy does not have an open position
    function _divest(uint256 assets) internal override returns (uint256) {
        // Totally unwind the position with 5% slippage tolerance
        if (!canStartNewPos) _endPosition(500); //
        uint256 amountToSend = Math.min(assets, balanceOfAsset());
        asset.safeTransfer(address(vault), amountToSend);
        // Return the given amount
        return amountToSend;
    }

    event PositionEnd( // usdc value of sushi rewards
        uint32 indexed position,
        uint256 assetsFromSushi,
        uint256 borrowsFromSushi,
        uint256 assetsFromRewards,
        uint256[2] borrowPrices,
        bool assetSold,
        uint256 assetsOrBorrowsSold,
        uint256 assetsOrBorrowsReceived,
        uint256 assetCollateral,
        uint256 borrowDebtPaid,
        uint256 timestamp
    );

    function endPosition(uint256 slippageToleranceBps) external onlyRole(STRATEGIST_ROLE) {
        _endPosition(slippageToleranceBps);
    }

    function _endPosition(uint256 slippageToleranceBps) internal {
        // Set position metadata
        require(!canStartNewPos, "DNLP: position is inactive");
        canStartNewPos = true;

        // Unstake lp tokens and sell all sushi
        _unstakeAndClaimSushi();
        uint256 assetsFromRewards = _sellSushi(slippageToleranceBps);

        // Remove liquidity
        // a = usdc, b = weth
        uint256 abPairBalance = abPair.balanceOf(address(this));
        (uint256 underlyingAssets, uint256 underlyingBorrows) = _getSushiLpUnderlyingAmounts(abPairBalance);
        (uint256 amount0, uint256 amount1) = router.removeLiquidity({
            tokenA: address(asset),
            tokenB: address(borrow),
            liquidity: abPairBalance,
            amountAMin: underlyingAssets.slippageDown(slippageToleranceBps),
            amountBMin: underlyingBorrows.slippageDown(slippageToleranceBps),
            to: address(this),
            deadline: block.timestamp
        });
        (uint256 assetsFromSushi, uint256 borrowsFromSushi) = _changeFormat(amount0, amount1);

        // Buy enough borrow to pay back debt
        uint256 debt = debtToken.balanceOf(address(this));

        // Either we buy eth or sell eth. If we need to buy then borrowToBuy will be
        // positive and borrowToSell will be zero and vice versa.
        uint256[2] memory tradeAmounts;
        bool assetSold;
        {
            uint256 bBal = borrow.balanceOf(address(this));
            uint256 borrowToBuy = debt > bBal ? debt - bBal : 0;
            uint256 borrowToSell = bBal > debt ? bBal - debt : 0;

            // Passing the `slippageToleranceBps` param directly triggers stack too deep error
            uint256 bps = slippageToleranceBps;
            tradeAmounts = _tradeBorrow(borrowToSell, borrowToBuy, _chainlinkPriceOfBorrow(), bps);
            assetSold = debt > bBal;
        }

        // Repay debt
        lendingPool.repay({asset: address(borrow), amount: debt, rateMode: 2, onBehalfOf: address(this)});

        // Withdraw from aave
        uint256 assetCollateral = aToken.balanceOf(address(this));
        lendingPool.withdraw({asset: address(asset), amount: aToken.balanceOf(address(this)), to: address(this)});

        emit PositionEnd({
            position: currentPosition,
            assetsFromSushi: assetsFromSushi, // usdc value of sushi rewards
            borrowsFromSushi: borrowsFromSushi,
            assetsFromRewards: assetsFromRewards,
            borrowPrices: [_chainlinkPriceOfBorrow(), _sushiPriceOfBorrow()],
            assetSold: assetSold,
            assetsOrBorrowsSold: tradeAmounts[0],
            assetsOrBorrowsReceived: tradeAmounts[1],
            assetCollateral: assetCollateral,
            borrowDebtPaid: debt,
            timestamp: block.timestamp
        });
    }

    function _tradeBorrow(uint256 borrowToSell, uint256 borrowToBuy, uint256 borrowPrice, uint256 slippageToleranceBps)
        internal
        returns (uint256[2] memory tradeAmounts)
    {
        if (borrowToBuy > 0) {
            ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
                tokenIn: address(asset),
                tokenOut: address(borrow),
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: borrowToBuy,
                // When amountOut is very small the conversion may truncate to zero. Set a floor of one whole token
                amountInMaximum: Math.max(
                    _borrowToAsset(borrowPrice, borrowToBuy).slippageUp(slippageToleranceBps), 10 ** ERC20(asset).decimals()
                    ),
                sqrtPriceLimitX96: 0
            });

            tradeAmounts[0] = v3Router.exactOutputSingle(params);
            tradeAmounts[1] = borrowToBuy;
        }
        if (borrowToSell > 0) {
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: address(borrow),
                tokenOut: address(asset),
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: borrowToSell,
                amountOutMinimum: _borrowToAsset(borrowPrice, borrowToSell).slippageDown(slippageToleranceBps),
                sqrtPriceLimitX96: 0
            });
            tradeAmounts[0] = borrowToSell;
            tradeAmounts[1] = v3Router.exactInputSingle(params);
        }
    }

    function _changeFormat(uint256 assets, uint256 borrows) internal view returns (uint256, uint256) {
        // If asset is not token 0 then flip
        if (address(asset) > address(borrow)) return (borrows, assets);
        return (assets, borrows);
    }

    function _stake() internal {
        // Deposit to MasterChef for additional SUSHI rewards.
        if (useMasterChefV2) {
            masterChef.deposit(masterChefPid, abPair.balanceOf(address(this)), address(this));
        } else {
            masterChef.deposit(masterChefPid, abPair.balanceOf(address(this)));
        }
    }

    function _unstakeAndClaimSushi() internal {
        uint256 depositedSLPAmount = masterChef.userInfo(masterChefPid, address(this)).amount;
        if (useMasterChefV2) {
            masterChef.withdrawAndHarvest(masterChefPid, depositedSLPAmount, address(this));
        } else {
            masterChef.withdraw(masterChefPid, depositedSLPAmount);
        }
    }

    function _sellSushi(uint256 slippageToleranceBps) internal returns (uint256 assetsReceived) {
        // Sell SUSHI tokens
        uint256 sushiBalance = sushiToken.balanceOf(address(this));
        if (sushiBalance == 0) return 0;

        address[] memory path = new address[](3);
        path[0] = address(sushiToken);
        path[1] = address(borrow);
        path[2] = address(asset);

        uint256[] memory amounts = router.getAmountsOut({amountIn: sushiBalance, path: path});
        uint256[] memory amountsReceived = router.swapExactTokensForTokens({
            amountIn: sushiBalance,
            amountOutMin: amounts[2].slippageDown(slippageToleranceBps),
            path: path,
            to: address(this),
            deadline: block.timestamp
        });

        assetsReceived = amountsReceived[2];
    }

    function claimAndSellSushi(uint256 slippageBps) external onlyRole(STRATEGIST_ROLE) {
        // Get Sushi into the contract
        if (useMasterChefV2) {
            masterChef.harvest(masterChefPid, address(this));
        } else {
            _unstakeAndClaimSushi();
        }

        // Sell the sushi
        _sellSushi(slippageBps);

        // Restake if using masterchefv1
        if (!useMasterChefV2) {
            _stake();
        }
    }
}