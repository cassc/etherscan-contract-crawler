// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

import "./interfaces/ILiquidation.sol";
import "./libraries/ErrorCodes.sol";
import "./InterconnectorLeaf.sol";

/**
 * This contract provides the liquidation functionality.
 */
contract Liquidation is ILiquidation, AccessControl, ReentrancyGuard, Multicall, InterconnectorLeaf {
    using SafeERC20 for IERC20;

    /// @notice Value is the Keccak-256 hash of "TRUSTED_LIQUIDATOR"
    /// @dev Role that's allowed to liquidate in Auto mode
    bytes32 public constant TRUSTED_LIQUIDATOR =
        bytes32(0xf81d27a41879d78d5568e0bc2989cb321b89b84d8e1b49895ee98604626c0218);
    /// @notice Value is the Keccak-256 hash of "MANUAL_LIQUIDATOR"
    /// @dev Role that's allowed to liquidate in Manual mode.
    ///      Each MANUAL_LIQUIDATOR address has to be appended to TRUSTED_LIQUIDATOR role too.
    bytes32 public constant MANUAL_LIQUIDATOR =
        bytes32(0x53402487d33e65b38c49f6f89bd08cbec4ff7c074cddd2357722b7917cd13f1e);
    /// @dev Value is the Keccak-256 hash of "TIMELOCK"
    bytes32 public constant TIMELOCK = bytes32(0xaefebe170cbaff0af052a32795af0e1b8afff9850f946ad2869be14f35534371);

    uint256 private constant EXP_SCALE = 1e18;

    /**
     * @notice Minterest supervisor contract
     */
    ISupervisor public immutable supervisor;

    /**
     * @notice The maximum allowable value of a healthy factor after liquidation, scaled by 1e18
     */
    uint256 public healthyFactorLimit = 1.2e18; // 120%

    /**
     * @notice Maximum sum in USD for internal liquidation. Collateral for loans that are less than this parameter will
     * be counted as protocol interest, scaled by 1e18
     */
    uint256 public insignificantLoanThreshold; // 0$ by default

    /**
     * @notice Minterest deadDrop address or contract
     */
    address public deadDrop;

    /**
     * @dev Flag that defines whether liquidation will update the processing state field of deaddrop contract
     */
    bool public useProcessingState;

    /**
     * @notice Construct a Liquidation contract
     * @param deadDrop_ Minterest deadDrop address
     * @param liquidators_ Array of addresses of liquidators
     * @param supervisor_ The address of the Supervisor contract
     * @param admin_ The address of the admin
     */
    constructor(
        address[] memory liquidators_,
        address deadDrop_,
        ISupervisor supervisor_,
        address admin_
    ) {
        require(deadDrop_ != address(0), ErrorCodes.ZERO_ADDRESS);
        require(address(supervisor_) != address(0), ErrorCodes.ZERO_ADDRESS);
        require(admin_ != address(0), ErrorCodes.ZERO_ADDRESS);

        supervisor = supervisor_;
        deadDrop = deadDrop_;
        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(TRUSTED_LIQUIDATOR, admin_);
        _grantRole(MANUAL_LIQUIDATOR, admin_);
        _grantRole(TIMELOCK, admin_);

        for (uint256 i = 0; i < liquidators_.length; i++) {
            _grantRole(TRUSTED_LIQUIDATOR, liquidators_[i]);
        }
    }

    /// @inheritdoc ILiquidation
    function liquidateUnsafeLoan(
        address borrower_,
        uint256[] memory seizeIndexes_,
        uint256[] memory debtRates_
    ) external onlyRole(TRUSTED_LIQUIDATOR) nonReentrant {
        AccountLiquidationAmounts memory accountState;

        IMToken[] memory accountAssets = supervisor.getAccountAssets(borrower_);
        verifyExternalData(accountAssets.length, seizeIndexes_, debtRates_);

        if (useProcessingState) {
            IDeadDrop(deadDrop).initialiseLiquidation(borrower_, block.number);
        }

        accrue(accountAssets, seizeIndexes_, debtRates_);
        accountState = calculateLiquidationAmounts(borrower_, accountAssets, seizeIndexes_, debtRates_);

        require(
            accountState.accountTotalCollateralUsd < accountState.accountTotalBorrowUsd,
            ErrorCodes.INSUFFICIENT_SHORTFALL
        );

        bool isManualLiquidation = hasRole(MANUAL_LIQUIDATOR, msg.sender);
        bool isDebtHealthy = accountState.accountPresumedTotalRepayUsd >= accountState.accountTotalBorrowUsd;

        seize(
            borrower_,
            accountAssets,
            accountState.seizeAmounts,
            accountState.accountTotalBorrowUsd <= insignificantLoanThreshold,
            isManualLiquidation
        );
        repay(borrower_, accountAssets, accountState.repayAmounts, isManualLiquidation);

        if (isDebtHealthy) {
            require(approveBorrowerHealthyFactor(borrower_, accountAssets), ErrorCodes.HEALTHY_FACTOR_NOT_IN_RANGE);
        }

        emit ReliableLiquidation(
            isManualLiquidation,
            isDebtHealthy,
            msg.sender,
            borrower_,
            accountAssets,
            seizeIndexes_,
            debtRates_
        );
    }

    /**
     * @notice Checks if input data meets requirements
     * @param accountAssetsLength The length of borrower's accountAssets array
     * @param seizeIndexes_ An array with market indexes that will be used as collateral.
     *        Each element corresponds to the market index in the accountAssets array
     * @param debtRates_ An array of debt redemption rates for each debt markets (scaled by 1e18).
     * @dev Indexes for arrays accountAssets && debtRates match each other
     */
    function verifyExternalData(
        uint256 accountAssetsLength,
        uint256[] memory seizeIndexes_,
        uint256[] memory debtRates_
    ) internal pure {
        uint256 debtRatesLength = debtRates_.length;
        uint256 seizeIndexesLength = seizeIndexes_.length;

        require(accountAssetsLength != 0 && debtRatesLength == accountAssetsLength, ErrorCodes.LQ_INVALID_DRR_ARRAY);
        require(
            seizeIndexesLength != 0 && seizeIndexesLength <= accountAssetsLength,
            ErrorCodes.LQ_INVALID_SEIZE_ARRAY
        );

        // Check all DRR are <= 100%
        for (uint256 i = 0; i < debtRatesLength; i++) {
            require(debtRates_[i] <= EXP_SCALE, ErrorCodes.LQ_INVALID_DEBT_REDEMPTION_RATE);
        }

        // Check all seizeIndexes are <= to (accountAssetsLength - 1)
        for (uint256 i = 0; i < seizeIndexesLength; i++) {
            require(seizeIndexes_[i] < accountAssetsLength, ErrorCodes.LQ_INVALID_SEIZE_INDEX);
            // Check seizeIndexes array does not contain duplicates
            for (uint256 j = i + 1; j < seizeIndexesLength; j++) {
                require(seizeIndexes_[i] != seizeIndexes_[j], ErrorCodes.LQ_DUPLICATE_SEIZE_INDEX);
            }
        }
    }

    /// @inheritdoc ILiquidation
    function accrue(
        IMToken[] memory accountAssets,
        uint256[] memory seizeIndexes_,
        uint256[] memory debtRates_
    ) public {
        for (uint256 i = 0; i < accountAssets.length; i++) {
            // slither-disable-next-line reentrancy-events
            if (debtRates_[i] > 0 || includes(i, seizeIndexes_)) accountAssets[i].accrueInterest();
        }
    }

    /**
     * @notice Determines whether an array includes a certain value among its entries
     * @param index_ The value to search for
     * @param seizeIndexes_ An array with market indexes that will be used as collateral.
     * @return bool Returning true or false as appropriate.
     */
    function includes(uint256 index_, uint256[] memory seizeIndexes_) internal pure returns (bool) {
        for (uint256 i = 0; i < seizeIndexes_.length; i++) {
            if (seizeIndexes_[i] == index_) return true;
        }
        return false;
    }

    /**
     * @dev Local marketParams for avoiding stack-depth limits in calculating liquidation amounts.
     */
    struct MarketParams {
        uint256 supplyWrap;
        uint256 borrowUnderlying;
        uint256 exchangeRateMantissa;
        uint256 liquidationFeeMantissa;
        uint256 utilisationFactorMantissa;
    }

    /// @inheritdoc ILiquidation
    function calculateLiquidationAmounts(
        address account_,
        IMToken[] memory marketAddresses,
        uint256[] memory seizeIndexes_,
        uint256[] memory debtRates_
    ) public view virtual returns (AccountLiquidationAmounts memory accountState) {
        uint256 accountTotalRepayUsd = 0;
        uint256 accountMarketsLen = marketAddresses.length;
        uint256[] memory presumedRepaysUsd = new uint256[](accountMarketsLen);
        uint256[] memory oraclePrices = new uint256[](accountMarketsLen);
        uint256[] memory liquidationFeeMultipliers = new uint256[](accountMarketsLen);

        accountState.repayAmounts = new uint256[](accountMarketsLen);
        accountState.seizeAmounts = new uint256[](accountMarketsLen);

        IPriceOracle cachedOracle = oracle();
        // calculate liquidation amounts for each market the borrower is in,
        // update accountState with accumulated values within the same loop
        for (uint256 i = 0; i < accountMarketsLen; i++) {
            IMToken market = marketAddresses[i];

            // oracle price of each processed token must exist
            oraclePrices[i] = cachedOracle.getUnderlyingPrice(market);
            require(oraclePrices[i] > 0, ErrorCodes.INVALID_PRICE);

            // slither-disable-next-line uninitialized-local
            MarketParams memory vars;
            (vars.supplyWrap, vars.borrowUnderlying, vars.exchangeRateMantissa) = market.getAccountSnapshot(account_);
            (vars.liquidationFeeMantissa, vars.utilisationFactorMantissa) = supervisor.getMarketData(market);

            // account position has borrowed assets in the market
            if (vars.borrowUnderlying > 0) {
                // collect accumulated value of accountState.accountTotalBorrowUsd:
                // accountTotalBorrowUsd += borrowUnderlying * oraclePrice
                uint256 accountBorrowUsd = (vars.borrowUnderlying * oraclePrices[i]) / EXP_SCALE;
                accountState.accountTotalBorrowUsd += accountBorrowUsd;

                // there is a debt on this market that should be repaid
                if (debtRates_[i] > 0) {
                    // repayAmountUnderlying = borrowUnderlying * redemptionRate
                    accountState.repayAmounts[i] = (vars.borrowUnderlying * debtRates_[i]) / EXP_SCALE;

                    accountTotalRepayUsd += (accountBorrowUsd * debtRates_[i]) / EXP_SCALE;
                }
            }

            // account position has supplied assets in the market
            if (vars.supplyWrap > 0) {
                // (1 + liquidationFee) value is stored for the future use as liquidationFeeMultipliers
                liquidationFeeMultipliers[i] = vars.liquidationFeeMantissa + EXP_SCALE;

                // supplyAmount = supplyWrap * exchangeRate
                uint256 supplyAmount = (vars.supplyWrap * vars.exchangeRateMantissa) / EXP_SCALE;
                uint256 accountSupplyUsd = (supplyAmount * oraclePrices[i]) / EXP_SCALE;

                // presumed repay in USD is a portion of the debt that is coverable by the current supply
                uint256 presumedRepayUsd = ((accountSupplyUsd * EXP_SCALE) / liquidationFeeMultipliers[i]);

                // collect accumulated value of accountState.accountPresumedTotalRepayUsd:
                // accountPresumedTotalRepayUsd value means what the totalRepay would be possible
                // under the condition of complete liquidation.
                accountState.accountPresumedTotalRepayUsd += presumedRepayUsd;

                // collect accumulated value of accountState.accountTotalSupplyUsd:
                // accountTotalSupplyUsd += supplyWrap * exchangeRate * oraclePrice
                accountState.accountTotalSupplyUsd += accountSupplyUsd;
                presumedRepaysUsd[i] = presumedRepayUsd;

                // accountTotalCollateralUsd += accountSupplyUsd * utilisationFactor
                accountState.accountTotalCollateralUsd +=
                    (accountSupplyUsd * vars.utilisationFactorMantissa) /
                    EXP_SCALE;
            }
        }

        if (accountTotalRepayUsd > 0) {
            // calculate seize amounts per market
            for (uint256 i = 0; i < seizeIndexes_.length; i++) {
                uint256 marketIndex = seizeIndexes_[i];
                uint256 marketPresumedRepayUsd = presumedRepaysUsd[marketIndex];

                if (marketPresumedRepayUsd <= accountTotalRepayUsd) {
                    accountState.seizeAmounts[marketIndex] = type(uint256).max;
                    accountTotalRepayUsd -= marketPresumedRepayUsd;
                } else {
                    accountState.seizeAmounts[marketIndex] =
                        (accountTotalRepayUsd * (liquidationFeeMultipliers[marketIndex])) /
                        oraclePrices[marketIndex];
                    accountTotalRepayUsd = 0;
                    break;
                }
            }
            require(accountTotalRepayUsd == 0, ErrorCodes.LQ_INVALID_SEIZE_DISTRIBUTION);
        }
        return accountState;
    }

    /**
     * @dev Burns collateral tokens at the borrower's address, transfer underlying assets
     *      to the deadDrop or ManualLiquidator address, if loan is not insignificant, otherwise, all account's
     *      collateral is credited to the protocolInterest. Process all borrower's markets.
     * @param borrower_ The account having collateral seized
     * @param marketAddresses_ Array of markets the borrower is in
     * @param seizeUnderlyingAmounts_ Array of seize amounts in underlying assets
     * @param isLoanInsignificant_ Marker for insignificant loan whose collateral must be credited to the
     *        protocolInterest
     * @param isManualLiquidation_ Marker for manual liquidation process.
     */
    function seize(
        address borrower_,
        IMToken[] memory marketAddresses_,
        uint256[] memory seizeUnderlyingAmounts_,
        bool isLoanInsignificant_,
        bool isManualLiquidation_
    ) internal {
        for (uint256 i = 0; i < marketAddresses_.length; i++) {
            uint256 seizeUnderlyingAmount = seizeUnderlyingAmounts_[i];
            if (seizeUnderlyingAmount > 0) {
                address receiver = isManualLiquidation_ ? msg.sender : address(deadDrop);

                IMToken seizeMarket = marketAddresses_[i];
                seizeMarket.autoLiquidationSeize(borrower_, seizeUnderlyingAmount, isLoanInsignificant_, receiver);
            }
        }
    }

    /**
     * @dev Liquidator repays a borrow belonging to borrower. Process all borrower's markets.
     * @param borrower_ The account with the debt being payed off
     * @param marketAddresses_ Array of markets the borrower is in
     * @param repayAmounts_ Array of repay amounts in underlying assets
     * @param isManualLiquidation_ Marker for manual liquidation process.
     * Note: The calling code must be sure that the oracle price for all processed markets is greater than zero.
     */
    function repay(
        address borrower_,
        IMToken[] memory marketAddresses_,
        uint256[] memory repayAmounts_,
        bool isManualLiquidation_
    ) internal {
        for (uint256 i = 0; i < marketAddresses_.length; i++) {
            uint256 repayAmount = repayAmounts_[i];
            if (repayAmount > 0) {
                IMToken repayMarket = marketAddresses_[i];

                if (isManualLiquidation_) {
                    repayMarket.addProtocolInterestBehalf(msg.sender, repayAmount);
                }

                repayMarket.autoLiquidationRepayBorrow(borrower_, repayAmount);
            }
        }
    }

    /**
     * @dev Approve that current healthy factor satisfies the condition:
     *      currentHealthyFactor <= healthyFactorLimit
     * @param borrower_ The account with the debt being payed off
     * @param marketAddresses_ Array of markets the borrower is in
     * @return Whether or not the current account healthy factor is correct
     */
    function approveBorrowerHealthyFactor(address borrower_, IMToken[] memory marketAddresses_)
        internal
        view
        returns (bool)
    {
        uint256 accountTotalCollateral = 0;
        uint256 accountTotalBorrow = 0;

        uint256 supplyWrap;
        uint256 borrowUnderlying;
        uint256 exchangeRateMantissa;
        uint256 utilisationFactorMantissa;

        IPriceOracle cachedOracle = oracle();
        for (uint256 i = 0; i < marketAddresses_.length; i++) {
            IMToken market = marketAddresses_[i];
            uint256 oraclePriceMantissa = cachedOracle.getUnderlyingPrice(market);
            require(oraclePriceMantissa > 0, ErrorCodes.INVALID_PRICE);

            (supplyWrap, borrowUnderlying, exchangeRateMantissa) = market.getAccountSnapshot(borrower_);

            if (borrowUnderlying > 0) {
                accountTotalBorrow += ((borrowUnderlying * oraclePriceMantissa) / EXP_SCALE);
            }
            if (supplyWrap > 0) {
                (, utilisationFactorMantissa) = supervisor.getMarketData(market);
                uint256 supplyAmountUsd = ((((supplyWrap * exchangeRateMantissa) / EXP_SCALE) * oraclePriceMantissa) /
                    EXP_SCALE);
                accountTotalCollateral += (supplyAmountUsd * utilisationFactorMantissa) / EXP_SCALE;
            }
        }
        // currentHealthyFactor = accountTotalCollateral / accountTotalBorrow
        uint256 currentHealthyFactor = (accountTotalCollateral * EXP_SCALE) / accountTotalBorrow;

        return (currentHealthyFactor <= healthyFactorLimit);
    }

    /*** Admin Functions ***/

    /// @inheritdoc ILiquidation
    function setHealthyFactorLimit(uint256 newValue_) external onlyRole(TIMELOCK) {
        uint256 oldValue = healthyFactorLimit;

        require(newValue_ != oldValue, ErrorCodes.IDENTICAL_VALUE);
        healthyFactorLimit = newValue_;

        emit HealthyFactorLimitChanged(oldValue, newValue_);
    }

    /// @inheritdoc ILiquidation
    function setDeadDrop(address newDeadDrop_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(newDeadDrop_ != address(0), ErrorCodes.ZERO_ADDRESS);

        address oldDeadDrop = deadDrop;
        deadDrop = newDeadDrop_;

        emit NewDeadDrop(oldDeadDrop, newDeadDrop_);
    }

    /// @inheritdoc ILiquidation
    function setInsignificantLoanThreshold(uint256 newValue_) external onlyRole(TIMELOCK) {
        uint256 oldValue = insignificantLoanThreshold;
        insignificantLoanThreshold = newValue_;

        emit NewInsignificantLoanThreshold(oldValue, newValue_);
    }

    /// @inheritdoc ILiquidation
    function setProcessingStateUsage(bool newValue) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(useProcessingState != newValue, ErrorCodes.IDENTICAL_VALUE);
        useProcessingState = newValue;
        emit ProcessingStateUsageChanged(newValue);
    }

    /// @notice get contract PriceOracle
    function oracle() internal view returns (IPriceOracle) {
        return getInterconnector().oracle();
    }
}