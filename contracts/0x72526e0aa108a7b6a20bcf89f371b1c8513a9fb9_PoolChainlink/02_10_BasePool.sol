// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../utils/TransferHelper.sol";
import "../interfaces/IPool.sol";
import "./../interfaces/IERC20.sol";

import {SwapLib} from "../lib/Lib.sol";

abstract contract BasePool is Ownable, IPool, Pausable {
    //state variable for dex data reserves, tokens etc check ../lib/Lib.sol
    SwapLib.DexData public dexData;

    //name, fee, timeout etc check ../lib/Lib.sol
    SwapLib.DexSetting public dexSettings;

    //to convert USD value to stable token amount
    SwapLib.FeedInfo public stableFeedInfo;

    modifier onlyComdexAdmin() {
        _onlyCommdexAdmin();
        _;
    }

    function _onlyCommdexAdmin() internal view {
        require(
            msg.sender == dexSettings.dexAdmin,
            "BP: caller not pool admin"
        );
    }

    constructor(
        address _commodityToken,
        address _stableToken,
        SwapLib.DexSetting memory _dexSettings
    ) {
        //note: no hard cap on upper limit because units can be any generic conversion
        require(_dexSettings.unitMultiplier > 0, "BP: Invalid _unitMultiplier");
        SwapLib._checkNullAddress(_dexSettings.dexAdmin);
        SwapLib._checkFee(_dexSettings.tradeFee);
        SwapLib._checkNullAddress(_commodityToken);
        SwapLib._checkNullAddress(_stableToken);
        SwapLib._checkRateTimeout(_dexSettings.rateTimeOut);
        dexData.commodityToken = _commodityToken;
        dexData.stableToken = _stableToken;
        //maximum allowed value for difference is 10% could be as low as 0 (1000 = 10.00 %)
        require(
            _dexSettings.sellSpotDifference <= 1000 &&
                _dexSettings.buySpotDifference <= 1000,
            "BP: invalid spot difference"
        );
        dexSettings = _dexSettings;
    }

    /// @notice Adds liquidity for both assets
    /// @param commodityAmount amount of tokens for commodity asset
    /// @param stableAmount amount of tokens for stable asset
    function _addLiquidity(uint256 commodityAmount, uint256 stableAmount)
        internal
    {
        dexData.reserveCommodity = dexData.reserveCommodity + commodityAmount;
        dexData.reserveStable = dexData.reserveStable + stableAmount;
        emit LiquidityAdded(_msgSender(), commodityAmount, stableAmount);
        TransferHelper.safeTransferFrom(
            dexData.commodityToken,
            msg.sender,
            address(this),
            commodityAmount
        );
        TransferHelper.safeTransferFrom(
            dexData.stableToken,
            msg.sender,
            address(this),
            stableAmount
        );
    }

    /// @notice Removes liquidity for both assets
    /// @param commodityAmount amount of tokens for commodity asset
    /// @param stableAmount amount of tokens for stable asset
    function _removeLiquidity(uint256 commodityAmount, uint256 stableAmount)
        internal
    {
        dexData.reserveCommodity = dexData.reserveCommodity - commodityAmount;
        dexData.reserveStable = dexData.reserveStable - stableAmount;
        emit LiquidityRemoved(_msgSender(), commodityAmount, stableAmount);
        TransferHelper.safeTransfer(
            dexData.commodityToken,
            _msgSender(),
            commodityAmount
        );
        TransferHelper.safeTransfer(
            dexData.stableToken,
            _msgSender(),
            stableAmount
        );
    }

    /// @notice Allows to set trade fee for swap
    /// @param _newTradeFee updated trade fee should be <= 10 ** 8
    function setTradeFee(uint256 _newTradeFee) external onlyComdexAdmin {
        SwapLib._checkFee(_newTradeFee);
        dexSettings.tradeFee = _newTradeFee;
        emit TradeFeeChanged(_newTradeFee);
    }

    /// @dev Allows comm-dex admin to withdraw fee
    function withdrawFee() external onlyComdexAdmin {
        //transfer fee to dexAdmin
        _withdrawFee();
        //reset states
        _resetFees();
        //emit event
        emit FeeWithdraw(
            msg.sender,
            dexData.totalFeeCommodity,
            dexData.totalFeeStable
        );
    }

    /// @notice Allows comm-dex admin to set new comm-dex admin
    /// @param _updatedAdmin the new admin
    function setCommdexAdmin(address _updatedAdmin) external onlyComdexAdmin {
        require(
            _updatedAdmin != address(0) &&
                _updatedAdmin != dexSettings.dexAdmin,
            "BP: invalid address"
        );
        dexSettings.dexAdmin = _updatedAdmin;
        emit ComDexAdminChanged(_updatedAdmin);
    }

    /// @notice allows owner to withdraw reserves in case of emergency
    function emergencyWithdraw() external onlyOwner {
        //transfe the
        _withDrawReserve();
        _resetReserves();
        emit EmergencyWithdraw(
            msg.sender,
            dexData.reserveCommodity,
            dexData.reserveStable
        );
    }

    /// @notice Allows comm-dex admin to self-destruct pool, sends reserves to pool owner and fee to comm-dex admin
    function withDrawAndDestory(address _to) external onlyComdexAdmin {
        SwapLib._checkNullAddress(_to);
        // send reserves to pool owner
        _withDrawReserve();
        // send fee to admin fees
        _withdrawFee();
        emit withDrawAndDestroyed(
            msg.sender,
            dexData.reserveCommodity,
            dexData.reserveStable,
            dexData.totalFeeCommodity,
            dexData.totalFeeStable
        );

        selfdestruct(payable(_to));
    }

    ///@dev pass a usd value to convert it to number of stable tokens against it
    function _convertUSDToStable(uint256 _amount)
        internal
        view
        returns (uint256)
    {
        (
            ,
            // uint80 roundID
            int256 price, // uint answer // startedAt
            ,
            uint256 updatedAt, // updatedAt

        ) = stableFeedInfo.priceFeed.latestRoundData();
        require(price > 0, "BP: stable price error");
        //check if updated rate is expired
        require(!_isStableFeedTimeout(updatedAt), "BP: stable price expired");
        // e.g.
        // price USD = 1 USDT
        // 1 USD = (1 USDT / price USD)USDT
        // (amount  * priceFeed.decimals() / price USD) USDT = amount USDT
        return
            (_amount * 10**stableFeedInfo.priceFeed.decimals()) /
            uint256(price);
    }

    ///@dev returns true if the stable feed updated price is over its heartbeat
    function _isStableFeedTimeout(uint256 _updatedAt)
        internal
        view
        returns (bool)
    {
        if (block.timestamp - _updatedAt < stableFeedInfo.heartbeat)
            return false;
        //under 3 minutes is not a timeout
        else return true;
    }

    function _withdrawFee() internal {
        address dexAdmin = dexSettings.dexAdmin;

        TransferHelper.safeTransfer(
            dexData.commodityToken,
            dexAdmin,
            dexData.totalFeeCommodity
        );
        TransferHelper.safeTransfer(
            dexData.stableToken,
            dexAdmin,
            dexData.totalFeeStable
        );
    }

    function _withDrawReserve() internal {
        address dexOwner = owner();
        TransferHelper.safeTransfer(
            dexData.commodityToken,
            dexOwner,
            dexData.reserveCommodity
        );
        TransferHelper.safeTransfer(
            dexData.stableToken,
            dexOwner,
            dexData.reserveStable
        );
    }

    function _resetReserves() internal {
        dexData.reserveCommodity = 0;
        dexData.reserveStable = 0;
    }

    function _resetFees() internal {
        dexData.totalFeeCommodity = 0;
        dexData.totalFeeStable = 0;
    }

    /// @notice Allows comm-dex-admin to pause the Swap function

    function unpause() external onlyComdexAdmin {
        _unpause();
    }

    /// @notice Allows comm-dex-admin to un-pause the Swap function

    function pause() external onlyComdexAdmin {
        _pause();
    }

    /// @notice Allows pool owner to update unitMultiplier
    /// @param _unitMultiplier new unitMultiplier
    function updateUnitMultiplier(uint256 _unitMultiplier) external onlyOwner {
        require(_unitMultiplier > 0, "BP: Invalid _unitMultiplier");
        dexSettings.unitMultiplier = _unitMultiplier;
        emit UnitMultiplierUpdated(_unitMultiplier);
    }

    /// @notice Allows comm-dex-admin to update buySpotDifference
    /// @param _newDifference new buySpotDifference
    function updateBuySpotDifference(uint256 _newDifference)
        external
        onlyComdexAdmin
    {
        //maximum allowed value for difference is 10% could be as low as 0 (1000 = 10.00 %)
        require(
            _newDifference <= 1000,
            "BP: invalid spot difference"
        );
        dexSettings.buySpotDifference = _newDifference;
        emit BuySpotDifferenceUpdated(_newDifference);
    }

    /// @notice Allows comm-dex-admin to update sellSpotDifference
    /// @param _newDifference new sellSpotDifference
    function updateSellSpotDifference(uint256 _newDifference)
        external
        onlyComdexAdmin
    {

        //maximum allowed value for difference is 10% could be as low as 0 (1000 = 10.00 %)
        require(
            _newDifference <= 1000,
            "BP: invalid spot difference"
        );
        dexSettings.sellSpotDifference = _newDifference;
        emit SellSpotDifferenceUpdated(_newDifference);
    }

    /// @dev get maximum allowed amount out and minimum allowed amount out for given expected amount out and slippage values
    /// @param _expectedAmountOut expected amount of output tokens at the time of quote
    /// @param _slippage slippage tolerance in percentage 0.00 % - 5.00 %
    /// @param _amountOut calculated amountOut in this tx
    function verifySlippageTolerance(
        uint256 _expectedAmountOut,
        uint256 _slippage,
        uint256 _amountOut
    ) public pure {
        //slippage value max 5% = 0 -> 500
        require(_slippage <= 500, "BP: invalid slippage");
        require(_expectedAmountOut > 0, "BP: invalid expected amount");
        //allowed minimum amount out for this tx
        uint256 minAmountOut = _expectedAmountOut -
            ((_expectedAmountOut * _slippage) / 10000); // 2 slippage decimals
        //allowed maximum amount out for this tx
        uint256 maxAmountOut = _expectedAmountOut +
            ((_expectedAmountOut * _slippage) / 10000); // 2 slippage decimals
        //verify slippage _amountOut > minimumAmountOut &&  _amountOut < maximumAmountOut &&
        require(
            _amountOut >= minAmountOut && _amountOut <= maxAmountOut,
            "BP: slippage high"
        );
    }
}