// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./Contractable.sol";
import "./FlexibleMetadata.sol";
import {blank, SetSubscribable, SubscribableData, PromoDiscount, defaultPayable, InvalidNumberOfDays } from "./SetSubscribable.sol";

abstract contract Subscribable is Contractable {
    using SetSubscribable for SubscribableData; // this is the crucial change
    SubscribableData subs;

    address payable internal OSM_TREASURY_WALLET = payable(defaultPayable);

    constructor(string memory name, string memory symbol) FlexibleMetadata(name,symbol) {
        subs.initialize();
    }  

    function setRecipient(address recipient) external onlyOwner {        
        OSM_TREASURY_WALLET = payable(recipient);    
    }

    function addPromoDiscount(string calldata discountCode, uint256 amount, uint256 commission, address partner) external onlyOwner {    
        subs.promoDiscounts[discountCode] = PromoDiscount(amount,commission,0,block.timestamp + (4 * 7 days),partner,true);
    }   

    function setRateParams(uint256 multiplier, uint256 discount) external onlyOwner {
        subs.setRateParams(multiplier,discount);
    }

    function renewForToken(uint256 tokenId, uint256 numberOfDays) external onlyOwner { 
        establishSubscription(tokenId,numberOfDays);  
    }        

    function standardFee(uint256 numberOfDays) public view returns (uint256) {
        return subs.calculateFee(numberOfDays);        
    }     

    function determineFee(uint256 numberOfDays, string memory discountCode) public view returns (uint256) {
        return subs.calculateFee(numberOfDays,discountCode);        
    }      

    function determineCommission(uint256 amount, string memory discountCode) public view returns (uint256) {
        return subs.calculateCommission(amount,discountCode);
    }

    function floor(uint256 amount) internal pure returns (uint256) {
        return amount - (amount % 1000000000000000);
    }

    function expiresAt(uint256 tokenId) external view returns (uint256) {
        return subs.expiresAt(tokenId);
    }      

    function getPromoDiscount(string calldata discountCode) external view returns (PromoDiscount memory) {    
        return subs.promoDiscounts[discountCode];
    }       

    function commitSubscription(uint256 tokenId, uint numberOfDays) internal {
        commitSubscription(tokenId, numberOfDays, blank);      
    }

    function establishSubscription(uint256 tokenId, uint numberOfDays) internal {
        subs.establishSubscription(tokenId, numberOfDays);      
    }    
    
    function commitSubscription(uint256 tokenId, uint numberOfDays, string memory discountCode) internal {
        subs.validateSubscription(numberOfDays,discountCode);
        subs.establishSubscription(tokenId,numberOfDays);        
    }

    function renewSubscription(uint256 tokenId, uint numberOfDays, string memory discountCode) internal {
        validateApprovedOrOwner(msg.sender, tokenId);
        subs.validateSubscription(numberOfDays, discountCode);
        commitSubscription(tokenId, numberOfDays, discountCode);
    }
}