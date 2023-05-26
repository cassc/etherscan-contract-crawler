// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10; 

import "./TOracle.sol";

interface IOracle {
    function getData() external view returns (uint256, bool);
}

/**
 * @title TBILL Price Oracle
 */
contract TBillPriceOracle is TOracle, IOracle {
    event UpdatedAvgPrice(
        uint256 price,
        bool valid
    );
    
    uint256 private constant VALIDITY_MASK = 2**(256-1);
    uint256 private constant PRICE_MASK = VALIDITY_MASK-1;
    uint8 public constant decimals = 18;

    uint256 private _tbillAvgPriceAndValidity; //1 bit validity then 255 bit price; updated ONLY daily. for more up-to-date info, view PriceRecords

    constructor(
        uint256 initialTbillPrice, 
        uint256 initialVoteThreshold, uint256 expiry, address[] memory initialOracles
    )
    TOracle(initialVoteThreshold, expiry, initialOracles)
    {
        _tbillAvgPriceAndValidity = initialTbillPrice;        
    }    

    function getData() external view returns (uint256 price, bool valid) {
        price = _tbillAvgPriceAndValidity & PRICE_MASK;
        valid = _tbillAvgPriceAndValidity & VALIDITY_MASK > 0;
    }
    function getTBillLastPrice() external view returns (uint256 price) {
        price = _tbillAvgPriceAndValidity & PRICE_MASK;
    }
    function getTBillLastPriceValid() external view returns (bool valid) {
        valid = _tbillAvgPriceAndValidity & VALIDITY_MASK > 0;
    }

    /**
        @notice should only be called by executeProposal, which has already verified the dataHash.
     */
    function onExecute(bytes calldata data) internal override {
        uint256 tbillAvgPriceAndValidity = uint256(bytes32(data[:32]));
        uint256 price = tbillAvgPriceAndValidity & PRICE_MASK;
        bool valid = tbillAvgPriceAndValidity & VALIDITY_MASK > 0;
        _tbillAvgPriceAndValidity = tbillAvgPriceAndValidity;
        emit UpdatedAvgPrice(price, valid);
    }    
}