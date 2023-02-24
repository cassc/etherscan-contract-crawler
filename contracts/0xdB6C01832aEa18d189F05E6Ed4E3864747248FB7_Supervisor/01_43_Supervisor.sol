// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./interfaces/ISupervisor.sol";
import "./libraries/PauseControl.sol";
import "./libraries/ErrorCodes.sol";
import "./InterconnectorLeaf.sol";

/**
 * @title Minterest Supervisor Contract
 * @author Minterest
 */
contract Supervisor is ISupervisor, Initializable, ReentrancyGuard, AccessControl, PauseControl, InterconnectorLeaf {
    using SafeCast for uint256;

    struct MarketState {
        // Whether or not this market is listed
        bool isListed;
        // Multiplier representing the most one can borrow against their collateral in this market.
        // For instance, 0.9 to allow borrowing 90% of collateral value.
        // Must be between 0 and 1, and stored as a mantissa.
        uint256 utilisationFactorMantissa;
        // Per-market mapping of "accounts in this asset"
        mapping(address => bool) accountMembership;
        // Multiplier representing the additional collateral which is taken from borrowers
        // as a penalty for being liquidated
        uint256 liquidationFeeMantissa;
    }

    /// @dev Value is the Keccak-256 hash of "GATEKEEPER"
    bytes32 public constant GATEKEEPER = bytes32(0x20162831d2f54c3e11eebafebfeda495d4c52c67b1708251179ec91fb76dd3b2);
    /// @dev Value is the Keccak-256 hash of "TIMELOCK"
    bytes32 public constant TIMELOCK = bytes32(0xaefebe170cbaff0af052a32795af0e1b8afff9850f946ad2869be14f35534371);

    /// @dev No utilisationFactorMantissa may exceed this value
    uint256 internal constant UTILISATION_FACTOR_MAX_MANTISSA = 0.95e18; // 0.95
    uint256 internal constant EXP_SCALE = 1e18;

    /// @notice Per-account mapping of "assets you are in"
    mapping(address => IMToken[]) public accountAssets;

    /// @notice Collection of states of supported markets
    mapping(IMToken => MarketState) public markets;

    /// @notice A list of all markets
    IMToken[] public allMarkets;

    /// @notice Borrow caps enforced by beforeBorrow for each mToken address.
    ///         Defaults to zero which corresponds to unlimited borrowing.
    mapping(IMToken => uint256) public borrowCaps;

    /// @notice RewardsHub contract
    IRewardsHub public rewardsHub;

    constructor() {
        _disableInitializers();
    }

    /**
     * @notice initialize Supervisor contract
     * @param admin_ admin address
     * @param rewardsHub_ RewardsHub contract address
     */
    function initialize(address admin_, IRewardsHub rewardsHub_) external initializer {
        rewardsHub = rewardsHub_;

        _grantRole(DEFAULT_ADMIN_ROLE, admin_);
        _grantRole(GATEKEEPER, admin_);
        _grantRole(TIMELOCK, admin_);
    }

    /***  Manage your collateral assets ***/

    /// @inheritdoc ISupervisor
    function getAccountAssets(address account) external view returns (IMToken[] memory) {
        return accountAssets[account];
    }

    /// @inheritdoc ISupervisor
    function checkMembership(address account, IMToken mToken) external view returns (bool) {
        return markets[mToken].accountMembership[account];
    }

    /// @inheritdoc ISupervisor
    function enableAsCollateral(IMToken[] memory mTokens) external virtual {
        require(isNotBlacklisted(msg.sender), ErrorCodes.ADDRESS_IS_BLACKLISTED);

        uint256 len = mTokens.length;
        for (uint256 i = 0; i < len; i++) {
            require(markets[mTokens[i]].isListed, ErrorCodes.MARKET_NOT_LISTED);
            enableMarketAsCollateralInternal(IMToken(mTokens[i]), msg.sender);
        }
    }

    /**
     * @dev Add the market to the borrower's "assets in" for liquidity calculations
     * @param mToken The market to enable as collateral
     * @param account The address of the account to modify
     */
    function enableMarketAsCollateralInternal(IMToken mToken, address account) internal {
        MarketState storage marketToEnableAsCollateral = markets[mToken];
        if (marketToEnableAsCollateral.accountMembership[account]) {
            return; // already joined
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if particular market is enabled for an account
        marketToEnableAsCollateral.accountMembership[account] = true;
        accountAssets[account].push(mToken);

        emit MarketEnabledAsCollateral(mToken, account);
    }

    /// @inheritdoc ISupervisor
    function disableAsCollateral(IMToken mTokenAddress) external virtual {
        IMToken mToken = IMToken(mTokenAddress);
        /* Get sender tokensHeld and amountOwed underlying from the mToken */
        (uint256 tokensHeld, uint256 amountOwed, ) = mToken.getAccountSnapshot(msg.sender);

        /* Fail if the sender has a borrow balance */
        require(amountOwed == 0, ErrorCodes.BALANCE_OWED);

        /* Fail if the sender is not permitted to redeem all of their tokens */
        beforeRedeemInternal(mTokenAddress, msg.sender, tokensHeld, false);

        MarketState storage marketToDisable = markets[mToken];

        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToDisable.accountMembership[msg.sender]) {
            return;
        }

        /* Set mToken account membership to false */
        delete marketToDisable.accountMembership[msg.sender];

        /* Delete mToken from the account’s list of assets */
        // load into memory for faster iteration
        IMToken[] memory accountAssetList = accountAssets[msg.sender];
        uint256 len = accountAssetList.length;
        uint256 assetIndex = len;
        for (uint256 i = 0; i < len; i++) {
            if (accountAssetList[i] == mToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        IMToken[] storage storedList = accountAssets[msg.sender];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.pop();

        emit MarketDisabledAsCollateral(mToken, msg.sender);
    }

    /*** Policy Hooks ***/

    /// @inheritdoc ISupervisor
    function beforeLend(IMToken mToken, address lender)
        external
        virtual
        checkPausedSubject(LEND_OP, address(mToken))
        whitelistMode(lender)
    {
        require(markets[mToken].isListed, ErrorCodes.MARKET_NOT_LISTED);
        // block users from lending if AML says so
        require(isNotBlacklisted(lender), ErrorCodes.ADDRESS_IS_BLACKLISTED);

        // Trigger Emission system
        rewardsHub.distributeSupplierMnt(mToken, lender);
    }

    /// @inheritdoc ISupervisor
    function beforeRedeem(
        IMToken mToken,
        address redeemer,
        uint256 redeemTokens,
        bool isAmlProcess
    ) external virtual nonReentrant whitelistMode(redeemer) {
        beforeRedeemInternal(mToken, redeemer, redeemTokens, isAmlProcess);

        // Trigger Emission system
        rewardsHub.distributeSupplierMnt(mToken, redeemer);
    }

    /**
     * @dev Checks if the account should be allowed to redeem tokens in the given market
     * @param mToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of mTokens to exchange for the underlying asset in the market
     * @param isAmlProcess Do we need to check the AML system or not
     */
    function beforeRedeemInternal(
        IMToken mToken,
        address redeemer,
        uint256 redeemTokens,
        bool isAmlProcess
    ) internal view {
        require(markets[mToken].isListed, ErrorCodes.MARKET_NOT_LISTED);

        /* If we are within the AML process, then we check the redeemer address for the presence in
        prohibited addresses */
        if (isAmlProcess) {
            require(!isNotBlacklisted(redeemer), ErrorCodes.ADDRESS_IS_NOT_IN_AML_SYSTEM);
        }

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[mToken].accountMembership[redeemer]) {
            return;
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (, uint256 shortfall) = getHypotheticalAccountLiquidity(redeemer, mToken, redeemTokens, 0);
        require(shortfall == 0, ErrorCodes.INSUFFICIENT_LIQUIDITY);
    }

    /// @inheritdoc ISupervisor
    function redeemVerify(uint256 redeemAmount, uint256 redeemTokens) external view virtual {
        // Require tokens is zero or amount is also zero
        require(redeemTokens > 0 || redeemAmount == 0, ErrorCodes.INVALID_REDEEM);
    }

    /// @inheritdoc ISupervisor
    function beforeBorrow(
        IMToken mToken,
        address borrower,
        uint256 borrowAmount
    ) external virtual checkPausedSubject(BORROW_OP, address(mToken)) nonReentrant whitelistMode(borrower) {
        require(markets[mToken].isListed, ErrorCodes.MARKET_NOT_LISTED);
        // Check against aml and block borrow if address is blacklisted
        require(isNotBlacklisted(borrower), ErrorCodes.ADDRESS_IS_BLACKLISTED);

        if (!markets[mToken].accountMembership[borrower]) {
            // only mTokens may call beforeBorrow if borrower not in market
            require(msg.sender == address(mToken), ErrorCodes.INVALID_SENDER);

            // attempt to enable market for the borrower
            enableMarketAsCollateralInternal(mToken, borrower);

            // it should be impossible to break the important invariant
            assert(markets[mToken].accountMembership[borrower]);
        }

        require(oracle().getUnderlyingPrice(mToken) > 0, ErrorCodes.INVALID_PRICE);

        uint256 borrowCap = borrowCaps[mToken];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint256 totalBorrows = mToken.totalBorrows();
            uint256 nextTotalBorrows = totalBorrows + borrowAmount;
            require(nextTotalBorrows < borrowCap, ErrorCodes.BORROW_CAP_REACHED);
        }

        (, uint256 shortfall) = getHypotheticalAccountLiquidity(borrower, mToken, 0, borrowAmount);
        require(shortfall == 0, ErrorCodes.INSUFFICIENT_LIQUIDITY);

        // Trigger Emission system
        rewardsHub.distributeBorrowerMnt(mToken, borrower);
    }

    /// @inheritdoc ISupervisor
    function beforeRepayBorrow(IMToken mToken, address borrower) external virtual nonReentrant whitelistMode(borrower) {
        require(markets[mToken].isListed, ErrorCodes.MARKET_NOT_LISTED);
        // Trigger Emission system
        rewardsHub.distributeBorrowerMnt(mToken, borrower);
    }

    /// @inheritdoc ISupervisor
    function beforeAutoLiquidationSeize(
        IMToken mToken,
        address liquidator_,
        address borrower
    ) external virtual nonReentrant {
        isLiquidator(liquidator_);
        // Trigger Emission system
        rewardsHub.distributeSupplierMnt(mToken, borrower);
    }

    /// @inheritdoc ISupervisor
    function isLiquidator(address liquidator_) public view virtual {
        require(liquidator() == ILiquidation(liquidator_), ErrorCodes.UNRELIABLE_LIQUIDATOR);
    }

    /// @inheritdoc ISupervisor
    function beforeAutoLiquidationRepay(
        address liquidator_,
        address borrower_,
        IMToken mToken_
    ) external virtual nonReentrant {
        isLiquidator(liquidator_);
        // Trigger Emission system
        rewardsHub.distributeBorrowerMnt(mToken_, borrower_);
    }

    /// @inheritdoc ISupervisor
    function beforeTransfer(
        IMToken mToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external virtual checkPaused(TRANSFER_OP) nonReentrant {
        // Transfer of the mTokens is blocked for blacklisted accounts
        require(isNotBlacklisted(src), ErrorCodes.ADDRESS_IS_BLACKLISTED);
        require(isNotBlacklisted(dst), ErrorCodes.ADDRESS_IS_BLACKLISTED);

        // Additionally check if src is allowed to redeem this many tokens
        beforeRedeemInternal(mToken, src, transferTokens, false);

        // Trigger Emission system
        rewardsHub.distributeSupplierMnt(mToken, src);
        rewardsHub.distributeSupplierMnt(mToken, dst);
    }

    /// @inheritdoc ISupervisor
    function beforeFlashLoan(
        IMToken mToken,
        address receiver,
        uint256, /* amount */
        uint256 /* fee */
    ) external view virtual checkPausedSubject(FLASH_LOAN_OP, address(mToken)) {
        require(markets[mToken].isListed, ErrorCodes.MARKET_NOT_LISTED);
        require(isNotBlacklisted(receiver), ErrorCodes.ADDRESS_IS_BLACKLISTED);
    }

    /*** Liquidity/Liquidation Calculations ***/

    /// @inheritdoc ISupervisor
    function getAccountLiquidity(address account) external view returns (uint256, uint256) {
        return getHypotheticalAccountLiquidity(account, IMToken(address(0)), 0, 0);
    }

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `mTokenBalance` is the number of mTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint256 sumCollateral;
        uint256 sumBorrowPlusEffects;
        uint256 mTokenBalance;
        uint256 borrowBalance;
        uint256 utilisationFactor;
        uint256 exchangeRate;
        uint256 oraclePrice;
        uint256 tokensToDenom;
    }

    /// @inheritdoc ISupervisor
    function getHypotheticalAccountLiquidity(
        address account,
        IMToken mTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    ) public view returns (uint256, uint256) {
        AccountLiquidityLocalVars memory vars; // Holds all our calculation results

        // For each asset the account is in
        IMToken[] memory assets = accountAssets[account];
        for (uint256 i = 0; i < assets.length; i++) {
            IMToken asset = assets[i];

            // Read the balances and exchange rate from the mToken
            (vars.mTokenBalance, vars.borrowBalance, vars.exchangeRate) = asset.getAccountSnapshot(account);
            vars.utilisationFactor = markets[asset].utilisationFactorMantissa;

            // Get the normalized price of the asset
            vars.oraclePrice = oracle().getUnderlyingPrice(asset);
            require(vars.oraclePrice > 0, ErrorCodes.INVALID_PRICE);

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.tokensToDenom =
                (((vars.utilisationFactor * vars.exchangeRate) / EXP_SCALE) * vars.oraclePrice) /
                EXP_SCALE;

            // sumCollateral += tokensToDenom * mTokenBalance
            vars.sumCollateral += (vars.tokensToDenom * vars.mTokenBalance) / EXP_SCALE;

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects += (vars.oraclePrice * vars.borrowBalance) / EXP_SCALE;

            // Calculate effects of interacting with mTokenModify
            if (asset == mTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects += (vars.tokensToDenom * redeemTokens) / EXP_SCALE;

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects += (vars.oraclePrice * borrowAmount) / EXP_SCALE;
            }
        }

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    /// @inheritdoc ISupervisor
    function getMarketData(IMToken market) external view returns (uint256, uint256) {
        return (markets[market].liquidationFeeMantissa, markets[market].utilisationFactorMantissa);
    }

    /*** Admin Functions ***/

    /// @inheritdoc ISupervisor
    function setUtilisationFactor(IMToken mToken, uint256 newUtilisationFactorMantissa) external onlyRole(TIMELOCK) {
        MarketState storage market = markets[mToken];
        require(market.isListed, ErrorCodes.MARKET_NOT_LISTED);

        // Check utilisation factor <= UTILISATION_FACTOR_MAX_MANTISSA
        require(
            newUtilisationFactorMantissa <= UTILISATION_FACTOR_MAX_MANTISSA,
            ErrorCodes.INVALID_UTILISATION_FACTOR_MANTISSA
        );

        // If utilisation factor = 0 than price can be any. Otherwise price must be > 0.
        require(newUtilisationFactorMantissa == 0 || oracle().getUnderlyingPrice(mToken) > 0, ErrorCodes.INVALID_PRICE);

        // Set market's utilisation factor to new utilisation factor, remember old value
        uint256 oldUtilisationFactorMantissa = market.utilisationFactorMantissa;
        market.utilisationFactorMantissa = newUtilisationFactorMantissa;

        // Emit event with asset, old utilisation factor, and new utilisation factor
        emit NewUtilisationFactor(mToken, oldUtilisationFactorMantissa, newUtilisationFactorMantissa);
    }

    /// @inheritdoc ISupervisor
    function setLiquidationFee(IMToken mToken, uint256 newLiquidationFeeMantissa) external onlyRole(TIMELOCK) {
        require(newLiquidationFeeMantissa > 0, ErrorCodes.LIQUIDATION_FEE_MANTISSA_SHOULD_BE_GREATER_THAN_ZERO);

        MarketState storage market = markets[mToken];
        require(market.isListed, ErrorCodes.MARKET_NOT_LISTED);

        uint256 oldLiquidationFeeMantissa = market.liquidationFeeMantissa;
        market.liquidationFeeMantissa = newLiquidationFeeMantissa;

        emit NewLiquidationFee(mToken, oldLiquidationFeeMantissa, newLiquidationFeeMantissa);
    }

    /// @inheritdoc ISupervisor
    function supportMarket(IMToken mToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!markets[mToken].isListed, ErrorCodes.MARKET_ALREADY_LISTED);

        markets[mToken].isListed = true;
        markets[mToken].utilisationFactorMantissa = 0;
        markets[mToken].liquidationFeeMantissa = 0;
        allMarkets.push(mToken);

        emit MarketListed(mToken);

        rewardsHub.initMarket(mToken);
    }

    /// @inheritdoc ISupervisor
    function setMarketBorrowCaps(IMToken[] calldata mTokens, uint256[] calldata newBorrowCaps)
        external
        onlyRole(GATEKEEPER)
    {
        uint256 numMarkets = mTokens.length;
        uint256 numBorrowCaps = newBorrowCaps.length;

        require(numMarkets != 0 && numMarkets == numBorrowCaps, ErrorCodes.INVALID_MTOKENS_OR_BORROW_CAPS);

        for (uint256 i = 0; i < numMarkets; i++) {
            borrowCaps[mTokens[i]] = newBorrowCaps[i];
            emit NewBorrowCap(mTokens[i], newBorrowCaps[i]);
        }
    }

    /// @inheritdoc ISupervisor
    function getAllMarkets() external view returns (IMToken[] memory) {
        return allMarkets;
    }

    /// @inheritdoc ISupervisor
    function isMarketListed(IMToken market) external view returns (bool) {
        return markets[market].isListed;
    }

    /// @inheritdoc ISupervisor
    function isNotBlacklisted(address) public view virtual returns (bool) {
        return true;
    }

    /// @inheritdoc ISupervisor
    function isMntTransferAllowed(address, address) external view virtual returns (bool) {
        return true;
    }

    /// @inheritdoc ISupervisor
    function getBlockNumber() public view virtual returns (uint256) {
        return block.number;
    }

    /**
     * @dev Check protocol operation mode. In whitelist mode, only members from whitelist and who have Minterest NFT
     * can work with protocol.
     */
    modifier whitelistMode(address account) {
        require(whitelist().isWhitelisted(account), ErrorCodes.WHITELISTED_ONLY);
        _;
    }

    /*** Pause control ****
     *
     * The gatekeeper can pause certain actions as a safety mechanism
     * and can set borrowCaps to any number for any market.
     * Actions which allow accounts to remove their own assets cannot be paused.
     * Transfer can only be paused globally, not by market.
     * Lowering the borrow cap could disable borrowing on the given market.
     */

    bytes32 internal constant LEND_OP = "Lend";
    bytes32 internal constant BORROW_OP = "Borrow";
    bytes32 internal constant FLASH_LOAN_OP = "FlashLoan";
    bytes32 internal constant TRANSFER_OP = "Transfer";

    function validatePause(address subject) internal view override {
        require(hasRole(GATEKEEPER, msg.sender), ErrorCodes.UNAUTHORIZED);
        if (subject != address(0)) {
            require(markets[IMToken(subject)].isListed, ErrorCodes.MARKET_NOT_LISTED);
        }
    }

    function validateUnpause(address subject) internal view override {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), ErrorCodes.UNAUTHORIZED);
        if (subject != address(0)) {
            require(markets[IMToken(subject)].isListed, ErrorCodes.MARKET_NOT_LISTED);
        }
    }

    // // // // Utils

    function oracle() internal view returns (IPriceOracle) {
        return getInterconnector().oracle();
    }

    function whitelist() internal view returns (IWhitelist) {
        return getInterconnector().whitelist();
    }

    function liquidator() internal view returns (ILiquidation) {
        return getInterconnector().liquidation();
    }
}