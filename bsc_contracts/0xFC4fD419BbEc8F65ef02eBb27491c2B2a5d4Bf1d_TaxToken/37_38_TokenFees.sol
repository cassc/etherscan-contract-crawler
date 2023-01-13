// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED

// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.

pragma solidity ^0.8.0;

import "./Ownable.sol";

interface ITokenFees {
    function getTokenFee() view external returns(uint256);
    
    function setTokenFee(uint _tokenFee) external;
    
    function getTokenFeeAddress() view external returns(address);
    
    function setTokenFeeAddress(address payable _tokenFeeAddress) external;
}

contract TokenFees is Ownable{
    
    struct Settings {
        uint256 TOKEN_FEE; 
        uint256 DENOMINATOR;
        address payable TOKEN_FEE_ADDRESS;
    }
    
    Settings public SETTINGS;
    
    constructor() {
        SETTINGS.TOKEN_FEE = 1;
        SETTINGS.DENOMINATOR = 10000;
        SETTINGS.TOKEN_FEE_ADDRESS = payable(msg.sender);
    }
    
    function getTokenFee() view external returns(uint256) {
        return SETTINGS.TOKEN_FEE;
    }
    
    function setTokenFee(uint _tokenFee) external onlyOwner {
        SETTINGS.TOKEN_FEE = _tokenFee;
    }
    
    function getTokenFeeAddress() view external returns(address) {
        return SETTINGS.TOKEN_FEE_ADDRESS;
    }
    
    function setTokenFeeAddress(address payable _tokenFeeAddress) external onlyOwner {
        SETTINGS.TOKEN_FEE_ADDRESS = _tokenFeeAddress;
    }
} 