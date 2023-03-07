// SPDX-License-Identifier: Unlicense

pragma solidity =0.8.4;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {IVaultStorage} from "../interfaces/IVaultStorage.sol";

import {Constants} from "../libraries/Constants.sol";
import {Faucet} from "../libraries/Faucet.sol";
import {SharedEvents} from "../libraries/SharedEvents.sol";

contract VaultStorage is IVaultStorage, Faucet {
    //@dev governance address
    address public override governance;
    //@dev rebalancer address
    address public override keeper;

    //@dev Uniswap pools tick spacing
    int24 public override tickSpacing = 60;

    //@dev twap period to use for rebalance calculations
    uint32 public override twapPeriod = 180 seconds;

    //@dev max amount of wETH that strategy accept for deposit
    uint256 public override cap;

    //@dev lower and upper ticks in Uniswap pools
    int24 public override orderEthUsdcLower = 201360;
    int24 public override orderEthUsdcUpper = 204420;
    int24 public override orderOsqthEthLower = 27360;
    int24 public override orderOsqthEthUpper = 30420;

    //@dev timestamp when last rebalance executed
    uint256 public override timeAtLastRebalance = 1677824795;

    //@dev ETH/USDC price when last rebalance executed
    uint256 public override ethPriceAtLastRebalance = 1563425252593763190027;

    //@dev min price change for initiating rebalance (1.69%)
    uint256 public override rebalanceThreshold = 1e18;

    //@dev interest rate when last rebalance executed
    uint256 public override interestRateAtLastRebalance = 3e18;

    //@dev max interest rate 4.2%
    uint256 public override irMax = 42e17;

    //@dev interest rate precision (0.01)
    uint256 public override irPrecision = 1e16;

    //@dev weight adjustment parameter
    uint256 public override weightAdjParam = 1e16;

    //@dev max weight adjustment
    uint256 public override weightAdjLimit = 42e15;

    //@dev base threshold scale (10000)
    uint256 public override baseThresholdScale = 1e32;

    //@dev minimum lp-range width
    int24 public override baseThresholdFloor = 10;

    //@dev max TWAP deviation ETH/USDC pool
    int24 public override maxTwapDeviationEthUsdc = 120;

    //@dev max TWAP deviation oSQTH/ETH pool
    int24 public override maxTwapDeviationOsqthEth = 120;

    //@dev time difference to trigger a hedge (seconds)
    uint256 public override rebalanceTimeThreshold;
    uint256 public override rebalancePriceThreshold;

    //@dev protocol fee expressed as multiple of 1e-6
    uint256 public override protocolFee;

    //@dev accrued fees
    uint256 public override accruedFeesEth;
    uint256 public override accruedFeesUsdc;
    uint256 public override accruedFeesOsqth;

    //@dev rebalance auction duration (seconds)
    uint256 public override auctionTime;

    //@dev start auction price multiplier for rebalance buy auction and reserve price for rebalance sell auction (scaled 1e18)
    uint256 public override minPriceMultiplier;
    uint256 public override maxPriceMultiplier;

    //@dev system can be paused
    bool public override isSystemPaused = false;

    //@dev counts deposits between the rebalances (used in withdraw procedure)
    uint256 public override depositCount = 0;

    /**
     * @notice strategy constructor
       @param _cap max amount of wETH that strategy accepts for deposits
       @param _rebalanceTimeThreshold rebalance time threshold (seconds)
       @param _rebalancePriceThreshold rebalance price threshold (0.05*1e18 = 5%)
       @param _auctionTime auction duration (seconds)
       @param _minPriceMultiplier minimum auction price multiplier (0.95*1e18 = min auction price is 95% of twap)
       @param _maxPriceMultiplier maximum auction price multiplier (1.05*1e18 = max auction price is 105% of twap)
       @param _governance governance address
       @param _keeper keeper address
     */
    constructor(
        uint256 _cap,
        uint256 _rebalanceTimeThreshold,
        uint256 _rebalancePriceThreshold,
        uint256 _auctionTime,
        uint256 _minPriceMultiplier,
        uint256 _maxPriceMultiplier,
        uint256 _protocolFee,
        address _governance,
        address _keeper
    ) Faucet() {
        cap = _cap;

        protocolFee = _protocolFee;

        rebalanceTimeThreshold = _rebalanceTimeThreshold;
        rebalancePriceThreshold = _rebalancePriceThreshold;

        auctionTime = _auctionTime;
        minPriceMultiplier = _minPriceMultiplier;
        maxPriceMultiplier = _maxPriceMultiplier;

        governance = _governance;
        keeper = _keeper;
    }

    /**
     * @notice governance can transfer his admin power to another address
     * @param _governance new governance address
     */
    function setGovernance(address _governance) external override onlyGovernance {
        governance = _governance;
    }

    /**
     * @notice keeper can transfer his admin power to another address
     * @param _keeper new keeper address
     */
    function setKeeper(address _keeper) external override onlyKeeper {
        keeper = _keeper;
    }

    /**
     * @notice owner can set the strategy cap in USD terms
     * @dev deposits are rejected if it would put the strategy above the cap amount
     * @param _cap the maximum strategy collateral in USD, checked on deposits
     */
    function setCap(uint256 _cap) external onlyGovernance {
        cap = _cap;
    }

    /**
     * @notice owner can set the protocol fee expressed as multiple of 1e-6
     * @param _protocolFee the protocol fee, scaled by 1e18
     */
    function setProtocolFee(uint256 _protocolFee) external onlyGovernance {
        protocolFee = _protocolFee;
    }

    /**
     * @notice change deposit count
     */
    function setDepositCount(uint256 _depositCount) external override onlyVault {
        depositCount = _depositCount;
    }

    /**
     * @notice owner can set the hedge time threshold in seconds that determines how often the strategy can be hedged
     * @param _rebalanceTimeThreshold the rebalance time threshold, in seconds
     */
    function setRebalanceTimeThreshold(uint256 _rebalanceTimeThreshold) external override onlyGovernance {
        rebalanceTimeThreshold = _rebalanceTimeThreshold;
    }

    /**
     * @notice owner can set the hedge time threshold in percent, scaled by 1e18 that determines the deviation in EthUsdc price that can trigger a rebalance
     * @param _rebalancePriceThreshold the hedge price threshold, in percent, scaled by 1e18
     */
    function setRebalancePriceThreshold(uint256 _rebalancePriceThreshold) external onlyGovernance {
        rebalancePriceThreshold = _rebalancePriceThreshold;
    }

    /**
     * @notice owner can set the auction time, in seconds, that a hedge auction runs for
     * @param _auctionTime the length of the hedge auction in seconds
     */
    function setAuctionTime(uint256 _auctionTime) external onlyGovernance {
        auctionTime = _auctionTime;
    }

    /**
     * @notice owner can set the min price multiplier in a percentage scaled by 1e18 (95e16 is 95%)
     * @param _minPriceMultiplier the min price multiplier, a percentage, scaled by 1e18
     */
    function setMinPriceMultiplier(uint256 _minPriceMultiplier) external onlyGovernance {
        minPriceMultiplier = _minPriceMultiplier;
    }

    /**
     * @notice owner can set the max price multiplier in a percentage scaled by 1e18 (105e15 is 105%)
     * @param _maxPriceMultiplier the max price multiplier, a percentage, scaled by 1e18
     */
    function setMaxPriceMultiplier(uint256 _maxPriceMultiplier) external onlyGovernance {
        maxPriceMultiplier = _maxPriceMultiplier;
    }

    /**
     * @notice owner can set the max interest rate
     * @param _irMax the max interest rate
     */
    function setIrMax(uint256 _irMax) external onlyGovernance {
        irMax = _irMax;
    }

    /**
     * @notice owner can set the interest rate floor precision (0.01)
     * @param _irPrecision the max interest rate
     */
    function setIrPrecision(uint256 _irPrecision) external onlyGovernance {
        irPrecision = _irPrecision;
    }

    /**
     * @notice owner can set weight adjustment parameter
     * @param _weightAdjParam the max interest rate
     */
    function setWeightAdjParam(uint256 _weightAdjParam) external onlyGovernance {
        weightAdjParam = _weightAdjParam;
    }

    /**
     * @notice owner can set weight adjustment limit
     * @param _weightAdjLimit the max interest rate
     */
    function setWeightAdjLimit(uint256 _weightAdjLimit) external onlyGovernance {
        weightAdjLimit = _weightAdjLimit;
    }

    /**
     * @notice owner can set base threshold scale
     * @param _baseThresholdScale the max interest rate
     */
    function setBaseThresholdScale(uint256 _baseThresholdScale) external onlyGovernance {
        baseThresholdScale = _baseThresholdScale;
    }

    /**
     * @notice owner can set base threshold floor (min range size)
     * @param _baseThresholdFloor the max interest rate
     */
    function setBaseThresholdFloor(int24 _baseThresholdFloor) external onlyGovernance {
        baseThresholdFloor = _baseThresholdFloor;
    }

    /**
     * @notice owner can set max twap deviation for the ETH/USDC pool oracle
     * @param _maxTwapDeviationEthUsdc the max interest rate
     */
    function setMaxTwapDeviationEthUsdc(int24 _maxTwapDeviationEthUsdc) external onlyGovernance {
        maxTwapDeviationEthUsdc = _maxTwapDeviationEthUsdc;
    }

    /**
     * @notice owner can set max twap deviation for the oSQTH/ETH pool oracle
     * @param _maxTwapDeviationOsqthEth the max interest rate
     */
    function setMaxTwapDeviationOsqthEth(int24 _maxTwapDeviationOsqthEth) external onlyGovernance {
        maxTwapDeviationOsqthEth = _maxTwapDeviationOsqthEth;
    }

    /**
     * @notice owner can set the min rebalance threshold after which time-based rebalance can be activated
     * @param _rebalanceThreshold the min rebalance threshold
     */
    function setRebalanceThreshold(uint256 _rebalanceThreshold) external onlyGovernance {
        rebalanceThreshold = _rebalanceThreshold;
    }

    // @dev snapshot after each rebalance
    function setSnapshot(
        int24 _orderEthUsdcLower,
        int24 _orderEthUsdcUpper,
        int24 _orderOsqthEthLower,
        int24 _orderOsqthEthUpper,
        uint256 _timeAtLastRebalance,
        uint256 _interestRateAtLastRebalance,
        uint256 _ethPriceAtLastRebalance
    ) external override onlyVault {
        orderEthUsdcLower = _orderEthUsdcLower;
        orderEthUsdcUpper = _orderEthUsdcUpper;
        orderOsqthEthLower = _orderOsqthEthLower;
        orderOsqthEthUpper = _orderOsqthEthUpper;
        timeAtLastRebalance = _timeAtLastRebalance;
        interestRateAtLastRebalance = _interestRateAtLastRebalance;
        ethPriceAtLastRebalance = _ethPriceAtLastRebalance;
    }

    /// @dev accrude fees in eth
    function setAccruedFeesEth(uint256 _accruedFeesEth) external override onlyMath {
        accruedFeesEth = _accruedFeesEth;
    }

    /// @dev accrude fees in usdc
    function setAccruedFeesUsdc(uint256 _accruedFeesUsdc) external override onlyMath {
        accruedFeesUsdc = _accruedFeesUsdc;
    }

    /// @dev accrude fees in osqth
    function setAccruedFeesOsqth(uint256 _accruedFeesOsqth) external override onlyMath {
        accruedFeesOsqth = _accruedFeesOsqth;
    }

    /// @dev function to update accrude fees on withdrawals
    function updateAccruedFees(
        uint256 amountEth,
        uint256 amountUsdc,
        uint256 amountOsqth
    ) external override onlyVault {
        accruedFeesUsdc = accruedFeesUsdc - amountUsdc;
        accruedFeesEth = accruedFeesEth - amountEth;
        accruedFeesOsqth = accruedFeesOsqth - amountOsqth;
    }

    /// @dev function to set Time, IV, and ethPrice during the first deposit
    function setParamsBeforeDeposit(
        uint256 _timeAtLastRebalance,
        uint256 _interestRateAtLastRebalance,
        uint256 _ethPriceAtLastRebalance
    ) external override onlyVault {
        timeAtLastRebalance = _timeAtLastRebalance;
        interestRateAtLastRebalance = _interestRateAtLastRebalance;
        ethPriceAtLastRebalance = _ethPriceAtLastRebalance;
    }

    /// @dev governance can pause the contract
    function setPause(bool _pause) external onlyGovernance {
        isSystemPaused = _pause;

        emit SharedEvents.Paused(_pause);
    }
}