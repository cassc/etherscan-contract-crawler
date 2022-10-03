pragma solidity ^0.5.16;

import "./PriceOracle.sol";
import "./MtrollerInterface.sol";
import "./MtrollerCommon.sol";
import "./MTokenInterfaces.sol";
import "./Mmo.sol";
import "./ErrorReporter.sol";
import "./compound/ExponentialNoError.sol";

/**
 * @title Based on Compound's Mtroller Contract, with some modifications
 * @dev This contract must not declare any variables. All required storage must be inherited from MtrollerCommon
 * @author Compound, mmo.finance
 */
contract MtrollerUser is MtrollerCommon, MtrollerUserInterface {

    /**
     * @notice Constructs a new MtrollerUser
     */
    constructor() public MtrollerCommon() {
    }

    /**
     * @notice Returns the type of implementation for this contract
     */
    function isMDelegatorUserImplementation() public pure returns (bool) {
        return true;
    }

    /*** Assets You Are In ***/

    /**
     * @notice Returns the assets an account has entered
     * @param account The address of the account to pull assets for
     * @return A dynamic list with the assets the account has entered
     */
    function getAssetsIn(address account) external view returns (uint240[] memory) {
        uint240[] memory assetsIn = accountAssets[account];
        return assetsIn;
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param mToken The mToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function checkMembership(address account, uint240 mToken) external view returns (bool) {
        return accountMembership(mToken, account);
    }

    /**
     * @notice Returns whether the given account is entered in the given asset
     * @param account The address of the account to check
     * @param mToken The mToken to check
     * @return True if the account is in the asset, otherwise false.
     */
    function accountMembership(uint240 mToken, address account) internal view returns (bool) {
        return markets[mToken]._accountMembership[account];
    }

    /**
     * @notice Add assets to be included in account liquidity calculation
     * @param mTokens The list of mToken markets to be enabled
     * @return Success indicator for whether each corresponding market was entered (0 = success, 
     * otherwise error code)
     */
    function enterMarkets(uint240[] memory mTokens) public returns (uint[] memory) {
        uint len = mTokens.length;

        uint[] memory results = new uint[](len);
        for (uint i = 0; i < len; i++) {
            results[i] = uint(addToMarketInternal(mTokens[i], msg.sender));
        }

        return results;
    }

    /**
     * @notice Allows the mToken contract to enter the market on a user's behalf
     * @param mToken The mToken market to be entered
     * @param owner The mToken owner on whose behalf the market should be entered
     * @return Success indicator for whether the market was entered
     */
    function enterMarketOnBehalf(uint240 mToken, address owner) external returns (uint) {
        ( , , address mTokenAddress) = parseToken(mToken);
        require(msg.sender == mTokenAddress, "Only mToken contract can do this, only for own mToken");
        return uint(addToMarketInternal(mToken, owner));
    }

    /**
     * @notice Add the mToken market to the borrower's "assets in" for liquidity calculations
     * @param mToken The market to enter
     * @param borrower The address of the account to modify
     * @return Success indicator for whether the market was entered
     */
    function addToMarketInternal(uint240 mToken, address borrower) internal returns (Error) {
        if (!isListed(mToken)) {
            // market is not listed, cannot join
            return Error.MARKET_NOT_LISTED;
        }

        if (accountMembership(mToken, borrower) == true) {
            // already joined
            return Error.NO_ERROR;
        }

        if (accountAssets[borrower].length >= maxAssets) {
            // no more assets allowed in the market for that borrower
            return Error.TOO_MANY_ASSETS;
        }

        // survived the gauntlet, add to list
        // NOTE: we store these somewhat redundantly as a significant optimization
        //  this avoids having to iterate through the list for the most common use cases
        //  that is, only when we need to perform liquidity checks
        //  and not whenever we want to check if an account is in a particular market
        markets[mToken]._accountMembership[borrower] = true;
        accountAssets[borrower].push(mToken);

        emit MarketEntered(mToken, borrower);

        return Error.NO_ERROR;
    }

    /**
     * @notice Removes asset from sender's account liquidity calculation
     * @dev Sender must not have an outstanding borrow balance in the asset,
     *  or be providing necessary collateral for an outstanding borrow.
     * @param mToken The asset to be removed
     * @return Whether or not the account successfully exited the market
     */
    function exitMarket(uint240 mToken) external returns (uint) {
        return exitMarketInternal(mToken, msg.sender);
    }

    /**
     * @notice Allows the mToken contract to exit the market on a user's behalf
     * @param mToken The mToken market to be exited
     * @param owner The mToken owner on whose behalf the market should be exited
     * @return Success indicator for whether the market was exited
     */
    function exitMarketOnBehalf(uint240 mToken, address owner) external returns (uint) {
        ( , , address mTokenAddress) = parseToken(mToken);
        require(msg.sender == mTokenAddress, "Only token contract can do this, only for own token");
        return uint(exitMarketInternal(mToken, owner));
    }

    function exitMarketInternal(uint240 mToken, address borrower) internal returns (uint) {
        /* Fail if mToken not listed */
        if (!isListed(mToken)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* Get sender tokensHeld and amountOwed underlying from the mToken */
        ( , , address mTokenAddress) = parseToken(mToken);
        (uint oErr, uint tokensHeld, uint amountOwed, ) = MTokenInterface(mTokenAddress).getAccountSnapshot(borrower, mToken);
        require(oErr == 0, "exitMarket: getAccountSnapshot failed"); // semi-opaque error code

        /* Fail if the sender has a borrow balance */
        if (amountOwed != 0) {
            return fail(Error.NONZERO_BORROW_BALANCE, FailureInfo.EXIT_MARKET_BALANCE_OWED);
        }

        /* If the borrower still holds tokens in that market they have to be all redeemable */
        if (tokensHeld != 0) {
            /* Fail if the sender is not permitted to redeem all of their tokens */
            uint allowed = redeemAllowedInternal(mToken, borrower, tokensHeld);
            if (allowed != 0) {
                return failOpaque(Error.REJECTION, FailureInfo.EXIT_MARKET_REJECTION, allowed);
            }
        }

        /* Return true if the sender is not already ‘in’ the market */
        if (!accountMembership(mToken, borrower)) {
            return uint(Error.NO_ERROR);
        }

        /* Set mToken account membership to false */
        delete markets[mToken]._accountMembership[borrower];

        /* Delete mToken from the account’s list of assets */
        // load into memory for faster iteration
        uint240[] memory userAssetList = accountAssets[borrower];
        uint len = userAssetList.length;
        uint assetIndex = len;
        for (uint i = 0; i < len; i++) {
            if (userAssetList[i] == mToken) {
                assetIndex = i;
                break;
            }
        }

        // We *must* have found the asset in the list or our redundant data structure is broken
        assert(assetIndex < len);

        // copy last item in list to location of item to be removed, reduce length by 1
        uint240[] storage storedList = accountAssets[borrower];
        storedList[assetIndex] = storedList[storedList.length - 1];
        storedList.length--;

        emit MarketExited(mToken, borrower);

        return uint(Error.NO_ERROR);
    }

    /**
      * @notice Sets the collateralFactor for a mToken market
      * @dev Admin function to set per-market collateralFactor
      * @param mToken The mToken to set the factor on
      * @param newCollateralFactorMantissa The new collateral factor, scaled by 1e18
      * @return uint 0=success, otherwise a failure. (See ErrorReporter for details)
      */
    function _setCollateralFactor(uint240 mToken, uint newCollateralFactorMantissa) external returns (uint) {
        // Check caller is admin
        if (msg.sender != getAdmin()) {
            return fail(Error.UNAUTHORIZED, FailureInfo.SET_COLLATERAL_FACTOR_OWNER_CHECK);
        }
        return _setCollateralFactorInternal(mToken, newCollateralFactorMantissa);
    }

    function _setCollateralFactorInternal(uint240 mToken, uint newCollateralFactorMantissa) internal returns (uint) {
        // Verify market is listed
        if (!isListed(mToken)) {
            return fail(Error.MARKET_NOT_LISTED, FailureInfo.SET_COLLATERAL_FACTOR_NO_EXISTS);
        }

        // Checks in case of individual collateral factor (i.e., for sub-markets)
        if (mToken != getAnchorToken(mToken)) {
            // fail if price == 0
            if (getPrice(mToken) == 0) {
                return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
            }

            // Checks that new individual collateral factor <= collateralFactorMaxMantissa
            if (newCollateralFactorMantissa > collateralFactorMaxMantissa) {
                return fail(Error.INVALID_COLLATERAL_FACTOR, FailureInfo.SET_COLLATERAL_FACTOR_VALIDATION);
            }
        }

        // Set market's collateral factor to new collateral factor, remember old value
        uint oldCollateralFactorMantissa = markets[mToken]._collateralFactorMantissa;
        markets[mToken]._collateralFactorMantissa = newCollateralFactorMantissa;

        // Checks that total (=combined) collateral factor is in range, otherwise reverts
        collateralFactorMantissa(mToken);

        // Emit event with asset, old collateral factor, and new collateral factor
        emit NewCollateralFactor(mToken, oldCollateralFactorMantissa, newCollateralFactorMantissa);

        return uint(Error.NO_ERROR);
    }

    /*** Policy Hooks ***/

    /**
     * @notice Checks if the given market is allowed for auctions
     * @param mToken The market for which to allow auctions
     * @param bidder The address wanting to use the auction
     * @return 0 if auctions are allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function auctionAllowed(uint240 mToken, address bidder) public returns (uint) {

        (MTokenType mTokenType, , address tokenAddress) = parseToken(mToken);

        // Pausing is a very serious situation - we revert to sound the alarms
        require(!auctionGuardianPaused[getAnchorToken(mToken)], "auction is paused");
        require(!auctionGuardianPaused[mToken], "auction is paused");

        if (!isListed(mToken)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Fail for fungible tokens
        if (mTokenType != MTokenType.ERC721_MTOKEN) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Fail for non-existing (e.g. already redeemed) tokens
        if (MERC721Interface(tokenAddress).ownerOf(mToken) == address(0)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        updateMmoSupplyIndex(mToken);
        distributeSupplierMmo(mToken, bidder);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Checks if the account should be allowed to mint tokens in the given market
     * @dev Also, if the anchor market of the mToken is listed, this automatically lists the mToken. 
     * To avoid rogue mTokens being listed this can only be called by the mToken's own contract.
     * @param mToken The market to verify the mint against
     * @param minter The account which would get the minted tokens
     * @param mintAmount The amount of underlying being supplied to the market in exchange for tokens
     * @return 0 if the mint is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function mintAllowed(uint240 mToken, address minter, uint mintAmount) external returns (uint) {
        // Shh - currently unused
        minter;
        mintAmount;

        // only allow calls from own mToken contract (to avoid listing of rogue mTokens)
        ( , uint72 mTokenSeqNr, address mTokenAddress) = parseToken(mToken);
        require(mTokenSeqNr <= MTokenCommon(mTokenAddress).totalCreatedMarkets(), "invalid mToken SeqNr");
        require(msg.sender == mTokenAddress, "only mToken can call this");

        // Pausing is a very serious situation - we revert to sound the alarms
        uint240 mTokenAnchor = getAnchorToken(mToken);
        require(!mintGuardianPaused[mTokenAnchor], "mint is paused");
        require(!mintGuardianPaused[mToken], "mint is paused");

        // Require anchor token to be listed already
        if (!isListed(mTokenAnchor)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        if (!isListed(mToken)) {
            // support new (sub-)market (collateral factor of the anchor token is used by default)
            uint err = _supportMarketInternal(mToken);
            if (err != uint(Error.NO_ERROR)) {
                return err;
            }
            // fail if price == 0
            if (getPrice(mToken) == 0) {
                return fail(Error.PRICE_ERROR, FailureInfo.SET_COLLATERAL_FACTOR_WITHOUT_PRICE);
            }
        }

        // Keep the flywheel moving
        updateMmoSupplyIndex(mToken);
        distributeSupplierMmo(mToken, minter);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates mint and reverts on rejection. May emit logs.
     * @param mToken Asset being minted
     * @param minter The address minting the tokens
     * @param actualMintAmount The amount of the underlying asset being minted
     * @param mintTokens The number of tokens being minted
     */
    function mintVerify(uint240 mToken, address minter, uint actualMintAmount, uint mintTokens) external {
        // Shh - currently unused
        mToken;
        minter;
        actualMintAmount;
        mintTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to redeem tokens in the given market
     * @param mToken The market to verify the redeem against
     * @param redeemer The account which would redeem the tokens
     * @param redeemTokens The number of mTokens to exchange for the underlying asset in the market
     * @return 0 if the redeem is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function redeemAllowed(uint240 mToken, address redeemer, uint redeemTokens) external returns (uint) {

        uint allowed = redeemAllowedInternal(mToken, redeemer, redeemTokens);

        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updateMmoSupplyIndex(mToken);
        distributeSupplierMmo(mToken, redeemer);

        return uint(Error.NO_ERROR);
    }

    function redeemAllowedInternal(uint240 mToken, address redeemer, uint redeemTokens) internal view returns (uint) {
        if (!isListed(mToken)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* If the redeemer is not 'in' the market, then we can bypass the liquidity check */
        if (!accountMembership(mToken, redeemer)) {
            return uint(Error.NO_ERROR);
        }

        /* Otherwise, perform a hypothetical liquidity check to guard against shortfall */
        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(redeemer, mToken, redeemTokens, 0);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates redeem and reverts on rejection. May emit logs.
     * @param mToken Asset being redeemed
     * @param redeemer The address redeeming the tokens
     * @param redeemAmount The amount of the underlying asset being redeemed
     * @param redeemTokens The number of tokens being redeemed
     */
    function redeemVerify(uint240 mToken, address redeemer, uint redeemAmount, uint redeemTokens) external {
        // Shh - currently unused
        mToken;
        redeemer;

        // If redeemTokens is zero, require aldo redeemAmount to be zero
        if (redeemTokens == 0 && redeemAmount > 0) {
            revert("redeemTokens zero");
        }
    }

    /**
     * @notice Checks if the account should be allowed to borrow the underlying asset of the given market
     * @param mToken The market to verify the borrow against
     * @param borrower The account which would borrow the asset
     * @param borrowAmount The amount of underlying the account would borrow
     * @return 0 if the borrow is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function borrowAllowed(uint240 mToken, address borrower, uint borrowAmount) external returns (uint) {

        ( , , address mTokenAddress) = parseToken(mToken);

        // Pausing is a very serious situation - we revert to sound the alarms
        require(!borrowGuardianPaused[getAnchorToken(mToken)], "borrow is paused");
        require(!borrowGuardianPaused[mToken], "borrow is paused");

        if (!isListed(mToken)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // This should never occur since borrow() should call enterMarketOnBehalf() first
        if (!accountMembership(mToken, borrower)) {
            return uint(Error.MARKET_NOT_ENTERED);
        }

        if (getPrice(mToken) == 0) {
            return uint(Error.PRICE_ERROR);
        }

        // Borrow cap is the minimum of the global cap of the mToken and the cap of the sub-market (if any)
        uint borrowCap = borrowCaps[getAnchorToken(mToken)];
        uint borrowCapSubmarket = borrowCaps[mToken];
        if (borrowCap == 0 || (borrowCapSubmarket != 0 && borrowCapSubmarket < borrowCap)) {
            borrowCap = borrowCapSubmarket;
        }
        // Borrow cap of 0 corresponds to unlimited borrowing
        if (borrowCap != 0) {
            uint totalBorrows = MTokenCommon(mTokenAddress).totalBorrows(mToken);
            uint nextTotalBorrows = add_(totalBorrows, borrowAmount);
            require(nextTotalBorrows < borrowCap, "market borrow cap reached");
        }

        (Error err, , uint shortfall) = getHypotheticalAccountLiquidityInternal(borrower, mToken, 0, borrowAmount);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall > 0) {
            return uint(Error.INSUFFICIENT_LIQUIDITY);
        }

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: MTokenCommon(mTokenAddress).borrowIndex(mToken)});
        updateMmoBorrowIndex(mToken, borrowIndex);
        distributeBorrowerMmo(mToken, borrower, borrowIndex);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates borrow and reverts on rejection. May emit logs.
     * @param mToken Asset whose underlying is being borrowed
     * @param borrower The address borrowing the underlying
     * @param borrowAmount The amount of the underlying asset requested to borrow
     */
    function borrowVerify(uint240 mToken, address borrower, uint borrowAmount) external {
        // Shh - currently unused
        mToken;
        borrower;
        borrowAmount;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to repay a borrow in the given market
     * @param mToken The market to verify the repay against
     * @param payer The account which would repay the asset
     * @param borrower The account which would borrowed the asset
     * @param repayAmount The amount of the underlying asset the account would repay
     * @return 0 if the repay is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function repayBorrowAllowed(uint240 mToken, address payer, address borrower, uint repayAmount) external returns (uint) {
        // Shh - currently unused
        payer;
        borrower;
        repayAmount;

        ( , , address mTokenAddress) = parseToken(mToken);

        if (!isListed(mToken)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        // Keep the flywheel moving
        Exp memory borrowIndex = Exp({mantissa: MTokenCommon(mTokenAddress).borrowIndex(mToken)});
        updateMmoBorrowIndex(mToken, borrowIndex);
        distributeBorrowerMmo(mToken, borrower, borrowIndex);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates repayBorrow and reverts on rejection. May emit logs.
     * @param mToken Asset being repaid
     * @param payer The address repaying the borrow
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying being repaid
     * @param borrowerIndex The borrower index before repayment
     */
    function repayBorrowVerify(uint240 mToken, address payer, address borrower, uint actualRepayAmount, uint borrowerIndex) external {
        // Shh - currently unused
        mToken;
        payer;
        borrower;
        actualRepayAmount;
        borrowerIndex;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the liquidation should be allowed to occur
     * @param mTokenBorrowed The mToken in which underlying asset was borrowed by the borrower
     * @param mTokenCollateral The mToken which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param repayAmount The amount of underlying being repaid
     * @return 0 if the liquidation is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function liquidateBorrowAllowed(uint240 mTokenBorrowed, uint240 mTokenCollateral, address liquidator, address borrower, uint repayAmount) external returns (uint) {
        // Shh - currently unused
        liquidator;

        /* Fail if mTokenCollateral is non-fungible (ERC-721) type */
        (MTokenType mTokenType, , ) = parseToken(mTokenCollateral);
        if (mTokenType == MTokenType.ERC721_MTOKEN) {
            return uint(Error.INVALID_TOKEN_TYPE);
        }

        if (!isListed(mTokenBorrowed) || !isListed(mTokenCollateral)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* Fail if borrower not "in" the markets for both mTokenBorrowed and mTokenCollateral */
        if (!accountMembership(mTokenBorrowed, borrower) || !accountMembership(mTokenCollateral, borrower)) {
            return uint(Error.MARKET_NOT_ENTERED);
        }

        /* The borrower must have shortfall in order to be liquidatable */
        (Error err, , uint shortfall) = getAccountLiquidityInternal(borrower);
        if (err != Error.NO_ERROR) {
            return uint(err);
        }
        if (shortfall == 0) {
            return uint(Error.INSUFFICIENT_SHORTFALL);
        }

        /* The liquidator may not repay more than what is allowed by the closeFactor */
        ( , , address mTokenBorrowedAddress) = parseToken(mTokenBorrowed);
        uint borrowBalance = MTokenInterface(mTokenBorrowedAddress).borrowBalanceStored(borrower, mTokenBorrowed);
        uint maxClose = mul_ScalarTruncate(Exp({mantissa: closeFactorMantissa}), borrowBalance);
        if (repayAmount > maxClose) {
            return uint(Error.TOO_MUCH_REPAY);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Check if liquidation of non-fungible (ERC-721) mToken collateral is allowed
     * @param mToken The mToken collateral to check
     * @return 0 if the liquidation is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function liquidateERC721Allowed(uint240 mToken) external returns (uint)  {
        /* Fail if mToken is not non-fungible (ERC-721) type */
        (MTokenType mTokenType, , address mTokenAddress) = parseToken(mToken);
        if (mTokenType != MTokenType.ERC721_MTOKEN) {
            return uint(Error.INVALID_TOKEN_TYPE);
        }
    
        if (!isListed(mToken)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* Fail if owner not "in" the markets for mToken */
        address owner = MERC721Interface(mTokenAddress).ownerOf(mToken);
        if (!accountMembership(mToken, owner)) {
            return uint(Error.MARKET_NOT_ENTERED);
        }

        /* Fail if mToken cannot be auctioned by sender (liquidator) */
        uint err = auctionAllowed(mToken, msg.sender);
        if (err != uint(Error.NO_ERROR)) {
            return err;
        }

        /* Fail if mToken owner has no shortfall (anymore) */
        uint shortfall;
        (err, , shortfall) = getAccountLiquidity(owner);
        if (err != uint(Error.NO_ERROR) || shortfall == 0) {
            return uint(Error.INSUFFICIENT_SHORTFALL);
        }

        /* Fail if sender (liquidator) is also owner */
        if (msg.sender == owner) {
            return uint(Error.UNAUTHORIZED);
        }

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates liquidateBorrow and reverts on rejection. May emit logs.
     * @param mTokenBorrowed The mToken in which underlying asset was borrowed by the borrower
     * @param mTokenCollateral The mToken which was used as collateral and will be seized
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param actualRepayAmount The amount of underlying in mTokenBorrowed actually being repaid
     * @param seizeTokens The number of mTokenCollateral tokens seized
     */
    function liquidateBorrowVerify(uint240 mTokenBorrowed, uint240 mTokenCollateral, address liquidator, address borrower, uint actualRepayAmount, uint seizeTokens) external {
        // Shh - currently unused
        mTokenBorrowed;
        mTokenCollateral;
        liquidator;
        borrower;
        actualRepayAmount;
        seizeTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the seizing of assets should be allowed to occur
     * @param mTokenCollateral The mToken which was used as collateral and will be seized
     * @param mTokenBorrowed The mToken in which underlying asset was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeAllowed(uint240 mTokenCollateral, uint240 mTokenBorrowed, address liquidator, address borrower, uint seizeTokens) external returns (uint) {
        // Shh - currently unused
        seizeTokens;

        ( , , address mTokenCollateralAddress) = parseToken(mTokenCollateral);
        ( , , address mTokenBorrowedAddress) = parseToken(mTokenBorrowed);

        // Pausing is a very serious situation - we revert to sound the alarms
        require(!seizeGuardianPaused[getAnchorToken(mTokenCollateral)], "seize is paused");
        require(!seizeGuardianPaused[mTokenCollateral], "seize is paused");

        if (!isListed(mTokenCollateral) || !isListed(mTokenBorrowed)) {
            return uint(Error.MARKET_NOT_LISTED);
        }

        /* Fail if borrower not "in" the markets for both mTokenBorrowed and mTokenCollateral */
        if (!accountMembership(mTokenBorrowed, borrower) || !accountMembership(mTokenCollateral, borrower)) {
            return uint(Error.MARKET_NOT_ENTERED);
        }

        if (MTokenCommon(mTokenCollateralAddress).mtroller() != MTokenCommon(mTokenBorrowedAddress).mtroller()) {
            return uint(Error.MTROLLER_MISMATCH);
        }

        // Keep the flywheel moving
        updateMmoSupplyIndex(mTokenCollateral);
        distributeSupplierMmo(mTokenCollateral, borrower);
        distributeSupplierMmo(mTokenCollateral, liquidator);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates seize and reverts on rejection. May emit logs.
     * @param mTokenCollateral The mToken which was used as collateral and will be seized
     * @param mTokenBorrowed The mToken in which underlying asset was borrowed by the borrower
     * @param liquidator The address repaying the borrow and seizing the collateral
     * @param borrower The address of the borrower
     * @param seizeTokens The number of collateral tokens to seize
     */
    function seizeVerify(uint240 mTokenCollateral, uint240 mTokenBorrowed, address liquidator, address borrower, uint seizeTokens) external {
        // Shh - currently unused
        mTokenCollateral;
        mTokenBorrowed;
        liquidator;
        borrower;
        seizeTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /**
     * @notice Checks if the account should be allowed to transfer tokens in the given market
     * @param mToken The market to verify the transfer against
     * @param src The account which sources the mTokens
     * @param dst The account which receives the mTokens
     * @param transferTokens The number of mTokens to transfer
     * @return 0 if the transfer is allowed, otherwise a semi-opaque error code (See ErrorReporter.sol)
     */
    function transferAllowed(uint240 mToken, address src, address dst, uint transferTokens) external returns (uint) {

        // Pausing is a very serious situation - we revert to sound the alarms
        require(!transferGuardianPaused[getAnchorToken(mToken)], "transfer is paused");
        require(!transferGuardianPaused[mToken], "transfer is paused");

        // Currently the only consideration is whether or not
        // the src is allowed to redeem this many tokens
        // NB: This also checks mToken validity
        uint allowed = redeemAllowedInternal(mToken, src, transferTokens);
        if (allowed != uint(Error.NO_ERROR)) {
            return allowed;
        }

        // Keep the flywheel moving
        updateMmoSupplyIndex(mToken);
        distributeSupplierMmo(mToken, src);
        distributeSupplierMmo(mToken, dst);

        return uint(Error.NO_ERROR);
    }

    /**
     * @notice Validates transfer and reverts on rejection. May emit logs.
     * @param mToken The mToken being transferred
     * @param src The account which sources the mTokens
     * @param dst The account which receives the mTokens
     * @param transferTokens The number of mTokens to transfer
     */
    function transferVerify(uint240 mToken, address src, address dst, uint transferTokens) external {
        // Shh - currently unused
        mToken;
        src;
        dst;
        transferTokens;

        // Shh - we don't ever want this hook to be marked pure
        if (false) {
            maxAssets = maxAssets;
        }
    }

    /*** Liquidity/Liquidation Calculations ***/

    /**
     * @dev Local vars for avoiding stack-depth limits in calculating account liquidity.
     *  Note that `mTokenBalance` is the number of mTokens the account owns in the market,
     *  whereas `borrowBalance` is the amount of underlying that the account has borrowed.
     */
    struct AccountLiquidityLocalVars {
        uint sumCollateral;
        uint sumBorrowPlusEffects;
        uint mTokenBalance;
        uint borrowBalance;
        uint exchangeRateMantissa;
        uint oraclePriceMantissa;
        Exp collateralFactor;
        Exp exchangeRate;
        Exp oraclePrice;
        Exp tokensToDenom;
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @param account The account to determine liquidity for
     * @return (possible error code (semi-opaque),
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidity(address account) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, 0, 0, 0);

        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine the current account liquidity wrt collateral requirements
     * @param account The account to determine liquidity for
     * @return (possible error code,
                account liquidity in excess of collateral requirements,
     *          account shortfall below collateral requirements)
     */
    function getAccountLiquidityInternal(address account) internal view returns (Error, uint, uint) {
        return getHypotheticalAccountLiquidityInternal(account, 0, 0, 0);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param account The account to determine liquidity for
     * @param mTokenModify The mToken market to hypothetically redeem/borrow in
     * @param redeemTokens The number of mTokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @return (possible error code (semi-opaque),
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidity(
        address account,
        uint240 mTokenModify,
        uint redeemTokens,
        uint borrowAmount) public view returns (uint, uint, uint) {
        (Error err, uint liquidity, uint shortfall) = getHypotheticalAccountLiquidityInternal(account, mTokenModify, redeemTokens, borrowAmount);
        return (uint(err), liquidity, shortfall);
    }

    /**
     * @notice Determine what the account liquidity would be if the given amounts were redeemed/borrowed
     * @param account The account to determine liquidity for
     * @param mTokenModify The mToken market to hypothetically redeem/borrow in
     * @param redeemTokens The number of mTokens to hypothetically redeem
     * @param borrowAmount The amount of underlying to hypothetically borrow
     * @dev Note that we calculate the exchangeRateStored for each collateral mToken using stored data,
     *  without calculating accumulated interest.
     * @return (possible error code,
                hypothetical account liquidity in excess of collateral requirements,
     *          hypothetical account shortfall below collateral requirements)
     */
    function getHypotheticalAccountLiquidityInternal(
        address account,
        uint240 mTokenModify,
        uint redeemTokens,
        uint borrowAmount) internal view returns (Error, uint, uint) {

        AccountLiquidityLocalVars memory vars; // Holds all our calculation results
        uint oErr;

        // For each asset the account is in
        uint240[] memory assets = accountAssets[account];
        for (uint i = 0; i < assets.length; i++) {

            uint240 asset = assets[i];
            ( , , address assetAddress) = parseToken(asset);

            // Read the balances and exchange rate from the mToken
            (oErr, vars.mTokenBalance, vars.borrowBalance, vars.exchangeRateMantissa) = MTokenInterface(assetAddress).getAccountSnapshot(account, asset);
            if (oErr != 0) { // semi-opaque error code, we assume NO_ERROR == 0 is invariant between upgrades
                return (Error.SNAPSHOT_ERROR, 0, 0);
            }
            vars.collateralFactor = Exp({mantissa: collateralFactorMantissa(asset)});
            vars.exchangeRate = Exp({mantissa: vars.exchangeRateMantissa});

            // Get the normalized price of the asset
            vars.oraclePriceMantissa = getPrice(asset);
            if (vars.oraclePriceMantissa == 0) {
                return (Error.PRICE_ERROR, 0, 0);
            }
            vars.oraclePrice = Exp({mantissa: vars.oraclePriceMantissa});

            // Pre-compute a conversion factor from tokens -> ether (normalized price value)
            vars.tokensToDenom = mul_(mul_(vars.collateralFactor, vars.exchangeRate), vars.oraclePrice);

            // sumCollateral += tokensToDenom * mTokenBalance
            vars.sumCollateral = mul_ScalarTruncateAddUInt(vars.tokensToDenom, vars.mTokenBalance, vars.sumCollateral);

            // sumBorrowPlusEffects += oraclePrice * borrowBalance
            vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, vars.borrowBalance, vars.sumBorrowPlusEffects);

            // Calculate effects of interacting with mTokenModify
            if (asset == mTokenModify) {
                // redeem effect
                // sumBorrowPlusEffects += tokensToDenom * redeemTokens
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.tokensToDenom, redeemTokens, vars.sumBorrowPlusEffects);

                // borrow effect
                // sumBorrowPlusEffects += oraclePrice * borrowAmount
                vars.sumBorrowPlusEffects = mul_ScalarTruncateAddUInt(vars.oraclePrice, borrowAmount, vars.sumBorrowPlusEffects);
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
     * @dev Used in liquidation (called in mToken.liquidateBorrowFresh)
     * @param mTokenBorrowed The borrowed mToken
     * @param mTokenCollateral The collateral mToken
     * @param actualRepayAmount The amount of mTokenBorrowed underlying to convert into mTokenCollateral tokens
     * @return (errorCode, number of mTokenCollateral tokens to be seized in a liquidation)
     */
    function liquidateCalculateSeizeTokens(uint240 mTokenBorrowed, uint240 mTokenCollateral, uint actualRepayAmount) external view returns (uint, uint) {
        if (!isListed(mTokenBorrowed) || !isListed(mTokenCollateral)) {
            return (uint(Error.MARKET_NOT_LISTED), 0);
        }
        /* Read oracle prices for borrowed and collateral markets */
        uint priceBorrowedMantissa = getPrice(mTokenBorrowed);
        uint priceCollateralMantissa = getPrice(mTokenCollateral);
        if (priceBorrowedMantissa == 0 || priceCollateralMantissa == 0) {
            return (uint(Error.PRICE_ERROR), 0);
        }

        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        ( , , address mTokenCollateralAddress) = parseToken(mTokenCollateral);
        uint exchangeRateMantissa = MTokenInterface(mTokenCollateralAddress).exchangeRateStored(mTokenCollateral); // Note: reverts on error
        uint seizeTokens;
        Exp memory numerator;
        Exp memory numerator2;
        Exp memory denominator;

/* old calculation (Compound version)
        numerator = mul_(Exp({mantissa: liquidationIncentiveMantissa}), Exp({mantissa: priceBorrowedMantissa}));
        denominator = mul_(Exp({mantissa: priceCollateralMantissa}), Exp({mantissa: exchangeRateMantissa}));
        ratio = div_(numerator, denominator);

        seizeTokens = mul_ScalarTruncate(ratio, actualRepayAmount);
*/

/* new calculation avoids underflow due to truncation for cases where seizeTokens == 1 */
        numerator = mul_(Exp({mantissa: liquidationIncentiveMantissa}), Exp({mantissa: priceBorrowedMantissa}));
        numerator2 = mul_(numerator, actualRepayAmount);
        denominator = mul_(Exp({mantissa: priceCollateralMantissa}), Exp({mantissa: exchangeRateMantissa}));
        seizeTokens = truncate(div_(numerator2, denominator));

        return (uint(Error.NO_ERROR), seizeTokens);
    }

    // /**
    //  * @notice Return all of the markets
    //  * @dev The automatic getter may be used to access an individual market.
    //  * @return The list of market addresses
    //  */
    // not implemented for now
    //function getAllMarkets() public view returns (MToken[] memory) {
    //    return allMarkets;
    //}

    /**
     * @notice Returns the current block number
     * @dev Can be overriden for test purposes.
     * @return uint The current block number
     */
    function getBlockNumber() public view returns (uint) {
        return block.number;
    }

    /**
     * @notice Returns the current price of the given mToken asset from the oracle
     * @param mToken The mToken whose price to get
     * @return uint The underlying asset price mantissa (scaled by 1e18). For fungible underlying tokens that
     * means e.g. if one single underlying token costs 1 Wei then the asset price mantissa should be 1e18. 
     * In case of underlying (ERC-721 compliant) NFTs one NFT always corresponds to oneUnit = 1e18 
     * internal calculatory units (see MTokenInterfaces.sol), therefore if e.g. one NFT costs 0.1 ETH 
     * then the asset price mantissa returned here should be 0.1e18.
     * Zero means the price is unavailable.
     */
    function getPrice(uint240 mToken) public view returns (uint) {
        require(mToken != getAnchorToken(mToken), "no getPrice for anchor token");
        require(isListed(mToken), "mToken not listed");
        ( , , address mTokenAddress) = parseToken(mToken);
        address uAddress = MTokenCommon(mTokenAddress).underlyingContract();

        if (uAddress == underlyingContractETH()) {
            // Return price = 1.0 for ETH
            return 1.0e18;            
        }

        uint256 uTokenID = MTokenCommon(mTokenAddress).underlyingIDs(mToken);
        return oracle.getUnderlyingPrice(uAddress, uTokenID);
    }

/******* NOT PROPERLY CHECKED YET BELOW THIS POINT *****************/

    /*** Mmo Distribution ***/

    /**
     * @notice Set MMO speed for a single market
     * @param mToken The market whose MMO speed to update
     * @param mmoSpeed New MMO speed for market
     */
    function setMmoSpeedInternal(uint240 mToken, uint mmoSpeed) internal {
        uint currentMmoSpeed = mmoSpeeds[mToken];
        if (currentMmoSpeed != 0) {
            // note that MMO speed could be set to 0 to halt liquidity rewards for a market
            ( ,  , address mTokenAddress) = parseToken(mToken);
            Exp memory borrowIndex = Exp({mantissa: MTokenCommon(mTokenAddress).borrowIndex(mToken)});
            updateMmoSupplyIndex(mToken);
            updateMmoBorrowIndex(mToken, borrowIndex);
        } else if (mmoSpeed != 0) {
            // Add the MMO market
            require(isListed(mToken), "mmo market is not listed");

            if (mmoSupplyState[mToken].index == 0 && mmoSupplyState[mToken].block == 0) {
                mmoSupplyState[mToken] = MmoMarketState({
                    index: mmoInitialIndex,
                    block: safe32(getBlockNumber(), "block number exceeds 32 bits")
                });
            }

            if (mmoBorrowState[mToken].index == 0 && mmoBorrowState[mToken].block == 0) {
                mmoBorrowState[mToken] = MmoMarketState({
                    index: mmoInitialIndex,
                    block: safe32(getBlockNumber(), "block number exceeds 32 bits")
                });
            }
        }

        if (currentMmoSpeed != mmoSpeed) {
            mmoSpeeds[mToken] = mmoSpeed;
            emit MmoSpeedUpdated(mToken, mmoSpeed);
        }
    }

    /**
     * @notice Accrue MMO to the market by updating the supply index
     * @param mToken The market whose supply index to update
     */
    function updateMmoSupplyIndex(uint240 mToken) internal {
        MmoMarketState storage supplyState = mmoSupplyState[mToken];
        uint supplySpeed = mmoSpeeds[mToken];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(supplyState.block));
        if (deltaBlocks > 0 && supplySpeed > 0) {
            ( , , address mTokenAddress) = parseToken(mToken);
            uint supplyTokens = MTokenCommon(mTokenAddress).totalSupply(mToken);
            uint mmoAccrued = mul_(deltaBlocks, supplySpeed);
            Double memory ratio = supplyTokens > 0 ? fraction(mmoAccrued, supplyTokens) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: supplyState.index}), ratio);
            mmoSupplyState[mToken] = MmoMarketState({
                index: safe224(index.mantissa, "new index exceeds 224 bits"),
                block: safe32(blockNumber, "block number exceeds 32 bits")
            });
        } else if (deltaBlocks > 0) {
            supplyState.block = safe32(blockNumber, "block number exceeds 32 bits");
        }
    }

    /**
     * @notice Accrue MMO to the market by updating the borrow index
     * @param mToken The market whose borrow index to update
     */
    function updateMmoBorrowIndex(uint240 mToken, Exp memory marketBorrowIndex) internal {
        MmoMarketState storage borrowState = mmoBorrowState[mToken];
        uint borrowSpeed = mmoSpeeds[mToken];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, uint(borrowState.block));
        if (deltaBlocks > 0 && borrowSpeed > 0) {
            ( , , address mTokenAddress) = parseToken(mToken);
            uint borrowAmount = div_(MTokenCommon(mTokenAddress).totalBorrows(mToken), marketBorrowIndex);
            uint mmoAccrued = mul_(deltaBlocks, borrowSpeed);
            Double memory ratio = borrowAmount > 0 ? fraction(mmoAccrued, borrowAmount) : Double({mantissa: 0});
            Double memory index = add_(Double({mantissa: borrowState.index}), ratio);
            mmoBorrowState[mToken] = MmoMarketState({
                index: safe224(index.mantissa, "new index exceeds 224 bits"),
                block: safe32(blockNumber, "block number exceeds 32 bits")
            });
        } else if (deltaBlocks > 0) {
            borrowState.block = safe32(blockNumber, "block number exceeds 32 bits");
        }
    }

    /**
     * @notice Calculate MMO accrued by a supplier and possibly transfer it to them
     * @param mToken The market in which the supplier is interacting
     * @param supplier The address of the supplier to distribute MMO to
     */
    function distributeSupplierMmo(uint240 mToken, address supplier) internal {
        MmoMarketState storage supplyState = mmoSupplyState[mToken];
        Double memory supplyIndex = Double({mantissa: supplyState.index});
        Double memory supplierIndex = Double({mantissa: mmoSupplierIndex[mToken][supplier]});
        mmoSupplierIndex[mToken][supplier] = supplyIndex.mantissa;

        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = mmoInitialIndex;
        }

        Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
        ( , , address mTokenAddress) = parseToken(mToken);
        uint supplierTokens = MTokenInterface(mTokenAddress).balanceOf(supplier, mToken);
        uint supplierDelta = mul_(supplierTokens, deltaIndex);
        uint supplierAccrued = add_(mmoAccrued[supplier], supplierDelta);
        mmoAccrued[supplier] = supplierAccrued;
        emit DistributedSupplierMmo(mToken, supplier, supplierDelta, supplyIndex.mantissa);
    }

    /**
     * @notice Calculate MMO accrued by a borrower and possibly transfer it to them
     * @dev Borrowers will not begin to accrue until after the first interaction with the protocol.
     * @param mToken The market in which the borrower is interacting
     * @param borrower The address of the borrower to distribute MMO to
     */
    function distributeBorrowerMmo(uint240 mToken, address borrower, Exp memory marketBorrowIndex) internal {
        MmoMarketState storage borrowState = mmoBorrowState[mToken];
        Double memory borrowIndex = Double({mantissa: borrowState.index});
        Double memory borrowerIndex = Double({mantissa: mmoBorrowerIndex[mToken][borrower]});
        mmoBorrowerIndex[mToken][borrower] = borrowIndex.mantissa;

        if (borrowerIndex.mantissa > 0) {
            Double memory deltaIndex = sub_(borrowIndex, borrowerIndex);
            ( , , address mTokenAddress) = parseToken(mToken);
            uint borrowerAmount = div_(MTokenInterface(mTokenAddress).borrowBalanceStored(borrower, mToken), marketBorrowIndex);
            uint borrowerDelta = mul_(borrowerAmount, deltaIndex);
            uint borrowerAccrued = add_(mmoAccrued[borrower], borrowerDelta);
            mmoAccrued[borrower] = borrowerAccrued;
            emit DistributedBorrowerMmo(mToken, borrower, borrowerDelta, borrowIndex.mantissa);
        }
    }

    /**
     * @notice Calculate additional accrued MMO for a contributor since last accrual
     * @param contributor The address to calculate contributor rewards for
     */
    function updateContributorRewards(address contributor) public {
        uint mmoSpeed = mmoContributorSpeeds[contributor];
        uint blockNumber = getBlockNumber();
        uint deltaBlocks = sub_(blockNumber, lastContributorBlock[contributor]);
        if (deltaBlocks > 0 && mmoSpeed > 0) {
            uint newAccrued = mul_(deltaBlocks, mmoSpeed);
            uint contributorAccrued = add_(mmoAccrued[contributor], newAccrued);

            mmoAccrued[contributor] = contributorAccrued;
            lastContributorBlock[contributor] = blockNumber;
        }
    }

    // /**
    //  * @notice Claim all the mmo accrued by holder in all markets
    //  * @param holder The address to claim MMO for
    //  */
    // This is not yet implemented
    // function claimMmo(address holder) public {
    //    return claimMmo(holder, allMarkets);
    // }

    /**
     * @notice Claim all the mmo accrued by holder in the specified markets
     * @param holder The address to claim MMO for
     * @param mTokens The list of markets to claim MMO in
     */
    function claimMmo(address holder, uint240[] memory mTokens) public {
        address[] memory holders = new address[](1);
        holders[0] = holder;
        claimMmo(holders, mTokens, true, true);
    }

    /**
     * @notice Claim all mmo accrued by the holders
     * @param holders The addresses to claim MMO for
     * @param mTokens The list of markets to claim MMO in
     * @param borrowers Whether or not to claim MMO earned by borrowing
     * @param suppliers Whether or not to claim MMO earned by supplying
     */
    function claimMmo(address[] memory holders, uint240[] memory mTokens, bool borrowers, bool suppliers) public {
        for (uint i = 0; i < mTokens.length; i++) {
            uint240 mToken = mTokens[i];
            require(isListed(mToken), "market must be listed");
            if (borrowers == true) {
                ( , , address mTokenAddress) = parseToken(mToken);
                Exp memory borrowIndex = Exp({mantissa: MTokenCommon(mTokenAddress).borrowIndex(mToken)});
                updateMmoBorrowIndex(mToken, borrowIndex);
                for (uint j = 0; j < holders.length; j++) {
                    distributeBorrowerMmo(mToken, holders[j], borrowIndex);
                    mmoAccrued[holders[j]] = grantMmoInternal(holders[j], mmoAccrued[holders[j]]);
                }
            }
            if (suppliers == true) {
                updateMmoSupplyIndex(mToken);
                for (uint j = 0; j < holders.length; j++) {
                    distributeSupplierMmo(mToken, holders[j]);
                    mmoAccrued[holders[j]] = grantMmoInternal(holders[j], mmoAccrued[holders[j]]);
                }
            }
        }
    }

    /**
     * @notice Transfer MMO to the user
     * @dev Note: If there is not enough MMO, we do not perform the transfer all.
     * @param user The address of the user to transfer MMO to
     * @param amount The amount of MMO to (possibly) transfer
     * @return The amount of MMO which was NOT transferred to the user
     */
    function grantMmoInternal(address user, uint amount) internal returns (uint) {
        Mmo mmo = Mmo(getMmoAddress());
        uint mmoRemaining = mmo.balanceOf(address(this));
        if (amount > 0 && amount <= mmoRemaining) {
            mmo.transfer(user, amount);
            return 0;
        }
        return amount;
    }

    /*** Mmo Distribution Admin ***/

    /**
     * @notice Transfer MMO to the recipient
     * @dev Note: If there is not enough MMO, we do not perform the transfer all.
     * @param recipient The address of the recipient to transfer MMO to
     * @param amount The amount of MMO to (possibly) transfer
     */
    function _grantMmo(address recipient, uint amount) public {
        require(msg.sender == getAdmin(), "only admin can grant mmo");
        uint amountLeft = grantMmoInternal(recipient, amount);
        require(amountLeft == 0, "insufficient mmo for grant");
        emit MmoGranted(recipient, amount);
    }

    /**
     * @notice Set MMO speed for a single market
     * @param mToken The market whose MMO speed to update
     * @param mmoSpeed New MMO speed for market
     */
    function _setMmoSpeed(uint240 mToken, uint mmoSpeed) public {
        require(msg.sender == getAdmin(), "only admin can set mmo speed");
        setMmoSpeedInternal(mToken, mmoSpeed);
    }

    /**
     * @notice Set MMO speed for a single contributor
     * @param contributor The contributor whose MMO speed to update
     * @param mmoSpeed New MMO speed for contributor
     */
    function _setContributorMmoSpeed(address contributor, uint mmoSpeed) public {
        require(msg.sender == getAdmin(), "only admin can set mmo speed");

        // note that MMO speed could be set to 0 to halt liquidity rewards for a contributor
        updateContributorRewards(contributor);
        if (mmoSpeed == 0) {
            // release storage
            delete lastContributorBlock[contributor];
        } else {
            lastContributorBlock[contributor] = getBlockNumber();
        }
        mmoContributorSpeeds[contributor] = mmoSpeed;

        emit ContributorMmoSpeedUpdated(contributor, mmoSpeed);
    }

    /**
     * @notice Return the address of the MMO token
     * @return The address of MMO
     */
    function getMmoAddress() public view returns (address) {
        return mmoTokenAddress;
    }
}