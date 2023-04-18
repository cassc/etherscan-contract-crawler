// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IMarketplace {
    event Buy(address seller, address buyer, uint256 nftId, address refAddress);

    event Sell(address seller, address buyer, uint256 nftId);

    event PayCommission(address buyer, address refAccount, uint256 commissionAmount);

    event ErrorLog(bytes message);

    function buyByCurrency(uint256[] memory _nftIds, uint256 _refCode) external;

    function buyByToken(uint256[] memory _nftIds, uint256 _refCode) external;

    function sell(uint256[] memory _nftIds) external;

    function setSaleWalletAddress(address _saleAddress) external;

    function setStakingContractAddress(address _stakingAddress) external;

    function setDiscountPercent(uint8 _discount) external;

    function setCommissionPercent(uint8 _percent) external;

    function setActiveSystemTrading(uint256 _activeTime) external;

    function setSaleStrategyOnlyCurrencyStart(uint256 _newSaleStart) external;

    function setSaleStrategyOnlyCurrencyEnd(uint256 _newSaleEnd) external;

    function setSalePercent(uint256 _newSalePercent) external;

    function setOracleAddress(address _oracleAddress) external;

    function allowBuyNftByCurrency(bool _activePayByCurrency) external;

    function allowBuyNftByToken(bool _activePayByToken) external;

    function setTypePayCommission(bool _typePayCommission) external;

    function getActiveMemberForAccount(address _wallet) external returns (uint256);

    function getReferredNftValueForAccount(address _wallet) external returns (uint256);

    function getNftCommissionEarnedForAccount(address _wallet) external returns (uint256);

    function getNftSaleValueForAccountInUsdDecimal(address _wallet) external returns (uint256);

    function updateStakeValueData(address _user, uint256 _valueInUsdWithDecimal) external;

    function updateReferralData(address _user, uint256 _refCode) external;

    function genReferralCodeForAccount() external returns (uint256);

    function getReferralCodeForAccount(address _wallet) external returns (uint256);

    function getReferralAccountForAccount(address _user) external view returns (address);

    function getReferralAccountForAccountExternal(address _user) external view returns (address);

    function getAccountForReferralCode(uint256 _refCode) external returns (address);

    function getF1ListForAccount(address _wallet) external returns (address[] memory);

    function getTeamNftSaleValueForAccountInUsdDecimal(address _wallet) external returns (uint256);

    function possibleChangeReferralData(address _wallet) external returns (bool);

    function lockedReferralDataForAccount(address _user) external;

    function currrentReferralCounter() external view returns (uint256);

    function setSystemWallet(address _newSystemWallet) external;

    function getCurrencyAddress() external view returns (address);

    function setCurrencyAddress(address _currency) external;

    function depositToken(uint256 _amount) external;

    function withdrawTokenEmergency(uint256 _amount) external;

    function withdrawCurrencyEmergency(address _currency, uint256 _amount) external;

    function tranferNftEmergency(address _receiver, uint256 _nftId) external;

    function tranferMultiNftsEmergency(
        address[] memory _receivers,
        uint256[] memory _nftIds
    ) external;

    function checkValidRefCodeAdvance(address _user, uint256 _refCode) external returns (bool);
}