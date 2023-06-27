// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

import "./IPublicLock.sol";
import "./ILockKeyPurchaseHook.sol";
import "./ReferralManager.sol";

contract KeyPurchaseHook is ILockKeyPurchaseHook {
    ReferralManager private _referralManager;

    constructor(ReferralManager referralManager) {
        _referralManager = referralManager;
    }

    function keyPurchasePrice(
    address from,
    address recipient,
    address referrer,
    bytes calldata data
    ) external view override returns (uint minKeyPrice) {
        IPublicLock lock = IPublicLock(msg.sender);
        uint basePrice = lock.keyPrice();

        // If the buyer has a referrer, use it
        address buyerReferrer = _referralManager.getReferrer(from);
        
        require(buyerReferrer == address(0) || buyerReferrer == referrer, "Invalid referrer");

        // If the buyer has no referrer or the referrer is valid, then proceed
        if(buyerReferrer != address(0)){
            referrer = buyerReferrer;
        }

        // Check if the referrer is not the owner
        if(referrer != address(0) && referrer != lock.owner()){
            // Apply a 10% discount
            return basePrice * 90 / 100;
        }
        else{
            return basePrice;
        }
    }


    function onKeyPurchase(
    uint tokenId,
    address from,
    address recipient,
    address referrer,
    bytes calldata data,
    uint minKeyPrice,
    uint pricePaid
    ) external override {
    // If the buyer does not have a referrer, set it
    if(_referralManager.getReferrer(from) == address(0)){
        _referralManager.setReferrer(from, referrer);
    }
}
}