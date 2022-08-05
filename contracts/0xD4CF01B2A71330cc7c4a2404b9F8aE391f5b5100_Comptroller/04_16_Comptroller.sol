pragma solidity ^0.5.16;

import "./ApeToken.sol";
import "./ErrorReporter.sol";
import "./Exponential.sol";
import "./PriceOracle/PriceOracle.sol";
import "./ComptrollerInterface.sol";
import "./ComptrollerStorage.sol";
import "./LiquidityMiningInterface.sol";
import "./Unitroller.sol";

/**
 * @title ApeFinance's Comptroller Contract
 */
contract Comptroller is ComptrollerV1Storage, ComptrollerInterface, ComptrollerErrorReporter, Exponential {
    /// @notice Emitted when an admin supports a market
    event MarketListed(ApeToken apeToken);

    /// @notice Emitted when an admin delists a market
    event MarketDelisted(ApeToken apeToken);

    /// @notice Emitted when an account enters a market
    event MarketEntered(ApeToken apeToken, address account);

    /// @notice Emitted when an account exits a market
    event MarketExited(ApeToken apeToken, address account);

    /// @notice Emitted when close factor is changed by admin
    event NewCloseFactor(uint256 oldCloseFactorMantissa, uint256 newCloseFactorMantissa);

    /// @notice Emitted when a collateral factor is changed by admin
    event NewCollateralFactor(
        ApeToken apeToken,
        uint256 oldCollateralFactorMantissa,
        uint256 newCollateralFactorMantissa
    );

    /// @notice Emitted when liquidation incentive is changed by admin
    event NewLiquidationIncentive(uint256 oldLiquidationIncentiveMantissa, uint256 newLiquidationIncentiveMantissa);

    /// @notice Emitted when price oracle is changed
    event NewPriceOracle(PriceOracle oldPriceOracle, PriceOracle newPriceOracle);

    /// @notice Emitted when pause guardian is changed
    event NewPauseGuardian(address oldPauseGuardian, address newPauseGuardian);

    /// @notice Emitted when liquidity mining module is changed
    event NewLiquidityMining(address oldLiquidityMining, address newLiquidityMining);

    /// @notice Emitted when an action is paused globally
    event ActionPaused(string action, bool pauseState);

    /// @notice Emitted when an action is paused on a market
    event ActionPaused(ApeToken apeToken, string action, bool pauseState);

    /// @notice Emitted when borrow cap for a apeToken is changed
    event NewBorrowCap(ApeToken indexed apeToken, uint256 newBorrowCap);

    /// @notice Emitted when supply cap for a apeToken is changed
    event NewSupplyCap(ApeToken indexed apeToken, uint256 newSupplyCap);

    /// @notice Emitted when protocol's credit limit has changed
    event CreditLimitChanged(address protocol, address market, uint256 creditLimit);

    /// @notice Emitted when credit limit manager is changed
    event NewCreditLimitManager(address oldCreditLimitManager, address newCreditLimitManager);

    // No collateralFactorMantissa may exceed this value
    uint256 internal constant collateralFactorMaxMantissa = 0.9e18; // 0.9

    constructor() public {
        admin = msg.sender;
    }

    /*** Assets You Are In ***/

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has entered
     */
    function getAssetsIn(address account) external view returns (ApeToken[] memory) {
        ApeToken[] memory assetsIn = accountAssets[account];

        return assetsIn;
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param apeToken The apeToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, ApeToken apeToken) external view returns (bool) {
        return markets[address(apeToken)].accountMembership[account];
    }

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param apeTokens The list of addresses of the apeToken markets to be enabled
     */
    function enterMarkets(address[] memory apeTokens) public {
        for (uint256 i = 0; i < apeTokens.length; i++) {
            ApeToken apeToken = ApeToken(apeTokens[i]);

            addToMarketInternal(apeToken, msg.sender);
        }
    }

    /**
     * @notice Add the market to the account's "assets in" for liquidity calculations
     * @param apeToken The market to enter
     * @param account The address of the account to modify
     */
    function addToMarketInternal(ApeToken apeToken, address account) internal {
        Market storage marketToJoin = markets[address(apeToken)];

        require(marketToJoin.isListed, "market not listed");

        if (marketToJoin.accountMembership[account] == true) {
            // already joined
            return;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        marketToJoin.accountMembership[account] = true;
        accountAssets[account].push(apeToken);

        emit MarketEntered(apeToken, account);
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing necessary collateral for an outstanding borrow.
     * @param apeTokenAddress The address of the asset to be removed
     */
    function exitMarket(address apeTokenAddress) external {
        ApeToken apeToken = ApeToken(apeTokenAddress);
        /* Get sender amountOwed underlying from the apeToken */
        (uint256 oErr, , uint256 amountOwed, ) = apeToken.getAccountSnapshot(msg.sender);
        require(oErr == 0, "exitMarket: getAccountSnapshot failed"); // semi-opaque error code

        /* Fail if the sender has a borrow or supply balance */
        require(amountOwed == 0, "nonzero borrow balance");
        require(apeToken.balanceOf(msg.sender) == 0, "nonzero supply balance");

        Market storage marketToExit = markets[apeTokenAddress];

        /* Return true if the sender is not already ‘in’ the market */
        if (!marketToExit.accountMembership[msg.sender]) {
            return;
        }

        /* Set apeToken account membership to false */
        delete marketToExit.accountMembership[msg.sender];

        /* Delete apeToken from the account’s list of assets */
        // load into memory for faster iteration
        ApeToken[] memory userAssetList = accountAssets[msg.sender];
        uint256 len = userAssetList.length;
        uint256 assetIndex = len;
        for (uint256 i = 0; i < len; i++) {
            if (userAssetList[i] == apeToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        ApeToken[] storage storedList = accountAssets[msg.sender];
        if (assetIndex != storedList.length - 1) {
            storedList[assetIndex] = storedList[storedList.length - 1];
        }
        storedList.length--;

        emit MarketExited(apeToken, msg.sender);
    }

    /**
     * @notice Return a specific market is listed or not
     * @param apeTokenAddress The address of the asset to be checked
     * @return Whether or not the market is listed
     */
    function isMarketListed(address apeTokenAddress) public view returns (bool) {
        return markets[apeTokenAddress].isListed;
    }

    /*** Policy Hooks ***/

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @param apeToken The market to verify the mint against
     * @param payer the account paying for the mint
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function mintAllowed(
        address apeToken,
        address payer,
        address minter,
        uint256 mintAmount
    ) external returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!mintGuardianPaused[apeToken], "mint is paused");
        require(!isCreditAccount(minter, apeToken), "credit account cannot mint");

        require(isMarketListed(apeToken), "market not listed");

        if (!markets[apeToken].accountMembership[minter]) {
            // only apeTokens may call mintAllowed if minter not in market
            require(msg.sender == apeToken, "sender must be apeToken");

            // add minter to the market
            addToMarketInternal(ApeToken(apeToken), minter);

            // it should be impossible to break the important invariant
            assert(markets[apeToken].accountMembership[minter]);
        }

        uint256 supplyCap = supplyCaps[apeToken];
        // Supply cap of 0 corresponds to unlimited supplying
        if (supplyCap != 0) {
            uint256 totalCash = ApeToken(apeToken).getCash();
            uint256 totalBorrows = ApeToken(apeToken).totalBorrows();
            uint256 totalReserves = ApeToken(apeToken).totalReserves();
            // totalSupplies = totalCash + totalBorrows - totalReserves
            (MathError mathErr, uint256 totalSupplies) = addThenSubUInt(totalCash, totalBorrows, totalReserves);
            require(mathErr == MathError.NO_ERROR, "totalSupplies failed");

            uint256 nextTotalSupplies = add_(totalSupplies, mintAmount);
            require(nextTotalSupplies < supplyCap, "market supply cap reached");
        }

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates mint and reverts on rejection. May emit logs.
     * @param apeToken Asset being minted
     * @param payer the account paying for the mint
     * @param minter The address minting the tokens
     * @param actualMintAmount The amount of the underlying asset being minted
     * @param mintTokens The number of tokens being minted
     */
    function mintVerify(
        address apeToken,
        address payer,
        address minter,
        uint256 actualMintAmount,
        uint256 mintTokens
    ) external {
        // Shh - currently unused
        apeToken;
        payer;
        minter;
        actualMintAmount;
        mintTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            closeFactorMantissa = closeFactorMantissa;
        }
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param apeToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of apeTokens to exchange for the underlying asset in the market
     * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function redeemAllowed(
        address apeToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256) {
        return redeemAllowedInternal(apeToken, redeemer, redeemTokens);
    }

    function redeemAllowedInternal(
        address apeToken,
        address redeemer,
        uint256 redeemTokens
    ) internal view returns (uint256) {
        require(isMarketListed(apeToken) || isMarkertDelisted[apeToken], "market not listed");
        require(!isCreditAccount(redeemer, apeToken), "credit account cannot redeem");

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!markets[apeToken].accountMembership[redeemer]) {
            return uint256(Error.NO_ERROR);
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (Error err, , uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
            redeemer,
            ApeToken(apeToken),
            redeemTokens,
            0
        );
        require(err == Error.NO_ERROR, "failed to get account liquidity");
        require(shortfall == 0, "insufficient liquidity");

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param apeToken Asset being redeemed
     * @param redeemer The address redeeming the tokens
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(
        address apeToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external {
        // Shh - currently unused
        apeToken;
        redeemer;

        // Require tokens is zero or amount is also zero
        if (redeemTokens == 0 && redeemAmount > 0) {
            revert("redeemTokens zero");
        }
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param apeToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function borrowAllowed(
        address apeToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!borrowGuardianPaused[apeToken], "borrow is paused");

        require(isMarketListed(apeToken), "market not listed");

        if (!markets[apeToken].accountMembership[borrower]) {
            // only apeTokens may call borrowAllowed if borrower not in market
            require(msg.sender == apeToken, "sender must be apeToken");

            // add borrower to the market
            addToMarketInternal(ApeToken(apeToken), borrower);

            // it should be impossible to break the important invariant
            assert(markets[apeToken].accountMembership[borrower]);
        }

        require(oracle.getUnderlyingPrice(ApeToken(apeToken)) != 0, "price error");

        uint256 borrowCap = borrowCaps[apeToken];
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint256 totalBorrows = ApeToken(apeToken).totalBorrows();
            uint256 nextTotalBorrows = add_(totalBorrows, borrowAmount);
            require(nextTotalBorrows < borrowCap, "market borrow cap reached");
        }

        uint256 creditLimit = creditLimits[borrower][apeToken];
        // If the borrower is a credit account, check the credit limit instead of account liquidity.
        if (creditLimit > 0) {
            (uint256 oErr, , uint256 borrowBalance, ) = ApeToken(apeToken).getAccountSnapshot(borrower);
            require(oErr == 0, "snapshot error");
            require(creditLimit >= add_(borrowBalance, borrowAmount), "insufficient credit limit");
        } else {
            (Error err, , uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
                borrower,
                ApeToken(apeToken),
                0,
                borrowAmount
            );
            require(err == Error.NO_ERROR, "failed to get account liquidity");
            require(shortfall == 0, "insufficient liquidity");
        }
        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates borrow and reverts on rejection. May emit logs.
     * @param apeToken Asset whose underlying is being borrowed
     * @param borrower The address borrowing the underlying
     * @param borrowAmount The amount of the underlying asset requested to borrow
     */
    function borrowVerify(
        address apeToken,
        address borrower,
        uint256 borrowAmount
    ) external {
        // Shh - currently unused
        apeToken;
        borrower;
        borrowAmount;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            closeFactorMantissa = closeFactorMantissa;
        }
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param apeToken The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which would borrowed the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function repayBorrowAllowed(
        address apeToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256) {
        // Shh - currently unused
        repayAmount;

        require(isMarketListed(apeToken) || isMarkertDelisted[apeToken], "market not listed");

        if (isCreditAccount(borrower, apeToken)) {
            require(borrower == payer, "cannot repay on behalf of credit account");
        }

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates repayBorrow and reverts on rejection. May emit logs.
     * @param apeToken Asset being repaid
     * @param payer The address repaying the borrow
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     */
    function repayBorrowVerify(
        address apeToken,
        address payer,
        address borrower,
        uint256 actualRepayAmount,
        uint256 borrowerIndex
    ) external {
        // Shh - currently unused
        apeToken;
        payer;
        borrower;
        actualRepayAmount;
        borrowerIndex;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            closeFactorMantissa = closeFactorMantissa;
        }
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param apeTokenBorrowed Asset which was borrowed by the borrower
     * @param apeTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     */
    function liquidateBorrowAllowed(
        address apeTokenBorrowed,
        address apeTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256) {
        require(!isCreditAccount(borrower, apeTokenBorrowed), "cannot liquidate credit account");

        // Shh - currently unused
        liquidator;

        require(isMarketListed(apeTokenBorrowed) && isMarketListed(apeTokenCollateral), "market not listed");

        /* The borrower must have shortfall in order to be liquidatable */
        (Error err, , uint256 shortfall) = getAccountLiquidityInternal(borrower);
        require(err == Error.NO_ERROR, "failed to get account liquidity");
        require(shortfall > 0, "insufficient shortfall");

        /* The liquidator may not repay more than what is allowed by the closeFactor */
        uint256 borrowBalance = ApeToken(apeTokenBorrowed).borrowBalanceStored(borrower);
        uint256 maxClose = mul_ScalarTruncate(Exp({mantissa: closeFactorMantissa}), borrowBalance);
        if (repayAmount > maxClose) {
            return uint256(Error.TOO_MUCH_REPAY);
        }

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates liquidateBorrow and reverts on rejection. May emit logs.
     * @param apeTokenBorrowed Asset which was borrowed by the borrower
     * @param apeTokenCollateral Asset which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     */
    function liquidateBorrowVerify(
        address apeTokenBorrowed,
        address apeTokenCollateral,
        address liquidator,
        address borrower,
        uint256 actualRepayAmount,
        uint256 seizeTokens
    ) external {
        // Shh - currently unused
        apeTokenBorrowed;
        apeTokenCollateral;
        liquidator;
        borrower;
        actualRepayAmount;
        seizeTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            closeFactorMantissa = closeFactorMantissa;
        }
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param apeTokenCollateral Asset which was used as collateral and will be seized
     * @param apeTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeAllowed(
        address apeTokenCollateral,
        address apeTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256) {
        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused, "seize is paused");
        require(!isCreditAccount(borrower, apeTokenBorrowed), "cannot sieze from credit account");

        // Shh - currently unused
        liquidator;
        seizeTokens;

        require(isMarketListed(apeTokenBorrowed) && isMarketListed(apeTokenCollateral), "market not listed");
        require(
            ApeToken(apeTokenCollateral).comptroller() == ApeToken(apeTokenBorrowed).comptroller(),
            "comptroller mismatched"
        );

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Validates seize and reverts on rejection. May emit logs.
     * @param apeTokenCollateral Asset which was used as collateral and will be seized
     * @param apeTokenBorrowed Asset which was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeVerify(
        address apeTokenCollateral,
        address apeTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external {
        // Shh - currently unused
        apeTokenCollateral;
        apeTokenBorrowed;
        liquidator;
        borrower;
        seizeTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            closeFactorMantissa = closeFactorMantissa;
        }
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param apeToken The market to verify the transfer against
     * @param receiver The account which receives the tokens
     * @param amount The amount of the tokens
     * @param params The other parameters
     */

    function flashloanAllowed(
        address apeToken,
        address receiver,
        uint256 amount,
        bytes calldata params
    ) external view returns (bool) {
        return !flashloanGuardianPaused[apeToken];
    }

    /**
     * @notice Check if the account is a credit account
     * @param account The account needs to be checked
     * @param apeToken The market
     * @return The account is a credit account or not
     */
    function isCreditAccount(address account, address apeToken) public view returns (bool) {
        return creditLimits[account][apeToken] > 0;
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `apeTokenBalance` is the number of apeTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint256 sumCollateral;
        uint256 sumBorrowPlusEffects;
        uint256 apeTokenBalance;
        uint256 borrowBalance;
        uint256 exchangeRateMantissa;
        uint256 oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidity(address account)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (Error err, uint256 liquidity, uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
            account,
            ApeToken(0),
            0,
            0
        );

        return (uint256(err), liquidity, shortfall);
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @return (possible error code,
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidityInternal(address account)
        internal
        view
        returns (
            Error,
            uint256,
            uint256
        )
    {
        return getHypotheticalAccountLiquidityInternal(account, ApeToken(0), 0, 0);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param apeTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        address apeTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        (Error err, uint256 liquidity, uint256 shortfall) = getHypotheticalAccountLiquidityInternal(
            account,
            ApeToken(apeTokenModify),
            redeemTokens,
            borrowAmount
        );
        return (uint256(err), liquidity, shortfall);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param apeTokenModify The market to hypothetically redeem/borrow in
     * @param account The account to determine liquidity for
     * @param redeemTokens The number of tokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral apeToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        ApeToken apeTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    )
        internal
        view
        returns (
            Error,
            uint256,
            uint256
        )
    {
        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint256 oErr;

        // For each asset the account is in
        ApeToken[] memory assets = accountAssets[account];
        for (uint256 i = 0; i < assets.length; i++) {
            ApeToken asset = assets[i];

            // Read the balances and exchange rate from the apeToken
            (oErr, vars.apeTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = asset.getAccountSnapshot(
                account
            );
            require(oErr == 0, "snapshot error");

            // Unlike compound protocol, getUnderlyingPrice is relatively expensive because we use ChainLink as our primary price feed.
            // If user has no supply / borrow balance on this asset, and user is not redeeming / borrowing this asset, skip it.
            if (vars.apeTokenBalance == 0 && vars.borrowBalance == 0 && asset != apeTokenModify) {
                continue;
            }

            vars.collateralFactor = Exp({mantissa: markets[address(asset)].collateralFactorMantissa});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = oracle.getUnderlyingPrice(asset);
            require(vars.oraclePriceMantissa > 0, "price error");
            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

            // sumCollateral += tokensToDenom * apeTokenBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(
                vars.tokensToDenom,
                vars.apeTokenBalance,
                vars.sumCollateral
            );

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(
                vars.oraclePrice,
                vars.borrowBalance,
                vars.sumBorrowPlusEffects
            );

            // Calculate effects of interacting with apeTokenModify
            if (asset == apeTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(
                    vars.tokensToDenom,
                    redeemTokens,
                    vars.sumBorrowPlusEffects
                );

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(
                    vars.oraclePrice,
                    borrowAmount,
                    vars.sumBorrowPlusEffects
                );
            }
        }

        // These are safe, as the underflow condition is checked first
        if (vars.sumCollateral > vars.sumBorrowPlusEffects) {
            return (Error.NO_ERROR, vars.sumCollateral - vars.sumBorrowPlusEffects, 0);
        } else {
            return (Error.NO_ERROR, 0, vars.sumBorrowPlusEffects - vars.sumCollateral);
        }
    }

    /**
     * @notice Calculate number of tokens of collateral asset to seize given an underlying amount
     * @dev Used in liquidation (called in apeToken.liquidateBorrowFresh)
     * @param apeTokenBorrowed The address of the borrowed apeToken
     * @param apeTokenCollateral The address of the collateral apeToken
     * @param actualRepayAmount The amount of apeTokenBorrowed underlying to convert into apeTokenCollateral tokens
     * @return (number of apeTokenCollateral tokens to be seized in a liquidation, fee tokens)
     */
    function liquidateCalculateSeizeTokens(
        address apeTokenBorrowed,
        address apeTokenCollateral,
        uint256 actualRepayAmount
    ) external view returns (uint256, uint256) {
        /* Read oracle prices for borrowed and collateral markets */
        uint256 priceBorrowedMantissa = oracle.getUnderlyingPrice(ApeToken(apeTokenBorrowed));
        uint256 priceCollateralMantissa = oracle.getUnderlyingPrice(ApeToken(apeTokenCollateral));
        require(priceBorrowedMantissa > 0 && priceCollateralMantissa > 0, "price error");

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        uint256 exchangeRateMantissa = ApeToken(apeTokenCollateral).exchangeRateStored(); // Note: reverts on error
        Exp memory denominator = mul_(Exp({mantissa: priceCollateralMantissa}), Exp({mantissa: exchangeRateMantissa}));
        Exp memory ratio = div_(Exp({mantissa: priceBorrowedMantissa}), denominator);
        uint256 base = mul_(actualRepayAmount, ratio);
        uint256 seizeTokens = mul_ScalarTruncate(Exp({mantissa: base}), liquidationIncentiveMantissa);

        // We take half of the liquidation incentive as fee
        uint256 feeRatio = div_(sub_(liquidationIncentiveMantissa, mantissaOne), 2);
        uint256 feeTokens = mul_ScalarTruncate(Exp({mantissa: base}), feeRatio);

        return (seizeTokens, feeTokens);
    }

    /*** Admin Functions ***/

    /**
     * @notice Sets a new price oracle for the comptroller
     * @dev Admin function to set a new price oracle
     * @return uint 0=success, otherwise a failure (see ErrorReporter.sol for details)
     */
    function _setPriceOracle(PriceOracle newOracle) public returns (uint256) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PRICE_ORACLE_OWNER_CHECK);
        }

        // Track the old oracle for the comptroller
        PriceOracle oldOracle = oracle;

        // Set comptroller's oracle to newOracle
        oracle = newOracle;

        // Emit NewPriceOracle(oldOracle, newOracle)
        emit NewPriceOracle(oldOracle, newOracle);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets the closeFactor used when liquidating borrows
     * @dev Admin function to set closeFactor
     * @param newCloseFactorMantissa New close factor, scaled by 1e18
     * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
     */
    function _setCloseFactor(uint256 newCloseFactorMantissa) external returns (uint256) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_CLOSE_FACTOR_OWNER_CHECK);
        }

        uint256 oldCloseFactorMantissa = closeFactorMantissa;
        closeFactorMantissa = newCloseFactorMantissa;
        emit NewCloseFactor(oldCloseFactorMantissa, closeFactorMantissa);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets the collateralFactor for a market
     * @dev Admin function to set per-market collateralFactor
     * @param apeToken The market to set the factor on
     * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
     * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
     */
    function _setCollateralFactor(ApeToken apeToken, uint256 newCollateralFactorMantissa) external returns (uint256) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK);
        }

        // Verify market is listed
        Market storage market = markets[address(apeToken)];
        if (!market.isListed) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS);
        }

        Exp memory newCollateralFactorExp = Exp({mantissa: newCollateralFactorMantissa});

        // Check collateral factor <= 0.9
        Exp memory highLimit = Exp({mantissa: collateralFactorMaxMantissa});
        if (lessThanExp(highLimit, newCollateralFactorExp)) {
            return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
        }

        // If collateral factor != 0, fail if price == 0
        if (newCollateralFactorMantissa != 0 && oracle.getUnderlyingPrice(apeToken) == 0) {
            return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint256 oldCollateralFactorMantissa = market.collateralFactorMantissa;
        market.collateralFactorMantissa = newCollateralFactorMantissa;

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(apeToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Sets liquidationIncentive
     * @dev Admin function to set liquidationIncentive
     * @param newLiquidationIncentiveMantissa New liquidationIncentive scaled by 1e18
     * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
     */
    function _setLiquidationIncentive(uint256 newLiquidationIncentiveMantissa) external returns (uint256) {
        // Check caller is admin
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_LIQUIDATION_INCENTIVE_OWNER_CHECK);
        }

        // Save current value for use in log
        uint256 oldLiquidationIncentiveMantissa = liquidationIncentiveMantissa;

        // Set liquidation incentive to new incentive
        liquidationIncentiveMantissa = newLiquidationIncentiveMantissa;

        // Emit event with old incentive, new incentive
        emit NewLiquidationIncentive(oldLiquidationIncentiveMantissa, newLiquidationIncentiveMantissa);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Add the market to the markets mapping and set it as listed
     * @dev Admin function to set isListed and add support for the market
     * @param apeToken The address of the market (token) to list
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _supportMarket(ApeToken apeToken) external returns (uint256) {
        require(msg.sender == admin, "admin only");
        require(!isMarketListed(address(apeToken)), "market already listed");
        require(!isMarkertDelisted[address(apeToken)], "market has been delisted");

        apeToken.isApeToken(); // Sanity check to make sure its really a ApeToken

        markets[address(apeToken)] = Market({isListed: true, collateralFactorMantissa: 0});

        _addMarketInternal(address(apeToken));

        emit MarketListed(apeToken);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Remove the market from the markets mapping
     * @param apeToken The address of the market (token) to delist
     */
    function _delistMarket(ApeToken apeToken) external {
        require(msg.sender == admin, "admin only");
        require(isMarketListed(address(apeToken)), "market not listed");
        require(markets[address(apeToken)].collateralFactorMantissa == 0, "market has collateral");

        apeToken.isApeToken(); // Sanity check to make sure its really a ApeToken

        isMarkertDelisted[address(apeToken)] = true;
        delete markets[address(apeToken)];

        for (uint256 i = 0; i < allMarkets.length; i++) {
            if (allMarkets[i] == apeToken) {
                allMarkets[i] = allMarkets[allMarkets.length - 1];
                delete allMarkets[allMarkets.length - 1];
                allMarkets.length--;
                break;
            }
        }

        emit MarketDelisted(apeToken);
    }

    function _addMarketInternal(address apeToken) internal {
        for (uint256 i = 0; i < allMarkets.length; i++) {
            require(allMarkets[i] != ApeToken(apeToken), "market already added");
        }
        allMarkets.push(ApeToken(apeToken));
    }

    /**
     * @notice Set the given supply caps for the given apeToken markets. Supplying that brings total supplys to or above supply cap will revert.
     * @dev Admin or pauseGuardian function to set the supply caps. A supply cap of 0 corresponds to unlimited supplying. If the total borrows
     *      already exceeded the cap, it will prevent anyone to borrow.
     * @param apeTokens The addresses of the markets (tokens) to change the supply caps for
     * @param newSupplyCaps The new supply cap values in underlying to be set. A value of 0 corresponds to unlimited supplying.
     */
    function _setMarketSupplyCaps(ApeToken[] calldata apeTokens, uint256[] calldata newSupplyCaps) external {
        require(msg.sender == admin || msg.sender == pauseGuardian, "admin or guardian only");

        uint256 numMarkets = apeTokens.length;
        uint256 numSupplyCaps = newSupplyCaps.length;

        require(numMarkets != 0 && numMarkets == numSupplyCaps, "invalid input");

        for (uint256 i = 0; i < numMarkets; i++) {
            supplyCaps[address(apeTokens[i])] = newSupplyCaps[i];
            emit NewSupplyCap(apeTokens[i], newSupplyCaps[i]);
        }
    }

    /**
     * @notice Set the given borrow caps for the given apeToken markets. Borrowing that brings total borrows to or above borrow cap will revert.
     * @dev Admin or pauseGuardian function to set the borrow caps. A borrow cap of 0 corresponds to unlimited borrowing. If the total supplies
     *      already exceeded the cap, it will prevent anyone to mint.
     * @param apeTokens The addresses of the markets (tokens) to change the borrow caps for
     * @param newBorrowCaps The new borrow cap values in underlying to be set. A value of 0 corresponds to unlimited borrowing.
     */
    function _setMarketBorrowCaps(ApeToken[] calldata apeTokens, uint256[] calldata newBorrowCaps) external {
        require(msg.sender == admin || msg.sender == pauseGuardian, "admin or guardian only");

        uint256 numMarkets = apeTokens.length;
        uint256 numBorrowCaps = newBorrowCaps.length;

        require(numMarkets != 0 && numMarkets == numBorrowCaps, "invalid input");

        for (uint256 i = 0; i < numMarkets; i++) {
            borrowCaps[address(apeTokens[i])] = newBorrowCaps[i];
            emit NewBorrowCap(apeTokens[i], newBorrowCaps[i]);
        }
    }

    /**
     * @notice Admin function to change the Pause Guardian
     * @param newPauseGuardian The address of the new Pause Guardian
     * @return uint 0=success, otherwise a failure. (See enum Error for details)
     */
    function _setPauseGuardian(address newPauseGuardian) public returns (uint256) {
        if (msg.sender != admin) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_PAUSE_GUARDIAN_OWNER_CHECK);
        }

        // Save current value for inclusion in log
        address oldPauseGuardian = pauseGuardian;

        // Store pauseGuardian with value newPauseGuardian
        pauseGuardian = newPauseGuardian;

        // Emit NewPauseGuardian(OldPauseGuardian, NewPauseGuardian)
        emit NewPauseGuardian(oldPauseGuardian, pauseGuardian);

        return uint256(Error.NO_ERROR);
    }

    /**
     * @notice Admin function to set the liquidity mining module address
     * @dev Removing the liquidity mining module address could cause the inconsistency in the LM module.
     * @param newLiquidityMining The address of the new liquidity mining module
     */
    function _setLiquidityMining(address newLiquidityMining) external {
        require(msg.sender == admin, "admin only");
        require(LiquidityMiningInterface(newLiquidityMining).comptroller() == address(this), "mismatch comptroller");

        // Save current value for inclusion in log
        address oldLiquidityMining = liquidityMining;

        // Store liquidityMining with value newLiquidityMining
        liquidityMining = newLiquidityMining;

        // Emit NewLiquidityMining(OldLiquidityMining, NewLiquidityMining)
        emit NewLiquidityMining(oldLiquidityMining, liquidityMining);
    }

    /**
     * @notice Admin function to set the credit limit manager address
     * @param newCreditLimitManager The address of the new credit limit manager
     */
    function _setCreditLimitManager(address newCreditLimitManager) external {
        require(msg.sender == admin, "admin only");

        // Save current value for inclusion in log
        address oldCreditLimitManager = creditLimitManager;

        // Store creditLimitManager with value newCreditLimitManager
        creditLimitManager = newCreditLimitManager;

        // Emit NewCreditLimitManager(oldCreditLimitManager, newCreditLimitManager)
        emit NewCreditLimitManager(oldCreditLimitManager, creditLimitManager);
    }

    function _setMintPaused(ApeToken apeToken, bool state) public returns (bool) {
        require(isMarketListed(address(apeToken)), "market not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "guardian or admin only");
        require(msg.sender == admin || state == true, "admin only");

        mintGuardianPaused[address(apeToken)] = state;
        emit ActionPaused(apeToken, "Mint", state);
        return state;
    }

    function _setBorrowPaused(ApeToken apeToken, bool state) public returns (bool) {
        require(isMarketListed(address(apeToken)), "market not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "guardian or admin only");
        require(msg.sender == admin || state == true, "admin only");

        borrowGuardianPaused[address(apeToken)] = state;
        emit ActionPaused(apeToken, "Borrow", state);
        return state;
    }

    function _setFlashloanPaused(ApeToken apeToken, bool state) public returns (bool) {
        require(isMarketListed(address(apeToken)), "market not listed");
        require(msg.sender == pauseGuardian || msg.sender == admin, "guardian or admin only");
        require(msg.sender == admin || state == true, "admin only");

        flashloanGuardianPaused[address(apeToken)] = state;
        emit ActionPaused(apeToken, "Flashloan", state);
        return state;
    }

    function _setSeizePaused(bool state) public returns (bool) {
        require(msg.sender == pauseGuardian || msg.sender == admin, "guardian or admin only");
        require(msg.sender == admin || state == true, "admin only");

        seizeGuardianPaused = state;
        emit ActionPaused("Seize", state);
        return state;
    }

    function _become(Unitroller unitroller) public {
        require(msg.sender == unitroller.admin(), "unitroller admin only");
        require(unitroller._acceptImplementation() == 0, "unauthorized");
    }

    /**
     * @notice Sets protocol's credit limit by market
     * @param protocol The address of the protocol
     * @param market The market
     * @param creditLimit The credit limit
     */
    function _setCreditLimit(
        address protocol,
        address market,
        uint256 creditLimit
    ) public {
        require(
            msg.sender == admin || msg.sender == creditLimitManager || msg.sender == pauseGuardian,
            "admin or credit limit manager or pause guardian only"
        );
        require(isMarketListed(market), "market not listed");

        if (creditLimits[protocol][market] == 0 && creditLimit != 0) {
            // Only admin or credit limit manager could set a new credit limit.
            require(msg.sender == admin || msg.sender == creditLimitManager, "admin or credit limit manager only");
        }

        creditLimits[protocol][market] = creditLimit;
        emit CreditLimitChanged(protocol, market, creditLimit);
    }

    /**
     * @notice Return all of the markets
     * @dev The automatic getter may be used to access an individual market.
     * @return The list of market addresses
     */
    function getAllMarkets() public view returns (ApeToken[] memory) {
        return allMarkets;
    }

    function getBlockNumber() public view returns (uint256) {
        return block.number;
    }
}