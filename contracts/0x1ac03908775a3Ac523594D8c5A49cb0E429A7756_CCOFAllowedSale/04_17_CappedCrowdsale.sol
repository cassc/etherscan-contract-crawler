// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./Crowdsale.sol";

abstract contract CappedCrowdsale is Crowdsale {
    /**
     *@dev cap Max number of tokens
     */
    uint256 public cap;

    /**
     * @dev Constructor, takes maximum amount of tokens available in the crowdsale.
     * @param _cap Max number of tokens that can be purchased in the current phase
     */
    constructor(uint256 _cap) {
        require(_cap > 0);
        cap = _cap;
    }

    /**
     * @dev Checks whether the cap has been reached.
     * @return bool Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return tokenSold >= cap;
    }

    /**
     * @dev Extend parent behavior requiring to be within contributing period
     *@param _beneficiary addr receiving the token
     * @param _tokenAmount Number of tokens sold
     */

    function _preValidatePurchase(address _beneficiary, uint256 _tokenAmount)
        internal
        virtual
        override
    {
        require(!capReached(), "ERROR:Cap Reached Crowdsale Over");
        super._preValidatePurchase(_beneficiary, _tokenAmount);
    }
}