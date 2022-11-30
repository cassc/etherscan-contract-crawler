// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./libraries/Ownable.sol";
import "./libraries/ReentrancyGuard.sol";
import "./interfaces/IPresaleSettings.sol";

contract PresaleSettingsAdmin is Ownable, ReentrancyGuard {
    IPresaleSettings public LAB_SETTINGS;
    bool public openEnrollment;

    constructor(IPresaleSettings _address) {
        LAB_SETTINGS = _address;
    }

    function setSettingsContract(IPresaleSettings _address) external onlyOwner {
        LAB_SETTINGS = _address;
    }

    function transferSettingsOwnership(address _newOwner) external onlyOwner {
        LAB_SETTINGS.transferOwnership(_newOwner);
    }
    
    function setFeeAddresses(address payable _ethAddress, address payable _tokenFeeAddress) external onlyOwner {
        LAB_SETTINGS.setFeeAddresses(_ethAddress, _tokenFeeAddress);
    }
    
    function setFees(uint256 _baseFee, uint256 _tokenFee, uint256 _ethCreationFee, uint256 _referralFee) external onlyOwner {
        LAB_SETTINGS.setFees( _baseFee, _tokenFee, _ethCreationFee, _referralFee);
    }
    
    function setLevel4RoundLength(uint256 _level4RoundLength) external onlyOwner {
        LAB_SETTINGS.setLevel4RoundLength(_level4RoundLength);
    }

    function setLevel3RoundLength(uint256 _level3RoundLength) external onlyOwner {
        LAB_SETTINGS.setLevel3RoundLength(_level3RoundLength);
    }

    function setLevel2RoundLength(uint256 _level2RoundLength) external onlyOwner {
        LAB_SETTINGS.setLevel2RoundLength(_level2RoundLength);
    }

    function setLevel1RoundLength(uint256 _level1RoundLength) external onlyOwner {
        LAB_SETTINGS.setLevel1RoundLength(_level1RoundLength);
    }

    function setMaxPresaleLength(uint256 _maxLength) external onlyOwner {
        LAB_SETTINGS.setMaxPresaleLength(_maxLength);
    }

    function setMinSoftcapRate(uint256 _minSoftcapRate) external onlyOwner {
        LAB_SETTINGS.setMinSoftcapRate(_minSoftcapRate);
    }

    function setMinPercentToPYESwap(uint256 _minPercentToPYE) external onlyOwner {
        LAB_SETTINGS.setMinPercentToPYESwap(_minPercentToPYE);
    }

    function setMinEarlyAllowance(uint256 _minEarlyAllowance) external onlyOwner {
        LAB_SETTINGS.setMinEarlyAllowance(_minEarlyAllowance);
    }
    
    function editAllowedReferrers(address payable _referrer, bool _allow) external onlyOwner {
        LAB_SETTINGS.editAllowedReferrers(_referrer, _allow);
    }

    function enrollReferrer() external nonReentrant {
        require(openEnrollment, "Open Enrollment not Active");
        LAB_SETTINGS.editAllowedReferrers(payable(msg.sender), true);
    }

    function enableOpenEnrollment(bool _flag) external onlyOwner {
        openEnrollment = _flag;
    }
    
    function editEarlyAccessTokens(address _token, uint256 _level1Amount, uint256 _level2Amount, uint256 _level3Amount, uint256 _level4Amount, bool _ownedBalance, bool _allow) external onlyOwner {
        LAB_SETTINGS.editEarlyAccessTokens(_token, _level1Amount, _level2Amount, _level3Amount, _level4Amount, _ownedBalance, _allow);
    }

    function setAllowedBaseToken(address _baseToken, bool _flag) external onlyOwner {
        LAB_SETTINGS.setAllowedBaseToken(_baseToken, _flag);
    }
    
}