// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../utils/TransferHelper.sol";
import "../interfaces/ISwap.sol";
import "./../utils/Pausable.sol";
import "./../interfaces/IERC20.sol";

import {SwapLib} from "../lib/Lib.sol";

abstract contract BaseSwap is Ownable, ISwap, Pausable {
    using SwapLib for *;

    SwapLib.DexData public dexData;
    SwapLib.DexSetting public dexSettings;
    AggregatorV3Interface internal priceFeed;
    AggregatorV3Interface internal stableTokenPriceFeed;
    // uint256 public unitMultiplier; // will be used to convert feed price units to token price units

    modifier onlyComdexAdmin() {
        _onlyCommdexOwner();
        _;
    }

    function _onlyCommdexOwner() internal view{
       require(
            msg.sender == dexSettings.dexAdmin,
            "Caller is not comm-dex owner"
        );
    }

    /// @notice Adds liquidity for both assets
    /// @param commodityAmount amount of tokens for commodity asset
    /// @param stableAmount amount of tokens for stable asset

    function _addLiquidity(uint256 commodityAmount, uint256 stableAmount) internal {
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
        dexData.reserveCommodity = dexData.reserveCommodity + commodityAmount;
        dexData.reserveStable = dexData.reserveStable + stableAmount;
        emit LiquidityAdded(_msgSender(), commodityAmount, stableAmount);
    }

    /// @notice Removes liquidity for both assets
    /// @param commodityAmount amount of tokens for commodity asset
    /// @param stableAmount amount of tokens for stable asset

    function _removeLiquidity(uint256 commodityAmount, uint256 stableAmount) internal {
        TransferHelper.safeTransfer(dexData.commodityToken, _msgSender(), commodityAmount);
        TransferHelper.safeTransfer(dexData.stableToken, _msgSender(), stableAmount);
        dexData.reserveCommodity = dexData.reserveCommodity - commodityAmount;
        dexData.reserveStable = dexData.reserveStable - stableAmount;
        emit LiquidityRemoved(_msgSender(), commodityAmount, stableAmount);
    }

    /// @notice Allows to set trade fee for swap
    /// @param _newTradeFee updated trade fee, should be < 10 ** 8


    function setTradeFee(uint256 _newTradeFee) external onlyComdexAdmin {
        require(_newTradeFee < 10**8, "Wrong Fee!");
        dexSettings.tradeFee = _newTradeFee;
        emit TradeFeeChanged(_newTradeFee);
    }

    /// @notice Allows comm-dex admin to withdraw fee

    function withdrawFee() external onlyComdexAdmin {

        withdrawFeeHelper();

        emit FeeWithdraw(
            msg.sender,
            dexData.totalFeeCommodity,
            dexData.totalFeeStable
        );

        resetFees();
    }

    /// @notice Allows to set Chainlink feed address
    /// @param _chainlinkPriceFeed the updated chainlink price feed address

    function setChainlinkFeedAddress(address _chainlinkPriceFeed)
        external
        onlyComdexAdmin
    {
        priceFeed = AggregatorV3Interface(_chainlinkPriceFeed);
        emit ChainlinkFeedAddressChanged(_chainlinkPriceFeed);
    }

    /// @notice Allows to set comm-dex admin
    /// @param _updatedAdmin the new admin

    function setCommdexAdmin(address _updatedAdmin) external onlyComdexAdmin {
        require(
            _updatedAdmin != address(0) &&
                _updatedAdmin != dexSettings.dexAdmin,
            "Invalid Address"
        );
        dexSettings.dexAdmin = _updatedAdmin;
        emit ComDexAdminChanged(_updatedAdmin);
    }

    /// @notice allows Swap admin to withdraw reserves in case of emergency

    function emergencyWithdraw() external onlyOwner {

        withDrawReserveHelper();

        emit EmergencyWithdrawComplete(
            msg.sender,
            dexData.reserveCommodity,
            dexData.reserveStable
        );

        resetReserves();
    }

    /// @notice Allows comm-dex admin to empty dex, sends reserves to comm-dex admin and fee to comm-dex admin

    function withDrawAndDestory(address _to) external onlyComdexAdmin {

        // withdraw the reserves
        withDrawReserveHelper();
        // withdraw fees
        withdrawFeeHelper();

        emit withDrawAndDestroyed(
            msg.sender,
            dexData.reserveCommodity,
            dexData.reserveStable,
            dexData.totalFeeCommodity,
            dexData.totalFeeStable
        );

        selfdestruct(payable(_to));
    }

    function getChainLinkFeedPrice() internal view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        require(price >= 0, "ChainLink price error");

        return (uint256(price) * dexSettings.unitMultiplier) / (10**18); // converting feed price unit into token commodity units e.g 1 gram = 1000mg
    }

    function convertUSDToStable(uint _amount) internal view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = stableTokenPriceFeed.latestRoundData();
        require(price >= 0, "ChainLink price error");

        return ((_amount * (1* (10**(8+5)) / uint256(price))))/ (10**5) ; // supporting 5 decimals on USD values
    }

    function withdrawFeeHelper() internal{
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

    function withDrawReserveHelper() internal {
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

    function resetReserves() internal{
        dexData.reserveCommodity = 0;
        dexData.reserveStable = 0;
    }

    function resetFees() internal {
        dexData.totalFeeCommodity = 0;
        dexData.totalFeeStable = 0;
    }

    /// @notice pauses the Swap function

    function unpause() external onlyComdexAdmin {
        _unpause();
    }

    /// @notice unpause the Swap function

    function pause() external onlyComdexAdmin{
        _pause();
    }

    function updateUnitMultiplier(uint _unitMultiplier) external onlyOwner{
        require(_unitMultiplier > 0 , "Invalid  _unitMultiplier");
        dexSettings.unitMultiplier = _unitMultiplier;
        emit UnitMultiplierUpdated(_unitMultiplier);
    }    
}