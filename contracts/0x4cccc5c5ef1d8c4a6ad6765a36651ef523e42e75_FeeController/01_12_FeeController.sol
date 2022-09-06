pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IFeeController.sol";

/**
 * Fee Controller is intended to be an upgradable component of Pawnfi
 * where new fees can be added or modified based on different user attributes
 *
 * Type/size of loan being requested
 * Amount of tokens being staked, etc
 *
 * Version 1 (as of 4/21/2021) Capabilities:
 *
 * FeeController will be called once after a loan has been matched so that we can
 * create an origination fee (2% credited to PawnFi)
 * @dev support for floating point originationFee should be discussed
 */

contract FeeController is AccessControlEnumerable, IFeeController, Ownable {
    // initial fee is 3%
    uint256 private originationFee = 300;

    constructor() {}

    /**
     * @dev Set the origination fee to the given value
     *
     * @param _originationFee the new origination fee, in bps
     *
     * Requirements:
     *
     * - The caller must be the owner of the contract
     */
    function setOriginationFee(uint256 _originationFee) external override onlyOwner {
        originationFee = _originationFee;
        emit UpdateOriginationFee(_originationFee);
    }

    /**
     * @dev Get the current origination fee in bps
     *
     */
    function getOriginationFee() public view override returns (uint256) {
        return originationFee;
    }
}