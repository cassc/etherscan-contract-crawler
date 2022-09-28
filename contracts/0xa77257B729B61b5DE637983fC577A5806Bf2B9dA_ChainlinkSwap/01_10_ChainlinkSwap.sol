// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;
import "./BaseSwap.sol";

contract ChainlinkSwap is BaseSwap {

    /// @param _commodityToken the commodity token
    /// @param _stableToken the stable token
    /// @param _commdexName Name for the dex
    /// @param _tradeFee Fee per swap
    /// @param _commodityChainlinkAddress chainlink price feed address for commodity
    /// @param _dexAdmin Comm-dex admin 
    constructor(
        address _commodityToken,
        address _stableToken,
        string memory _commdexName,
        uint256 _tradeFee,
        address _commodityChainlinkAddress,
        address _dexAdmin,
        uint256 _unitMultiplier,
        address _stableToUSDPriceFeed
    ) {
        require(
            _dexAdmin != address(0),
            "Invalid address"
        );
        require(_unitMultiplier > 0, "Invalid _unitMultiplier");
        dexData.commodityToken = _commodityToken;
        dexData.stableToken = _stableToken;
        dexSettings.comdexName = _commdexName;
        dexSettings.tradeFee = _tradeFee;
        dexSettings.dexAdmin = _dexAdmin;
        dexSettings.unitMultiplier = _unitMultiplier; 
        dexSettings.stableToUSDPriceFeed = _stableToUSDPriceFeed;

        priceFeed = AggregatorV3Interface(_commodityChainlinkAddress);
        stableTokenPriceFeed = AggregatorV3Interface(_stableToUSDPriceFeed);
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
            uint256 stableAmount = (commodityAmount * getChainLinkFeedPrice()) / (10**8);
            stableAmount = convertUSDToStable(stableAmount);
            stableAmount = SwapLib.normalizeAmount(stableAmount, _from, _to);

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
            uint commodityUnitPrice = convertUSDToStable(getChainLinkFeedPrice());
            uint256 commodityAmount = (stableAmount * (10**8)) / commodityUnitPrice;
            commodityAmount = SwapLib.normalizeAmount(commodityAmount, _from, _to);

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
        uint amount = (commodityAmount * convertUSDToStable(getChainLinkFeedPrice())) / (10**8);
        require(
            SwapLib.normalizeAmount(amount,dexData.commodityToken, dexData.stableToken) == stableAmount,
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
        uint amount = (commodityAmount * convertUSDToStable(getChainLinkFeedPrice())) / (10**8);
        require(
            SwapLib.normalizeAmount(amount, dexData.commodityToken, dexData.stableToken) == stableAmount,
            "commodityAmount should be equal"
        );
        super._removeLiquidity(commodityAmount, stableAmount);
    }
}