// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

interface IOnRye {
    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
    event MaxTokenAmountSet(uint256 newAmount);
    event GovTokenSet(address _govToken);
    event GovTokenRateSet(uint256 _govTokenRate);
    event CielSet(address _ciel);
    event CielTokenRateSet(uint256 _cielTokenRate);
    event PromoTokenRateSet(uint256 _promoTokenRate);
    event CielPairSet(address _cielPair);
    event BuyBackAddressSet(address _buyBackAddress);
    event TokenPendingDividendsSet(uint256 _newValue);
    event GasForTransferSet(uint256 _newGas);

    receive() external payable;
    function dividendOf(address _owner) external view returns(uint256);
    function setGovToken(address _govToken) external;
    function setCiel(address _ciel) external;
    function setCielPair(address _cielPair) external;
    function setBuyBackAddress(address payable _buyBackAddress) external;
    function sTPD(uint256 _newValue) external;
    function setGasForTransfer(uint256 _newGas) external;
    function setMaxTokenSendAmount(uint256 _newAmount) external;
    function setGovTokenRate(uint256 _govTokenRate) external;
    function setCielTokenRate(uint256 _cielTokenRate) external;
    function setPromoTokenRate(uint256 _promoTokenRate) external;
    function gTDD() external view returns(uint256);
    function withdrawableDividendOf(address _owner) external view returns(uint256);
    function _withdrawDividendOfUser(address payable user) external returns (uint256);
    function withdrawnDividendOf(address _owner) external view returns(uint256);
    function accumulativeDividendOf(address _owner) external view returns(uint256);
    function getMagnifiedDividend() external view returns(uint256);
    function _getTotalPendingDividends() external view returns(uint256);
    function getMagDiv(address account) external view returns(int256);
    function _setBalance(address account, uint256 newBalance) external;
    function _userCustomRewardToken(address user) external view returns (address);
    function sUCRT(address user, address rewardToken) external;
    function sTA(address rewardToken, bool isAvailable) external;
    function dTA(address rewardToken) external;
    function sTSS(address rewardToken, bool shouldSwap) external;
    function dTSS(address rewardToken) external;
    
}