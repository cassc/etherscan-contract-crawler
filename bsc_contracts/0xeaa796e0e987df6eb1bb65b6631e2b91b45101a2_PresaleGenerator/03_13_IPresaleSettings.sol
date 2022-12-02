// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IPresaleSettings {
    function getMaxPresaleLength () external view returns (uint256);
    function getLevel4RoundLength () external view returns (uint256);
    function getLevel3RoundLength () external view returns (uint256);
    function getLevel2RoundLength () external view returns (uint256);
    function getLevel1RoundLength () external view returns (uint256);
    function userAllowlistLevel (address _user) external view returns (uint8);
    function referrerIsValid(bytes32 _referralCode) external view returns (bool, address payable);
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
    function addReferral(bytes32 _referralCode, address _project, address _presale, address _baseToken) external returns (bool, address payable, uint256);
    function finalizeReferral(bytes32 _referralCode, uint256 _index, bool _active, bool _success, uint256 _raised, uint256 _earned) external;
}