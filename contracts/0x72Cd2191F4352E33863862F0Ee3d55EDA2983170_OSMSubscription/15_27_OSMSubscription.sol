// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "./TokenReceiver.sol";
import "./Mintable.sol";
import "./Nameable.sol";
import { DiscountIsInvalid } from "./SetSubscribable.sol";

error ZeroAddress(address zero);
contract OSMSubscription is TokenReceiver {  
    event CommissionPaid(address wallet, uint256 amount); 
    constructor(string memory name, string memory symbol) Subscribable(name,symbol) {}          

    function payOutFees(uint256 numberOfDays, string memory discountCode) internal {
        
        address payable partner = payable(subs.promoDiscounts[discountCode].partner);        
            
        if (determineCommission(determineFee(numberOfDays,discountCode), discountCode) > 0) {
            partner.transfer(determineCommission(determineFee(numberOfDays,discountCode), discountCode));
            emit CommissionPaid(subs.promoDiscounts[discountCode].partner, determineCommission(determineFee(numberOfDays,discountCode), discountCode));
        }        
        OSM_TREASURY_WALLET.transfer(determineFee(numberOfDays,discountCode)-determineCommission(determineFee(numberOfDays,discountCode), discountCode));
        subs.promoDiscounts[discountCode].timesUsed = subs.promoDiscounts[discountCode].timesUsed + 1; 
    }       

    function mint(uint256 numberOfDays) external payable {
        payOutFees(numberOfDays, blank);
        _mintTokenFor(msg.sender,numberOfDays);     
    }  

    function discountMint(uint256 numberOfDays, string calldata discountCode) external payable {          
        if (!subs.promoDiscounts[discountCode].exists || subs.promoDiscounts[discountCode].expires < block.timestamp) {
            revert DiscountIsInvalid(discountCode);
        }        
        payOutFees(numberOfDays, discountCode);
        subs.promoDiscounts[discountCode].timesUsed = subs.promoDiscounts[discountCode].timesUsed + 1;
        _mintTokenFor(msg.sender,numberOfDays,discountCode);          
    }    

    function mintForRecipient(address recipient, uint256 numberOfDays) external onlyOwner { 
        establishSubscription(incrementMint(recipient),numberOfDays);  
    }  

    function _mintTokenFor(address recipient, uint256 numberOfDays) internal {
        _mintTokenFor(recipient,numberOfDays,blank);
    }
    function _mintTokenFor(address recipient, uint256 numberOfDays, string memory discountCode) internal {
        commitSubscription(incrementMint(recipient), numberOfDays, discountCode);  
    }

    function incrementMint(address recipient) private returns (uint256) {
        uint256 tokenId = totalSupply()+1;
        _mint(recipient,tokenId);
        return tokenId;
    }

    function renewOSM(uint256 tokenId, uint256 numberOfDays) public payable {
        renewOSM(tokenId, numberOfDays, blank);
    }

    function renewOSM(uint256 tokenId, uint256 numberOfDays, string memory discountCode) public payable {
        payOutFees(numberOfDays, discountCode);
        renewSubscription(tokenId, numberOfDays, discountCode);
    }
}