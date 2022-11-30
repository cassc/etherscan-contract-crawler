// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IPresaleSettings {
    function getMaxPresaleLength () external view returns (uint256);
    function getLevel4RoundLength () external view returns (uint256);
    function getLevel3RoundLength () external view returns (uint256);
    function getLevel2RoundLength () external view returns (uint256);
    function getLevel1RoundLength () external view returns (uint256);
    function userAllowlistLevel (address _user) external view returns (uint8);
    function referrerIsValid(address _referrer) external view returns (bool);
    function baseTokenIsValid(address _baseToken) external view returns (bool);
    function getBaseFee () external view returns (uint256);
    function getTokenFee () external view returns (uint256);
    function getEthAddress () external view returns (address payable);
    function getTokenAddress () external view returns (address payable);
    function getReferralFee () external view returns (uint256);
    function getEthCreationFee () external view returns (uint256);
    function getMinSoftcapRate() external view returns (uint256);
    function getMinEarlyAllowance() external view returns (uint256);
    function getMinimumPercentToPYE() external view returns (uint256);

    function transferOwnership(address _newOwner) external;    
    function setFeeAddresses(address payable _ethAddress, address payable _tokenFeeAddress) external;
    function setFees(uint256 _baseFee, uint256 _tokenFee, uint256 _ethCreationFee, uint256 _referralFee) external;
    function setLevel4RoundLength(uint256 _level4RoundLength) external;
    function setLevel3RoundLength(uint256 _level3RoundLength) external;
    function setLevel2RoundLength(uint256 _level2RoundLength) external;
    function setLevel1RoundLength(uint256 _level1RoundLength) external;
    function setMaxPresaleLength(uint256 _maxLength) external;
    function setMinSoftcapRate(uint256 _minSoftcapRate) external;
    function setMinPercentToPYESwap(uint256 _minPercentToPYE) external;
    function setMinEarlyAllowance(uint256 _minEarlyAllowance) external;
    function editAllowedReferrers(address payable _referrer, bool _allow) external;
    function editEarlyAccessTokens(address _token, uint256 _level1Amount, uint256 _level2Amount, uint256 _level3Amount, uint256 _level4Amount, bool _ownedBalance, bool _allow) external;
    function setAllowedBaseToken(address _baseToken, bool _flag) external;
}