pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: GPL-3.0-only



import "./utils/Common.sol";
import "./utils/Governed.sol";

import "./lib/SafeMath.sol";
import "./lib/SafeInt256.sol";
import "./lib/SafeUInt128.sol";
import "./utils/RiskFramework.sol";

import "./interface/IRateOracle.sol";
import "./interface/IPortfoliosCallable.sol";

import "./storage/PortfoliosStorage.sol";
import "./CashMarket.sol";

/**
 * @title Portfolios
 * @notice Manages account portfolios which includes all fCash positions and liquidity tokens.
 */
contract Portfolios is PortfoliosStorage, IPortfoliosCallable, Governed {
    using SafeMath for uint256;
    using SafeInt256 for int256;
    using SafeUInt128 for uint128;

    struct TradePortfolioState {
        uint128 amountRemaining;
        uint256 indexCount;
        int256 unlockedCurrentCash;
        Common.Asset[] portfolioChanges;
    }

    /**
     * @notice Emitted when an account has its portfolio settled, only emitted if the portfolio has changed
     * @param account the account that had its porfolio modified
     */
    event SettleAccount(address account);

    /**
     * @notice Emitted when an account has its portfolio settled, all accounts are emitted in the batch
     * @param accounts batch of accounts that *may* have been settled
     */
    event SettleAccountBatch(address[] accounts);

    /**
     * @notice Emitted when a new cash group is listed
     * @param cashGroupId id of the new cash group
     */
    event NewCashGroup(uint8 indexed cashGroupId);

    /**
     * @notice Emitted when a new cash group is updated
     * @param cashGroupId id of the updated cash group
     */
    event UpdateCashGroup(uint8 indexed cashGroupId);

    /**
     * @notice Emitted when max assets is set
     * @param maxAssets the max assets a portfolio can hold
     */
    event SetMaxAssets(uint256 maxAssets);

    /**
     * @notice Notice for setting haircut amount for liquidity tokens
     * @param liquidityHaircut amount of haircut applied to liquidity token claims 
     * @param fCashHaircut amount of negative haircut applied to fcash
     * @param fCashMaxHaircut max haircut amount applied to fcash
     */
    event SetHaircuts(uint128 liquidityHaircut, uint128 fCashHaircut, uint128 fCashMaxHaircut);

    /**
     * @dev skip
     * @param directory holds contract addresses for dependencies
     * @param numCurrencies initializes the number of currencies listed on the escrow contract
     * @param maxAssets max assets that a portfolio can hold
     */
    function initialize(address directory, address owner, uint16 numCurrencies, uint256 maxAssets) external initializer {
        Governed.initialize(directory, owner);

        // We must initialize this here because it cannot be a constant.
        NULL_ASSET = Common.Asset(0, 0, 0, 0, 0, 0);
        G_NUM_CURRENCIES = numCurrencies;
        G_MAX_ASSETS = maxAssets;

        emit SetMaxAssets(maxAssets);
    }

    /****** Governance Parameters ******/

    /**
     * @notice Sets the haircut amount for liquidity token claims, this is set to a percentage
     * less than 1e18, for example, a 5% haircut will be set to 0.95e18.
     * @dev governance
     * @param liquidityHaircut amount of negative haircut applied to token claims
     * @param fCashHaircut amount of negative haircut applied to fcash
     * @param fCashMaxHaircut max haircut amount applied to fcash
     */
    function setHaircuts(uint128 liquidityHaircut, uint128 fCashHaircut, uint128 fCashMaxHaircut) external onlyOwner {
        PortfoliosStorageSlot._setLiquidityHaircut(liquidityHaircut);
        PortfoliosStorageSlot._setfCashHaircut(fCashHaircut);
        PortfoliosStorageSlot._setfCashMaxHaircut(fCashMaxHaircut);
        Escrow().setLiquidityHaircut(liquidityHaircut);

        emit SetHaircuts(liquidityHaircut, fCashHaircut, fCashMaxHaircut);
    }

    /**
     * @dev skip
     * @param numCurrencies the total number of currencies set by escrow
     */
    function setNumCurrencies(uint16 numCurrencies) external override {
        require(calledByEscrow(), "20");
        G_NUM_CURRENCIES = numCurrencies;
    }

    /**
     * @notice Set the max assets that a portfolio can hold. The default will be initialized to something
     * like 10 assets, but this will be increased as new markets are created.
     * @dev governance
     * @param maxAssets new max asset number
     */
    function setMaxAssets(uint256 maxAssets) external onlyOwner {
        G_MAX_ASSETS = maxAssets;

        emit SetMaxAssets(maxAssets);
    }

    /**
     * @notice An cash group defines a collection of similar fCashs where the risk ladders can be netted
     * against each other. The identifier is only 1 byte so we can only have 255 cash groups, 0 is unused.
     * @dev governance
     * @param numMaturities the total number of maturitys
     * @param maturityLength the maturity length (in seconds)
     * @param precision the discount rate precision
     * @param currency the token address of the currenty this fCash settles in
     * @param cashMarket the rate oracle that defines the discount rate
     */
    function createCashGroup(
        uint32 numMaturities,
        uint32 maturityLength,
        uint32 precision,
        uint16 currency,
        address cashMarket
    ) external onlyOwner {
        require(currentCashGroupId <= MAX_CASH_GROUPS, "32");
        require(Escrow().isValidCurrency(currency), "19");

        currentCashGroupId++;
        cashGroups[currentCashGroupId] = Common.CashGroup(
            numMaturities,
            maturityLength,
            precision,
            cashMarket,
            currency
        );

        if (cashMarket == address(0)) {
            // If cashMarket is set to address 0, then it is an idiosyncratic cash group that does not have
            // an AMM that will trade it. It can only be traded off chain and created via mintfCashPair
            require(numMaturities == 1);
        } else if (cashMarket != address(0)) {
            // The fCash is set to 0 for discount rate oracles and there is no max rate as well.
            IRateOracle(cashMarket).setParameters(currentCashGroupId, 0, precision, maturityLength, numMaturities, 0);
        }

        emit NewCashGroup(currentCashGroupId);
    }

    /**
     * @notice Updates cash groups. Be very careful when calling this function! When changing maturities and
     * maturity sizes the markets must be updated as well.
     * @dev governance
     * @param cashGroupId the group id to update
     * @param numMaturities this is safe to update as long as the discount rate oracle is not shared
     * @param maturityLength this is only safe to update when there are no assets left
     * @param precision this is only safe to update when there are no assets left
     * @param currency this is safe to update if there are no assets or the new currency is equivalent
     * @param cashMarket this is safe to update once the oracle is established
     */
    function updateCashGroup(
        uint8 cashGroupId,
        uint32 numMaturities,
        uint32 maturityLength,
        uint32 precision,
        uint16 currency,
        address cashMarket
    ) external onlyOwner {
        require(
            cashGroupId != 0 && cashGroupId <= currentCashGroupId,
            "33"
        );
        require(Escrow().isValidCurrency(currency), "19");

        Common.CashGroup storage i = cashGroups[cashGroupId];
        if (i.numMaturities != numMaturities) i.numMaturities = numMaturities;
        if (i.maturityLength != maturityLength) i.maturityLength = maturityLength;
        if (i.precision != precision) i.precision = precision;
        if (i.currency != currency) i.currency = currency;
        if (i.cashMarket != cashMarket) i.cashMarket = cashMarket;

        // The fCash is set to 0 for discount rate oracles and there is no max rate as well.
        IRateOracle(cashMarket).setParameters(cashGroupId, 0, precision, maturityLength, numMaturities, 0);

        emit UpdateCashGroup(cashGroupId);
    }

    /****** Governance Parameters ******/

    /***** Public View Methods *****/

    /**
     * @notice Returns the assets of an account
     * @param account to retrieve
     * @return an array representing the account's portfolio
     */
    function getAssets(address account) public override view returns (Common.Asset[] memory) {
        return _accountAssets[account];
    }

    /**
     * @notice Returns a particular asset via index
     * @param account to retrieve
     * @param index of asset
     * @return a single asset by index in the portfolio
     */
    function getAsset(address account, uint256 index) public view returns (Common.Asset memory) {
        return _accountAssets[account][index];
    }

    /**
     * @notice Returns a particular cash group
     * @param cashGroupId to retrieve
     * @return the given cash group
     */
    function getCashGroup(uint8 cashGroupId) public override view returns (Common.CashGroup memory) {
        return cashGroups[cashGroupId];
    }

    /**
     * @notice Returns a batch of cash groups
     * @param groupIds array of cash group ids to retrieve
     * @return an array of cash group objects
     */
    function getCashGroups(uint8[] memory groupIds) public override view returns (Common.CashGroup[] memory) {
        Common.CashGroup[] memory results = new Common.CashGroup[](groupIds.length);

        for (uint256 i; i < groupIds.length; i++) {
            results[i] = cashGroups[groupIds[i]];
        }

        return results;
    }

    /**
     * @notice Public method for searching for a asset in an account.
     * @param account account to search
     * @param assetType the type of asset to search for
     * @param cashGroupId the cash group id
     * @param instrumentId the instrument id
     * @param maturity the maturity timestamp of the asset
     * @return (asset, index of asset)
     */
    function searchAccountAsset(
        address account,
        bytes1 assetType,
        uint8 cashGroupId,
        uint16 instrumentId,
        uint32 maturity
    ) public override view returns (Common.Asset memory, uint256) {
        Common.Asset[] storage portfolio = _accountAssets[account];
        (
            bool found, uint256 index, /* uint128 */, /* bool */ 
        ) = _searchAsset(portfolio, assetType, cashGroupId, instrumentId, maturity, false);

        if (!found) return (NULL_ASSET, index);

        return (portfolio[index], index);
    }

    /**
     * @notice Stateful version of free collateral, first settles all assets in the account before returning
     * the free collateral parameters. Generally, external developers should not need to call this function. It is used
     * internally to both check free collateral and ensure that the portfolio does not have any matured assets.
     * Call `freeCollateralView` if you require a view function.
     * @param account address of account to get free collateral for
     * @return (net free collateral position, an array of the net currency available)
     */
    function freeCollateral(address account) public override returns (int256, int256[] memory, int256[] memory) {
        // This will emit an event, which is the correct action here.
        settleMaturedAssets(account);

        return freeCollateralView(account);
    }

    function freeCollateralAggregateOnly(address account) public override returns (int256) {
        // This will emit an event, which is the correct action here.
        settleMaturedAssets(account);
        
        (int256 fc, /* int256[] memory */, /* int256[] memory */) = freeCollateralView(account);

        return fc;
    }

    /**
     * @notice Stateful version of free collateral called during settlement and liquidation.
     * @dev skip
     * @param account address of account to get free collateral for
     * @param localCurrency local currency for the liquidation
     * @param collateralCurrency collateral currency for the liquidation
     * @return FreeCollateralFactors object
     */
    function freeCollateralFactors(
        address account,
        uint256 localCurrency,
        uint256 collateralCurrency
    ) public override returns (Common.FreeCollateralFactors memory) {
        require(calledByEscrow(), "20");
        // This will not emit an event, which is the correct action here.
        _settleMaturedAssets(account);

        (int256 fc, int256[] memory netCurrencyAvailable, int256[] memory cashClaims) = freeCollateralView(account);

        return Common.FreeCollateralFactors(
            fc,
            netCurrencyAvailable[localCurrency],
            netCurrencyAvailable[collateralCurrency],
            cashClaims[localCurrency],
            cashClaims[collateralCurrency]
        );
    }

    /**
     * @notice Returns the free collateral balance for an account as a view functon.
     * @dev - INVALID_EXCHANGE_RATE: exchange rate returned by the oracle is less than 0
     * @param account account in question
     * @return (net free collateral position, an array of the net currency available)
     */
    function freeCollateralView(address account) public override view returns (int256, int256[] memory, int256[] memory) {
        int256[] memory balances = Escrow().getBalances(account);
        return _freeCollateral(account, balances);
    }

    function _freeCollateral(address account, int256[] memory balances) internal view returns (int256, int256[] memory, int256[] memory) {
        Common.Asset[] memory portfolio = _accountAssets[account];
        int256[] memory cashClaims = new int256[](balances.length);

        if (portfolio.length > 0) {
            // This returns the net requirement in each currency held by the portfolio.
            Common.Requirement[] memory requirements = RiskFramework.getRequirement(
                portfolio,
                address(this)
            );

            for (uint256 i; i < requirements.length; i++) {
                uint256 currency = uint256(requirements[i].currency);
                cashClaims[currency] = cashClaims[currency].add(requirements[i].cashClaim);
                balances[currency] = balances[currency].add(requirements[i].cashClaim).add(requirements[i].netfCashValue);
            }
        }

        // Collateral requirements are denominated in ETH and positive.
        int256[] memory ethBalances = Escrow().convertBalancesToETH(balances);

        // Sum up the required balances in ETH
        int256 fc;
        for (uint256 i; i < balances.length; i++) {
            fc = fc.add(ethBalances[i]);
        }

        return (fc, balances, cashClaims);
    }

    /***** Public Authenticated Methods *****/

    /**
     * @notice Updates the portfolio of an account with a asset, merging it into the rest of the
     * portfolio if necessary.
     * @dev skip
     * @param account to insert the asset to
     * @param asset asset to insert into the account
     * @param checkFreeCollateral allows free collateral check to be skipped (BE CAREFUL WITH THIS!)
     */
    function upsertAccountAsset(
        address account,
        Common.Asset calldata asset,
        bool checkFreeCollateral
    ) external override {
        // Only the fCash market can insert assets into a portfolio
        address cashMarket = cashGroups[asset.cashGroupId].cashMarket;
        require(msg.sender == cashMarket, "20");

        Common.Asset[] storage portfolio = _accountAssets[account];
        _upsertAsset(portfolio, asset, false);

        if (checkFreeCollateral) {
            (
                int256 fc, /* int256[] memory */, /* int256[] memory */
            ) = freeCollateral(account);
            require(fc >= 0, "5");
        }
    }

    /**
     * @notice Updates the portfolio of an account with a batch of assets, merging it into the rest of the
     * portfolio if necessary.
     * @dev skip
     * @param account to insert the assets into
     * @param assets array of assets to insert into the account
     * @param checkFreeCollateral allows free collateral check to be skipped (BE CAREFUL WITH THIS!)
     */
    function upsertAccountAssetBatch(
        address account,
        Common.Asset[] calldata assets,
        bool checkFreeCollateral
    ) external override {
        if (assets.length == 0) {
            return;
        }

        // Here we check that all the cash group ids are the same if the liquidation auction
        // is not calling this function. If this is not the case then we have an issue. Cash markets
        // should only ever call this function with the same cash group id for all the assets
        // they submit.
        uint16 id = assets[0].cashGroupId;
        for (uint256 i = 1; i < assets.length; i++) {
            require(assets[i].cashGroupId == id, "53");
        }

        address cashMarket = cashGroups[assets[0].cashGroupId].cashMarket;
        require(msg.sender == cashMarket, "20");

        Common.Asset[] storage portfolio = _accountAssets[account];
        for (uint256 i; i < assets.length; i++) {
            _upsertAsset(portfolio, assets[i], false);
        }

        if (checkFreeCollateral) {
            (
                int256 fc, /* int256[] memory */, /* int256[] memory */
            ) = freeCollateral(account);
            require(fc >= 0, "5");
        }
    }

    /**
     * @notice Transfers a asset from one account to another.
     * @dev skip
     * @param from account to transfer from
     * @param to account to transfer to
     * @param assetType the type of asset to search for
     * @param cashGroupId the cash group id
     * @param instrumentId the instrument id
     * @param maturity the maturity of the asset
     * @param value the amount of notional transfer between accounts
     */
    function transferAccountAsset(
        address from,
        address to,
        bytes1 assetType,
        uint8 cashGroupId,
        uint16 instrumentId,
        uint32 maturity,
        uint128 value
    ) external override {
        // Can only be called by ERC1155 token to transfer assets between accounts.
        require(calledByERC1155Token(), "20");

        Common.Asset[] storage fromPortfolio = _accountAssets[from];
        (
            bool found, uint256 index, /* uint128 */, /* bool */
        ) = _searchAsset(fromPortfolio, assetType, cashGroupId, instrumentId, maturity, false);
        require(found, "54");

        uint32 rate = fromPortfolio[index].rate;
        _reduceAsset(fromPortfolio, fromPortfolio[index], index, value);

        Common.Asset[] storage toPortfolio = _accountAssets[to];
        _upsertAsset(
            toPortfolio,
            Common.Asset(cashGroupId, instrumentId, maturity, assetType, rate, value),
            false
        );

        // All transfers of assets must pass a free collateral check.
        (
            int256 fc, /* int256[] memory */, /* int256[] memory */
        ) = freeCollateral(from);
        require(fc >= 0, "5");

        // Receivers of transfers do not need to pass a free collateral check because we only allow transfers
        // of positive value. Their free collateral position will always increase.
    }

    /**
     * @notice Used by ERC1155 token contract to create block trades for fCash pairs. Allows idiosyncratic
     * fCash when cashGroup is set to zero.
     * @dev skip
     */
    function mintfCashPair(
        address payer,
        address receiver,
        uint8 cashGroupId,
        uint32 maturity,
        uint128 notional
    ) external override {
        require(calledByERC1155Trade(), "20");
        require(cashGroupId != 0 && cashGroupId <= currentCashGroupId, "33");

        uint32 blockTime = uint32(block.timestamp);
        require(blockTime < maturity, "46");

        Common.CashGroup memory fcg = cashGroups[cashGroupId];

        uint32 maxMaturity;
        if (fcg.cashMarket != address(0)) {
            // This is a cash group that is traded on an AMM so we ensure that the maturity fits
            // the cadence.
            require(maturity % fcg.maturityLength == 0, "7");

            maxMaturity = blockTime - (blockTime % fcg.maturityLength) + (fcg.maturityLength * fcg.numMaturities);
        } else {
            // This is an idiosyncratic asset so its max maturity is simply relative to the current time
            maxMaturity = blockTime + fcg.maturityLength;
        }
        require(maturity <= maxMaturity, "45");


        _upsertAsset(
            _accountAssets[payer],
            Common.Asset(
                cashGroupId,
                0,
                maturity,
                Common.getCashPayer(),
                fcg.precision,
                notional
            ),
            false
        );

        _upsertAsset(
            _accountAssets[receiver],
            Common.Asset(
                cashGroupId,
                0,
                maturity,
                Common.getCashReceiver(),
                fcg.precision,
                notional
            ),
            false
        );

        (int256 fc, /* int256[] memory */, /* int256[] memory */) = freeCollateral(payer);
        require(fc >= 0, "5");

        // NOTE: we do not check that the receiver has sufficient free collateral because their collateral
        // position will always increase as a result.
    }

    /**
     * @notice Settles all matured cash assets and liquidity tokens in a user's portfolio. This method is
     * unauthenticated, anyone may settle the assets in any account. This is required for accounts that
     * have negative cash and counterparties need to settle against them. Generally, external developers
     * should not need to call this function. We ensure that accounts are settled on every free collateral
     * check, cash settlement, and liquidation.
     * @param account the account referenced
     */
    function settleMaturedAssets(address account) public override {
        bool didSettle = _settleMaturedAssets(account);

        if (didSettle) {
            emit SettleAccount(account);
        }
    }

    /**
     * @notice Settle a batch of accounts. See note for `settleMaturedAssets`, external developers should not need
     * to call this function.
     * @param accounts an array of accounts to settle
     */
    function settleMaturedAssetsBatch(address[] calldata accounts) external override {
        for (uint256 i; i < accounts.length; i++) {
            _settleMaturedAssets(accounts[i]);
        }

        // We do not want to emit when this is called by escrow during settle cash.
        if (!calledByEscrow()) {
            emit SettleAccountBatch(accounts);
        }
    }

    /**
     * @notice Settles all matured cash assets and liquidity tokens in a user's portfolio. This method is
     * unauthenticated, anyone may settle the assets in any account. This is required for accounts that
     * have negative cash and counterparties need to settle against them.
     * @param account the account referenced
     * @return true if the account had any assets that were settled, used to determine if we emit
     * an event or not
     */
    function _settleMaturedAssets(address account) internal returns (bool) {
        bool didSettle = false;
        Common.Asset[] storage portfolio = _accountAssets[account];
        uint32 blockTime = uint32(block.timestamp);

        // This is only used when merging the account's portfolio for updating cash balances in escrow. We
        // keep this here so that we can do a single function call to settle all the cash in Escrow.
        int256[] memory settledCash = new int256[](uint256(G_NUM_CURRENCIES + 1));
        uint256 length = portfolio.length;

        // Loop through the portfolio and find the assets that have matured.
        for (uint256 i; i < length; i++) {
            if (portfolio[i].maturity <= blockTime) {
                Common.Asset memory asset = portfolio[i];
                // Here we are dealing with a matured asset. We get the appropriate currency for
                // the instrument. We may want to cache this somehow, but in all likelihood there
                // will not be multiple matured assets in the same cash group.
                Common.CashGroup memory fcg = cashGroups[asset.cashGroupId];
                uint16 currency = fcg.currency;

                if (Common.isCashPayer(asset.assetType)) {
                    // If the asset is a payer, we subtract from the cash balance
                    settledCash[currency] = settledCash[currency].sub(asset.notional);
                } else if (Common.isCashReceiver(asset.assetType)) {
                    // If the asset is a receiver, we add to the cash balance
                    settledCash[currency] = settledCash[currency].add(asset.notional);
                } else if (Common.isLiquidityToken(asset.assetType)) {
                    // Settling liquidity tokens is a bit more involved since we need to remove
                    // money from the collateral pools. This function returns the amount of fCash
                    // the liquidity token has a claim to.
                    address cashMarket = fcg.cashMarket;
                    // This function call will transfer the collateral claim back to the Escrow account.
                    uint128 fCashAmount = CashMarket(cashMarket).settleLiquidityToken(
                        account,
                        asset.notional,
                        asset.maturity
                    );
                    settledCash[currency] = settledCash[currency].add(fCashAmount);
                } else {
                    revert("7");
                }

                // Remove asset from the portfolio
                _removeAsset(portfolio, i);
                // The portfolio has gotten smaller, so we need to go back to account for the removed asset.
                i--;
                length = length == 0 ? 0 : length - 1;
                didSettle = true;
            }
        }

        // We call the escrow contract to update the account's cash balances.
        if (didSettle) {
            Escrow().portfolioSettleCash(account, settledCash);
        }

        return didSettle;
    }

    /***** Public Authenticated Methods *****/

    /***** Liquidation Methods *****/

    /**
     * @notice Looks for ways to take cash from the portfolio and return it to the escrow contract during
     * cash settlement.
     * @dev skip
     * @param account the account to extract cash from
     * @param currency the currency that the token should be denominated in
     * @param amount the amount of cash to extract from the portfolio
     * @return returns the amount of remaining cash value (if any) that the function was unable
     *  to extract from the portfolio
     */
    function raiseCurrentCashViaLiquidityToken(
        address account,
        uint16 currency,
        uint128 amount
    ) external override returns (uint128) {
        // Sorting the portfolio ensures that as we iterate through it we see each cash group
        // in batches. However, this means that we won't be able to track the indexes to remove correctly.
        Common.Asset[] memory portfolio = Common._sortPortfolio(_accountAssets[account]);
        TradePortfolioState memory state = _tradePortfolio(account, currency, amount, Common.getLiquidityToken(), portfolio);

        return state.amountRemaining;
    }

    /**
     * @notice Trades cash receiver in the portfolio for cash. Only possible if there are no liquidity tokens in the portfolio
     * as required by `settlefCash` and `liquidatefCash`. If fCash assets cannot be sold in the CashMarket, sells the fCash to
     * the liquidator at a discount.
     * @dev skip
     * @param account the account to extract cash from
     * @param liquidator the account that is initiating the action
     * @param currency the currency that the token should be denominated in
     * @param amount the amount of cash to extract from the portfolio
     * @return returns the amount of remaining cash value (if any) that the function was unable
     *  to extract from the portfolio
     */
    function raiseCurrentCashViaCashReceiver(
        address account,
        address liquidator,
        uint16 currency,
        uint128 amount
    ) external override returns (uint128, uint128) {
        // Sorting the portfolio ensures that as we iterate through it we see each cash group
        // in batches. However, this means that we won't be able to track the indexes to remove correctly.
        Common.Asset[] memory portfolio = Common._sortPortfolio(_accountAssets[account]);

        // If a portfolio has liquidity tokens then it still has an asset that can be converted to cash more directly than fCash
        // receiver tokens. Will not proceed until the portfolio does not have liquidity tokens.
        uint256 fCashReceivers;
        for (uint256 i; i < portfolio.length; i++) {
            require(!Common.isLiquidityToken(portfolio[i].assetType), "56");

            // Technically we should check for the proper currency here but we do this inside
            // _tradefCashLiquidator. Not doing it here to save some SLOAD calls. This serves as
            // an upper bound for the receivers in the portfolio.
            if (Common.isCashReceiver(portfolio[i].assetType)) fCashReceivers++;
        }

        require(fCashReceivers > 0, "57");
        TradePortfolioState memory state = _tradePortfolio(account, currency, amount, Common.getCashReceiver(), portfolio);

        uint128 liquidatorPayment;
        if (fCashReceivers > state.indexCount && state.amountRemaining > 0) {
            // This means that there are fCashRecievers in the portfolio that were unable to be traded on the market. In this case
            // we will allow the caller to purchase a portion of the fCashReceiver at a heavily discounted amount.

            (state.amountRemaining, liquidatorPayment) = _tradefCashLiquidator(
                _accountAssets[account],
                _accountAssets[liquidator],
                state.amountRemaining,
                currency
            );
        }

        return (state.amountRemaining, liquidatorPayment);
    }

    /**
     * @notice Trades fCash receivers to the liquidator at a discount. Transfers the assets between portfolios and returns
     * the amount that the liquidator must pay in return for the assets.
     */
    function _tradefCashLiquidator(
        Common.Asset[] storage portfolio,
        Common.Asset[] storage liquidatorPortfolio,
        uint128 amountRemaining,
        uint16 currency
    ) internal returns (uint128, uint128) {
        uint128 liquidatorPayment;
        uint128 notionalToTransfer;

        uint256 length = portfolio.length;
        Common.CashGroup memory cg;
        uint128 fCashHaircut = PortfoliosStorageSlot._fCashHaircut();
        uint128 fCashMaxHaircut = PortfoliosStorageSlot._fCashMaxHaircut();

        for (uint256 i; i < length; i++) {
            Common.Asset memory asset = portfolio[i];
            if (Common.isCashReceiver(asset.assetType)) {
                cg = cashGroups[asset.cashGroupId];
                if (cg.currency != currency) continue;
                 
                (liquidatorPayment, notionalToTransfer, amountRemaining) = _calculateNotionalToTransfer(
                    fCashHaircut,
                    fCashMaxHaircut,
                    liquidatorPayment,
                    amountRemaining,
                    asset
                );

                if (notionalToTransfer == asset.notional) {
                    // This is a full transfer and we will remove the asset, we need to update the loop
                    // variables as well.
                    _removeAsset(portfolio, i);
                    i--;
                    length = length == 0 ? 0 : length - 1;
                } else {
                    // This is a partial transfer and it means that state.amountRemaining is now
                    // equal to zero and we will exit the loop.
                    _reduceAsset(portfolio, portfolio[i], i, notionalToTransfer);
                }

                asset.notional = notionalToTransfer;
                _upsertAsset(liquidatorPortfolio, asset, false);
            }

            if (amountRemaining == 0) break;
        }

        return (amountRemaining, liquidatorPayment);
    }

    function _calculateNotionalToTransfer(
        uint128 fCashHaircut,
        uint128 fCashMaxHaircut,
        uint128 liquidatorPayment,
        uint128 amountRemaining,
        Common.Asset memory asset
    ) internal view returns (uint128, uint128, uint128) {
        // blockTime is in here because of the stack size
        uint32 blockTime = uint32(block.timestamp);
        uint128 notionalToTransfer;
        uint128 assetValue;
        int256 tmp = RiskFramework._calculateReceiverValue(
            asset.notional,
            asset.maturity,
            blockTime,
            fCashHaircut,
            fCashMaxHaircut
        );
        // Asset values will always be positive.
        require(tmp >= 0);
        assetValue = uint128(tmp);
   
        if (assetValue >= amountRemaining) {
            notionalToTransfer = SafeCast.toUint128(
                uint256(asset.notional)
                    .mul(amountRemaining)
                    .div(assetValue)
            );
            liquidatorPayment = liquidatorPayment.add(amountRemaining);
            amountRemaining = 0;
        } else {
            notionalToTransfer = asset.notional;
            amountRemaining = amountRemaining - assetValue;
            liquidatorPayment = liquidatorPayment.add(assetValue);
        }
 
        return (liquidatorPayment, notionalToTransfer, amountRemaining);
    }

    /**
     * @notice A generic, internal function that trades positions within a portfolio.
     * @param account account that holds the portfolio to trade
     * @param currency the currency that the trades should be denominated in
     * @param amount of cash available
     * @param tradeType the assetType to trade in the portfolio
     */
    function _tradePortfolio(
        address account,
        uint16 currency,
        uint128 amount,
        bytes1 tradeType,
        Common.Asset[] memory portfolio
    ) internal returns (TradePortfolioState memory) {
        // Only Escrow can execute actions to trade the portfolio
        require(calledByEscrow(), "20");

        TradePortfolioState memory state = TradePortfolioState(
            amount,
            0,
            0,
            // At most we will add twice as many assets as the portfolio (this would be for liquidity token)
            // changes where we update both liquidity tokens as well as cash obligations.
            new Common.Asset[](portfolio.length * 2)
        );

        if (portfolio.length == 0) return state;

        // We initialize these cash groups here knowing that there is at least one asset in the portfolio
        uint8 cashGroupId = portfolio[0].cashGroupId;
        Common.CashGroup memory cg = cashGroups[cashGroupId];

        // Iterate over the portfolio and trade as required.
        for (uint256 i; i < portfolio.length; i++) {
            if (cashGroupId != portfolio[i].cashGroupId) {
                // Here the cash group has changed and therefore the fCash market has also
                // changed. We need to unlock cash from the previous fCash market.
                Escrow().unlockCurrentCash(currency, cg.cashMarket, state.unlockedCurrentCash);
                // Reset this counter for the next group
                state.unlockedCurrentCash = 0;

                // Fetch the new cash group.
                cashGroupId = portfolio[i].cashGroupId;
                cg = cashGroups[cashGroupId];
            }

            // This is an idiosyncratic fCash market and we cannot trade out of it
            if (cg.cashMarket == address(0)) continue;
            if (cg.currency != currency) continue;
            if (portfolio[i].assetType != tradeType) continue;

            if (Common.isCashPayer(portfolio[i].assetType)) {
                revert("7");
            } else if (Common.isLiquidityToken(portfolio[i].assetType)) {
                _tradeLiquidityToken(portfolio[i], cg.cashMarket, state);
            } else if (Common.isCashReceiver(portfolio[i].assetType)) {
                _tradeCashReceiver(account, portfolio[i], cg.cashMarket, state);
            }

            // No more cash left so we break out of the loop
            if (state.amountRemaining == 0) {
                break;
            }
        }

        if (state.unlockedCurrentCash != 0) {
            // Transfer cash from the last cash group in the previous loop
            Escrow().unlockCurrentCash(currency, cg.cashMarket, state.unlockedCurrentCash);
        }

        Common.Asset[] storage accountStorage = _accountAssets[account];
        for (uint256 i; i < state.indexCount; i++) {
            // This bypasses the free collateral check that we do not need to do here
            _upsertAsset(accountStorage, state.portfolioChanges[i], true);
        }

        return state;
    }

    /**
     * @notice Extracts cash from liquidity tokens.
     * @param asset the liquidity token to extract cash from
     * @param cashMarket the address of the fCash market
     * @param state state of the portfolio trade operation
     */
    function _tradeLiquidityToken(
        Common.Asset memory asset,
        address cashMarket,
        TradePortfolioState memory state
    ) internal {
        (uint128 cash, uint128 fCash, uint128 tokens) = CashMarket(cashMarket).tradeLiquidityToken(
            state.amountRemaining,
            asset.notional,
            asset.maturity
        );
        state.amountRemaining = state.amountRemaining.sub(cash);

        // This amount of cash has been removed from the market
        state.unlockedCurrentCash = state.unlockedCurrentCash.add(cash);

        // This is a CASH_RECEIVER that is credited back as a result of settling the liquidity token.
        state.portfolioChanges[state.indexCount] = Common.Asset(
            asset.cashGroupId,
            asset.instrumentId,
            asset.maturity,
            Common.getCashReceiver(),
            asset.rate,
            fCash
        );
        state.indexCount++;

        // This marks the removal of an amount of liquidity tokens
        state.portfolioChanges[state.indexCount] = Common.Asset(
            asset.cashGroupId,
            asset.instrumentId,
            asset.maturity,
            Common.makeCounterparty(Common.getLiquidityToken()),
            asset.rate,
            tokens
        );
        state.indexCount++;
    }

    /**
     * @notice Sells fCash in order to raise cash
     * @param account the account that holds the fCash
     * @param asset the fCash token to extract cash from
     * @param cashMarket the address of the fCash market
     * @param state state of the portfolio trade operation
     */
    function _tradeCashReceiver(
        address account,
        Common.Asset memory asset,
        address cashMarket,
        TradePortfolioState memory state
    ) internal {
        // This will sell off the entire amount of fCash and return cash
        uint128 cash = CashMarket(cashMarket).tradeCashReceiver(
            account,
            state.amountRemaining,
            asset.notional,
            asset.maturity
        );

        // Trade failed, do not update any state variables
        if (cash == 0) return;

        // This amount of cash has been removed from the market
        state.unlockedCurrentCash = state.unlockedCurrentCash.add(cash);
        state.amountRemaining = state.amountRemaining.sub(cash);

        // This is a CASH_PAYER that will offset the fCash in the portfolio, it will
        // always be the entire fCash amount.
        state.portfolioChanges[state.indexCount] = Common.Asset(
            asset.cashGroupId,
            asset.instrumentId,
            asset.maturity,
            Common.getCashPayer(),
            asset.rate,
            asset.notional
        );
        state.indexCount++;
    }

    /***** Liquidation Methods *****/

    /***** Internal Portfolio Methods *****/

    /**
     * @notice Returns the offset for a specific asset in an array of assets given a storage
     * pointer to a asset array. The parameters of this function define a unique id of
     * the asset.
     * @param portfolio storage pointer to the list of assets
     * @param assetType the type of asset to search for
     * @param cashGroupId the cash group id
     * @param instrumentId the instrument id
     * @param maturity maturity of the asset
     * @param findCounterparty find the counterparty of the asset
     *
     * @return (bool if found, index of asset, notional amount, is counterparty asset or not)
     */
    function _searchAsset(
        Common.Asset[] storage portfolio,
        bytes1 assetType,
        uint8 cashGroupId,
        uint16 instrumentId,
        uint32 maturity,
        bool findCounterparty
    ) internal view returns (bool, uint256, uint128, bool) {
        uint256 length = portfolio.length;
        if (length == 0) {
            return (false, length, 0, false);
        }

        for (uint256 i; i < length; i++) {
            Common.Asset storage t = portfolio[i];
            if (t.cashGroupId != cashGroupId) continue;
            if (t.instrumentId != instrumentId) continue;
            if (t.maturity != maturity) continue;

            bytes1 s = t.assetType;
            if (s == assetType) {
                return (true, i, t.notional, false);
            } else if (findCounterparty && s == Common.makeCounterparty(assetType)) {
                return (true, i, t.notional, true);
            }
        }

        return (false, length, 0, false);
    }

    /**
     * @notice Checks for the existence of a matching asset and then chooses update or append
     * as appropriate.
     * @param portfolio a list of assets
     * @param asset the new asset to add
     * @param liquidateAllowAdd allows liquidate function to continue to add assets to the portfolio
     */
    function _upsertAsset(
        Common.Asset[] storage portfolio,
        Common.Asset memory asset,
        bool liquidateAllowAdd
    ) internal {
        (bool found, uint256 index, uint128 notional, bool isCounterparty) = _searchAsset(
            portfolio,
            asset.assetType,
            asset.cashGroupId,
            asset.instrumentId,
            asset.maturity,
            true
        );

        if (!found) {
            // If not found then we append to the portfolio. We won't allow it to grow past the max assets parameter
            // except in the case of liquidating liquidity tokens. When doing so, we may need to add cash receiver tokens
            // back into the portfolio.
            require(index <= G_MAX_ASSETS || liquidateAllowAdd, "34");

            if (Common.isLiquidityToken(asset.assetType) && Common.isPayer(asset.assetType)) {
                // You cannot have a payer liquidity token without an existing liquidity token entry in
                // your portfolio since liquidity tokens must always have a positive balance.
                revert("8");
            }

            // Append the new asset
            portfolio.push(asset);
        } else if (!isCounterparty) {
            // If the asset types match, then just aggregate the notional amounts.
            portfolio[index].notional = notional.add(asset.notional);
        } else {
            if (notional >= asset.notional) {
                // We have enough notional of the asset to reduce or remove the asset.
                _reduceAsset(portfolio, portfolio[index], index, asset.notional);
            } else if (Common.isLiquidityToken(asset.assetType)) {
                // Liquidity tokens cannot go below zero.
                revert("8");
            } else if (Common.isCash(asset.assetType)) {
                // Otherwise, we need to flip the sign of the asset and set the notional amount
                // to the difference.
                portfolio[index].notional = asset.notional.sub(notional);
                portfolio[index].assetType = asset.assetType;
            }
        }
    }

    /**
     * @notice Reduces the notional of a asset by value, if value is equal to the total notional
     * then removes it from the portfolio.
     * @param portfolio a storage pointer to the account's assets
     * @param asset a storage pointer to the asset
     * @param index of the asset in the portfolio
     * @param value the amount of notional to reduce
     */
    function _reduceAsset(
        Common.Asset[] storage portfolio,
        Common.Asset storage asset,
        uint256 index,
        uint128 value
    ) internal {
        require(asset.assetType != 0x00, "7");
        require(asset.notional >= value, "8");

        if (asset.notional == value) {
            _removeAsset(portfolio, index);
        } else {
            // We did the check above that will prevent an underflow here
            asset.notional = asset.notional - value;
        }
    }

    /**
     * @notice Removes a asset from a portfolio, used when assets are transferred by _reduceAsset
     * or when they are settled.
     * @param portfolio a storage pointer to the assets
     * @param index the index of the asset to remove
     */
    function _removeAsset(Common.Asset[] storage portfolio, uint256 index) internal {
        uint256 lastIndex = portfolio.length - 1;
        if (index != lastIndex) {
            Common.Asset memory lastAsset = portfolio[lastIndex];
            portfolio[index] = lastAsset;
        }
        portfolio.pop();
    }
}