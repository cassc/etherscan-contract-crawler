// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IReferral.sol";
import "./access/AccessControl.sol";


contract Referral is IReferral,AccessControl{

    mapping (address=>address) private _referrals; 
    
    mapping (address=>uint256) private _referralCounts;
    
    address private _rootAddress;
 
    constructor(address rootAddress_){
        _rootAddress = rootAddress_;
    }

    function getReferral(address _address)public view returns(address){
        return _referrals[_address];
    }

    function isBindReferral(address _address) public view returns(bool)
    {
        return getReferral(_address) != address(0) || _address == _rootAddress;
    }

    function getReferralCount(address _address) public view returns(uint256){
        return _referralCounts[_address];
    }

    function bindReferral(address _referral,address _user) external onlyOperator{
        require(isBindReferral(_referral),"Referral not bind");
        require(!isBindReferral(_user),"User is bind");
        _referrals[_user] = _referral;
        _referralCounts[_referral]++;
        emit BindReferral(_referral, _user);
    }

    function getReferrals(address _address,uint256 _num) external view returns(address[] memory){
        address[] memory result;
        result = new address[](_num);
        for(uint256 i=0;i<_num;i++){
            _address = getReferral(_address);
            if(_address == address(0))break;
            result[i] = _address;
        }
        return result;
    }

    function getRootAddress()external view returns(address){
        return _rootAddress;
    }
}