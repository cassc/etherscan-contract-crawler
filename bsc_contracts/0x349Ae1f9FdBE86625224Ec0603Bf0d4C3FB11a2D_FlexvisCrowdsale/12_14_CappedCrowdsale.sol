// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../Crowdsale.sol";
import "./TimedCrowdsale.sol";

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
abstract contract CappedCrowdsale is TimedCrowdsale {
    using SafeMath for uint256;

    uint256 private _cap;
    

    /**
     * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
     * @param cap Max amount of wei to be contributed
     */
    constructor (uint256 cap) {
        require(cap > 0, "CappedCrowdsale: cap is 0");
        _cap = cap;
    }

    /**
     * @return the cap of the crowdsale.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }

    /**
     * @dev Checks whether the cap has been reached.
     * @return Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return weiRaised() >= _cap;
    }

    function hasEnded() public view returns (bool){
        return HAS_ENDED;
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the funding cap.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal override {

        require(block.timestamp >= openingTime() && block.timestamp <= closingTime(), "TimedCrowdsale: time not within range");
        
        require(weiRaised().add(weiAmount) <= _cap, "CappedCrowdsale: cap exceeded");
        require(!HAS_ENDED, "Crowdsale has ended");

        if(weiRaised().add(weiAmount) == _cap){
            _closeCrowdsaleImmediately();
            
        }
      
        super._preValidatePurchase(beneficiary, weiAmount);

    }
}