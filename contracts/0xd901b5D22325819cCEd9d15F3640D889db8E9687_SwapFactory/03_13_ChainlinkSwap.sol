// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;
import "./BaseSwap.sol";

contract ChainlinkSwap is BaseSwap {

    /// @param _commodityToken the commodity token
    /// @param _stableToken the stable token
    /// @param _commodityChainlinkAddress chainlink price feed address for commodity
    /// @param _newDexSettings dexsettings 
    constructor(
        address _commodityToken,
        address _stableToken,
        address _commodityChainlinkAddress,
        SwapLib.DexSetting memory _newDexSettings
    ) {
        require(
            _newDexSettings.dexAdmin != address(0),
            "Invalid address"
        );
        require(_newDexSettings.unitMultiplier > 0, "Invalid _unitMultiplier");
        dexData.commodityToken = _commodityToken;
        dexData.stableToken = _stableToken;
        dexSettings.comdexName = _newDexSettings.comdexName;
        dexSettings.tradeFee = _newDexSettings.tradeFee;
        dexSettings.dexAdmin = _newDexSettings.dexAdmin;
        dexSettings.unitMultiplier = _newDexSettings.unitMultiplier; 
        dexSettings.stableToUSDPriceFeed = _newDexSettings.stableToUSDPriceFeed;
        dexSettings.buySpotDifference = _newDexSettings.buySpotDifference;
        dexSettings.sellSpotDifference = _newDexSettings.sellSpotDifference;

        priceFeed = AggregatorV3Interface(_commodityChainlinkAddress);
        stableTokenPriceFeed = AggregatorV3Interface(_newDexSettings.stableToUSDPriceFeed);
    }

    /// @notice Allows Swaps from commodity token to another token and vice versa,
    /// @param _amountIn Amount of tokens user want to give for swap (in decimals of _from token)
    /// @param _from token that user wants to spend
    /// @param _to token that user wants in result of swap

    function swap(
        uint256 _amountIn,
        address _from,
        address _to
    ) external virtual whenNotPaused {
        require(_amountIn > 0, "wrong amount");
        require(
            (_from == dexData.commodityToken && _to == dexData.stableToken) ||
                (_to == dexData.commodityToken && _from == dexData.stableToken),
            "wrong pair"
        );

        uint256 amountFee = (_amountIn * dexSettings.tradeFee) / (10**10); // 8 decimals for fee, 100 for percentage

        if (_from == dexData.commodityToken) {
            uint256 commodityAmount = _amountIn - amountFee;
            uint256 stableAmount = getAmountOut(commodityAmount, false);
            if (dexData.reserveStable < stableAmount)
                emit LowstableTokenalance(dexData.stableToken, dexData.reserveStable);
            require(dexData.reserveStable >= stableAmount, "not enough liquidity");
            
            TransferHelper.safeTransferFrom(
                dexData.commodityToken,
                msg.sender,
                address(this),
                _amountIn
            );
            TransferHelper.safeTransfer(dexData.stableToken, msg.sender, stableAmount);

            dexData.reserveCommodity = dexData.reserveCommodity + commodityAmount;
            dexData.reserveStable = dexData.reserveStable - stableAmount;
            dexData.totalFeeCommodity = dexData.totalFeeCommodity + amountFee;
            emit Swapped(msg.sender, _amountIn, stableAmount, SwapLib.SELL_INDEX);
        } else {
            uint256 stableAmount = _amountIn - amountFee;
            uint256 commodityAmount = getAmountOut(stableAmount, true);

            if (dexData.reserveCommodity < commodityAmount)
                emit LowstableTokenalance(dexData.commodityToken, dexData.reserveCommodity);
            require(dexData.reserveCommodity >= commodityAmount, "not enough liquidity");

            TransferHelper.safeTransferFrom(
                dexData.stableToken,
                msg.sender,
                address(this),
                _amountIn
            );
            TransferHelper.safeTransfer(dexData.commodityToken, msg.sender, commodityAmount);

            dexData.reserveCommodity = dexData.reserveCommodity - commodityAmount;
            dexData.reserveStable = dexData.reserveStable + stableAmount;
            dexData.totalFeeStable = dexData.totalFeeStable + amountFee;
            emit Swapped(msg.sender, _amountIn, commodityAmount, SwapLib.BUY_INDEX);
        }
    }


    /// @notice adds liquidity for both assets
    /// @dev stableAmount should be = commodityAmount * price
    /// @param commodityAmount amount of tokens for commodity asset
    /// @param stableAmount amount of tokens for stable asset

    function addLiquidity(uint256 commodityAmount, uint256 stableAmount)
        external
        virtual
        onlyOwner
    {
        uint amount = getAmountOut(commodityAmount, false);
        require(
            amount == stableAmount,
            "amounts should be equal"
        );
        super._addLiquidity(commodityAmount, stableAmount);
    }

    /// @notice removes liquidity for both assets
    /// @dev stableAmount should be = commodityAmount * price
    /// @param commodityAmount amount of tokens for commodity asset
    /// @param stableAmount amount of tokens for stable asset

    function removeLiquidity(uint256 commodityAmount, uint256 stableAmount)
        external
        virtual
        onlyOwner
    {
        uint amount = getAmountOut(commodityAmount, false);//false flag to get sell price
        require(
            amount == stableAmount,
            "commodityAmount should be equal"
        );
        super._removeLiquidity(commodityAmount, stableAmount);
    }

    function getAmountOut(uint256 _amountIn, bool flag) public view returns(uint256){
        if(flag){//buy price for 1 unit of commdotiy token
            uint commodityUnitPrice = convertUSDToStable(getChainLinkFeedPrice());
            commodityUnitPrice = commodityUnitPrice + ((commodityUnitPrice * dexSettings.buySpotDifference) / 10000) ; // adding 1.12% from spot price
            uint256 commodityAmount = (_amountIn * (10**8)) / commodityUnitPrice;
            commodityAmount = SwapLib.normalizeAmount(commodityAmount, dexData.stableToken, dexData.commodityToken);
            return commodityAmount;
        }
        else{//sell price for 1 unit of commodity token
            uint256 stableAmount = (_amountIn * getChainLinkFeedPrice()) / (10**8);
            stableAmount = convertUSDToStable(stableAmount);
            stableAmount = stableAmount - ((stableAmount * dexSettings.sellSpotDifference)/(10000)); // deducting 1.04% out of spot price
            stableAmount = SwapLib.normalizeAmount(stableAmount, dexData.commodityToken, dexData.stableToken);
            return stableAmount;
        }
    }
}