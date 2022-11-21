// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./Crowdsale.sol";

abstract contract TimedCrowdsale is Crowdsale {
    /**
     * @dev openingTime Time when the sale starts
     */

    uint256 public openingTime;

    /**
     * @dev closingTime Time when the sale ends
     */
    uint256 public closingTime;

    /**
     *@dev reverts if not in Crowdsale time range
     **/

    modifier onlyWhileOpen() {
        require(
            block.timestamp >= openingTime,
            "ERROR: Crowdsale hasn't started yet"
        );
        require(block.timestamp <= closingTime, "ERROR: Crowdsale Over");

        _;
    }

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param _openingTime opening time
     * @param _closingTime  closing time
     */

    constructor(uint256 _openingTime, uint256 _closingTime) {
        require(_closingTime >= _openingTime);

        openingTime = _openingTime;
        closingTime = _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */

    function crowdsaleHasClosed() public view returns (bool) {
        return block.timestamp > closingTime;
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
        onlyWhileOpen
    {
        super._preValidatePurchase(_beneficiary, _tokenAmount);
    }
}