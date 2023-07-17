// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;
import "./BasePool.sol";

contract PoolChainlink is BasePool {
    SwapLib.FeedInfo public commodityFeedInfo;

    /// @param _commodityToken the commodity token
    /// @param _stableToken the stable token
    /// @param _dexSettings dexsettings
    /// @param _stableFeedInfo chainlink price feed address and heartbeats
    /// @param _commodityFeedInfo chainlink price feed address and heartbeats
    constructor(
        address _commodityToken,
        address _stableToken,
        SwapLib.DexSetting memory _dexSettings,
        SwapLib.FeedInfo memory _commodityFeedInfo,
        SwapLib.FeedInfo memory _stableFeedInfo
    ) BasePool(_commodityToken, _stableToken, _dexSettings) {
        //set price feeds
        _setFeedSetting(_commodityFeedInfo, _stableFeedInfo);
    }

    /// @notice Allows Swaps from commodity token to another token and vice versa,
    /// @param _amountIn Amount of tokens user want to give for swap (in decimals of _from token)
    /// @param _expectedAmountOut expected amount of output tokens at the time of quote
    /// @param _slippage slippage tolerance in percentage (2 decimals)
    /// @param _from token that user wants to spend
    /// @param _to token that user wants in result of swap
    function swap(
        uint256 _amountIn,
        uint256 _expectedAmountOut,
        uint256 _slippage,
        address _from,
        address _to
    ) external virtual whenNotPaused {
        //invalid amount check
        require(_amountIn > 0, "PC: wrong amount");
        //tokens check
        require(
            (_from == dexData.commodityToken && _to == dexData.stableToken) ||
                (_to == dexData.commodityToken && _from == dexData.stableToken),
            "PC: wrong pair"
        );
        //calculating fee as percentage of amount passed
        uint256 amountFee = (_amountIn * dexSettings.tradeFee) / (10**10); // 8 decimals for fee, 100 for percentage

        //start sell case
        if (_from == dexData.commodityToken) {
            //commodity -> stable conversion
            //deducting fee
            uint256 commodityAmount = _amountIn - amountFee;
            //getting latest price for given amount
            //false indicates commodity being sold
            uint256 stableAmount = getAmountOut(
                commodityAmount,
                SwapLib.SELL_INDEX
            );

            //cant go ahead if no liquidity
            require(
                dexData.reserveStable >= stableAmount,
                "PC: not enough liquidity"
            );
            //verify slippage stableAmount > minimumAmountOut &&  stableAmount < maximumAmountOut
            verifySlippageTolerance(
                _expectedAmountOut,
                _slippage,
                stableAmount
            );

            //increase commodity reserve
            dexData.reserveCommodity =
                dexData.reserveCommodity +
                commodityAmount;
            //decrease stable reserve
            dexData.reserveStable = dexData.reserveStable - stableAmount;
            //add fee
            dexData.totalFeeCommodity = dexData.totalFeeCommodity + amountFee;
            //emit swap event
            emit Swapped(
                msg.sender,
                _amountIn,
                stableAmount,
                SwapLib.SELL_INDEX
            );

            // All state updates for swap should come before calling the
            // See: https://solidity.readthedocs.io/en/develop/security-considerations.html#use-the-checks-effects-interactions-pattern

            //transfer the commodity tokens to the contract
            TransferHelper.safeTransferFrom(
                dexData.commodityToken,
                msg.sender,
                address(this),
                _amountIn
            );
            //transfer the stable amount to the user
            TransferHelper.safeTransfer(
                dexData.stableToken,
                msg.sender,
                stableAmount
            );
        } else {
            //deduct calculated fee
            uint256 stableAmount = _amountIn - amountFee;
            //get number of commodity tokens to buy against stable amount passed
            uint256 commodityAmount = getAmountOut(
                stableAmount,
                SwapLib.BUY_INDEX
            );
            //revert on low reserves
            require(
                dexData.reserveCommodity >= commodityAmount,
                "PC: not enough liquidity"
            );

            //verify slippage commodityAmount > minimumAmountOut &&  stableAmount < maximumAmountOut
            verifySlippageTolerance(
                _expectedAmountOut,
                _slippage,
                commodityAmount
            );

            //decrease commodity reserve
            dexData.reserveCommodity =
                dexData.reserveCommodity -
                commodityAmount;
            //increase stable reserve
            dexData.reserveStable = dexData.reserveStable + stableAmount;
            //add stable fee
            dexData.totalFeeStable = dexData.totalFeeStable + amountFee;
            //emit swap event
            emit Swapped(
                msg.sender,
                _amountIn,
                commodityAmount,
                SwapLib.BUY_INDEX
            );
            // All state updates for swap should come before calling the
            // See: https://solidity.readthedocs.io/en/develop/security-considerations.html#use-the-checks-effects-interactions-pattern

            //transfer stale amountt from user to contract
            TransferHelper.safeTransferFrom(
                dexData.stableToken,
                msg.sender,
                address(this),
                _amountIn
            );
            //transfer commodity amount from contract to user
            TransferHelper.safeTransfer(
                dexData.commodityToken,
                msg.sender,
                commodityAmount
            );
        }
    }

    /// @notice Allows pool owner to add liquidity for both assets
    /// @param _commodityAmount amount of tokens for commodity asset
    /// @param _stableAmount amount of tokens for stable asset
    /// @param _slippage slippage tolerance in percentage (2 decimals)
    function addLiquidity(
        uint256 _commodityAmount,
        uint256 _stableAmount,
        uint256 _slippage
    ) external virtual onlyOwner {
        //calculating amount of stable against commodity amount
        uint256 amount = getAmountOut(_commodityAmount, SwapLib.SELL_INDEX); //deliberate use of false flag to get sell price
        //verify slippage amount > minimumAmountOut &&  amount < maximumAmountOut
        verifySlippageTolerance(_stableAmount, _slippage, amount);
        super._addLiquidity(_commodityAmount, amount);
    }

    /// @notice Allows pool owner to remove liquidity for both assets
    /// @param _commodityAmount amount of tokens for commodity asset
    /// @param _stableAmount amount of tokens for stable asset
    /// @param _slippage slippage tolerance in percentage (2 decimals)
    function removeLiquidity(
        uint256 _commodityAmount,
        uint256 _stableAmount,
        uint256 _slippage
    ) external virtual onlyOwner {
        //calculating amount of stable against commodity amount
        uint256 amount = getAmountOut(_commodityAmount, SwapLib.SELL_INDEX); //deliberate use of false flag to get sell price
        //verify slippage amount > minimumAmountOut &&  amount < maximumAmountOut &&
        verifySlippageTolerance(_stableAmount, _slippage, amount);
        super._removeLiquidity(_commodityAmount, amount);
    }

    ///@dev returns the amonutOut for given amount in if true flag
    ///@param _amountIn the amount of tokens to exchange
    ///@param _index 0 = buy price returns amount commodity for stable _amountIn,
    ///              1 = for sell price
    function getAmountOut(uint256 _amountIn, uint256 _index)
        public
        view
        returns (uint256)
    {
        //calculating commodity amount against stable tokens passed
        //1 Commodity Token = ? Stable tokens
        uint256 commodityUnitPriceUsd = getCommodityPrice();//price returned as USD is converted into respective stable token amount
        uint256 commodityUnitPriceStable = _convertUSDToStable(commodityUnitPriceUsd);

        if (_index == SwapLib.BUY_INDEX) {

            //adding spot price difference to unit price in terms of percentage of the unit price itself
            //e.g. buySpotDifference = 110 = 1.1% and commodityUnitPrice = 50 StableTokens
            //result will be 50+(1.1% of 50) = 50.55
            commodityUnitPriceStable =
                commodityUnitPriceStable +
                ((commodityUnitPriceStable * dexSettings.buySpotDifference) / 10000); // adding % from spot price

            // commodityAmount = amount of stable tokens / commodity unit price in stable
            uint256 commodityAmount = (_amountIn *
                (10**commodityFeedInfo.priceFeed.decimals())) /
                commodityUnitPriceStable;

            //convert to commodity decimals as amount is in stable decimals
            return
                SwapLib._normalizeAmount(
                    commodityAmount,
                    dexData.stableToken,
                    dexData.commodityToken
                );
        } else {
            // calculating stable amount against commodity tokens passed
            // getCommodityPrice returns 1 commodity in USD / its decimals
            // _convertUSDToStable converts dollar value to stable token amount
            // total stable amount  = amount of commodity tokens * 1 commodity price in stable token
            uint256 stableAmount = (_amountIn *
                commodityUnitPriceStable) /
                10**stableFeedInfo.priceFeed.decimals();

            //subtracting sell spot difference
            //e.g. sellSpotDifference = 110 = 1.1% and commodityUnitPrice = 50 StableTokens
            //result will be 50-(1.1% of 50) = 49.45
            stableAmount =
                stableAmount -
                ((stableAmount * dexSettings.sellSpotDifference) / (10000)); // deducting 1.04% out of spot price
            //convert to stable decimal as amount is in commodity decimals
            return
                SwapLib._normalizeAmount(
                    stableAmount,
                    dexData.commodityToken,
                    dexData.stableToken
                );
        }
    }

    /// @notice Allows to set Chainlink feed address
    /// @param _stableFeedInfo chainlink price feed addresses and heartbeats
    /// @param _commodityFeedInfo chainlink price feed addresses and heartbeats
    function setFeedSetting(
        SwapLib.FeedInfo memory _commodityFeedInfo,
        SwapLib.FeedInfo memory _stableFeedInfo
    ) external onlyComdexAdmin {
        _setFeedSetting(_commodityFeedInfo, _stableFeedInfo);
    }

    /// @dev internal function to set chainlink feed settings
    function _setFeedSetting(
        SwapLib.FeedInfo memory _commodityFeedInfo,
        SwapLib.FeedInfo memory _stableFeedInfo
    ) internal {
        require(
            _commodityFeedInfo.heartbeat > 10 &&
                _commodityFeedInfo.heartbeat <= 86400, // 10 seconds to 24 hrs
            "PC: invalid heartbeat commodity"
        );
        require(
            _stableFeedInfo.heartbeat > 10 &&
                _stableFeedInfo.heartbeat <= 86400, // 10 seconds to 24 hrs
            "PC: invalid heartbeat stable"
        );

        commodityFeedInfo = _commodityFeedInfo;
        //try to hit price to check if commodity feed is valid
        uint256 commodityUnitPrice = getCommodityPrice();

        stableFeedInfo = _stableFeedInfo;
        //try to hit price FOR ARBITRARY VALUE to check if stable feed is valid
        _convertUSDToStable(commodityUnitPrice);

        emit FeedAddressesChanged(
            address(_commodityFeedInfo.priceFeed),
            address(_stableFeedInfo.priceFeed)
        );
    }

    ///@dev returns the price of 1 unit of commodity from chainlink feed configured
    function getCommodityPrice() internal view returns (uint256) {
        (
            ,
            // uint80 roundID
            int256 price, // uint answer // startedAt
            ,
            uint256 updatedAt, // updatedAt

        ) = commodityFeedInfo.priceFeed.latestRoundData();
        require(price > 0, "BP: chainLink price error");
        require(
            !_isCommodityFeedTimeout(updatedAt),
            "BP: commodity price expired"
        );
        return (uint256(price) * dexSettings.unitMultiplier) / (10**18); // converting feed price unit into token commodity units e.g 1 gram = 1000mg
    }

    ///@dev returns true if the commodity feed updated price is over heartbeat value
    function _isCommodityFeedTimeout(uint256 _updatedAt)
        internal
        view
        returns (bool)
    {
        //under heartbeat is not a timeout
        if (block.timestamp - _updatedAt < commodityFeedInfo.heartbeat)
            return false;
        else return true;
    }
}