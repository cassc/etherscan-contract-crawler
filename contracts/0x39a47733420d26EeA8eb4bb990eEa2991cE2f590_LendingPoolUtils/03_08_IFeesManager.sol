// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../utils/Types.sol";

    
interface IFeesManager {

    enum FeeType{
        NOT_SET,
        FIXED,
        LINEAR_DECAY_WITH_AUCTION
    }


    struct RateData{
        FeeType rateType;
        uint48 startRate;
        uint48 endRate;
        uint48 auctionStartDate;
        uint48 auctionEndDate;
        uint48 poolExpiry;
    }

    error ZeroAddress();
    error NotAPool();
    error NoPermission();
    error InvalidType();
    error InvalidExpiry();
    error InvalidFeeRate();
    error InvalidFeeDates();

    event ChangeFee(address indexed pool, FeeType rateType, uint48 startRate, uint48 endRate, uint48 auctionStartDate, uint48 auctionEndDate);

    function setPoolRates(
        address _lendingPool,
        bytes32 _ratesAndType,
        uint48 _expiry,
        uint48 _protocolFee
    ) external;

    function getCurrentRate(address _pool) external view returns (uint48);
}