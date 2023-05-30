// SPDX-License-Identifier: No License
/**
 * @title Vendor Factory Contract
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./interfaces/IGenericPool.sol";
import "./interfaces/IPoolFactory.sol";
import "./interfaces/IFeesManager.sol";

contract FeesManager is 
    IFeesManager,    
    Initializable,
    UUPSUpgradeable,
    OwnableUpgradeable 
{

    IPoolFactory public factory;
    mapping(address => RateData) public poolFeesData;

    /* ========== CONSTANT VARIABLES ========== */
    uint48 private constant HUNDRED_PERCENT = 100_0000;
    uint48 private constant SECONDS_IN_YEAR = 31_536_000;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice                 Sets the address of the factory
    /// @param _factory         Address of the Vendor Pool Factory
    function initialize(IPoolFactory _factory) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        if (address(_factory) == address(0)) revert ZeroAddress();
        factory = _factory;
    }

    /// @notice                  Update the fee rates for the given pool 1% = 10000.
    /// @param _pool             Pool for which the rate will be updated.
    /// @param _ratesAndType     Encoded: feeType (1 byte) | free space (7) | startDate (6) | endDate (6) | startRate (6) | endRate (6)
    /// @param _expiry           Expiry of the pool. Not validated as either checked in factory or passed by pool.
    /// @param _protocolFee      Protocol fee set on the pool. Not checked as passed only by the pool or factory.
    /// @dev                     All updates on the rates are done from the pool itself for easy track of changes related to a pool in one contract.
    function setPoolRates(
        address _pool,
        bytes32 _ratesAndType,
        uint48 _expiry,
        uint48 _protocolFee
    ) external {
        if (!factory.pools(_pool)) revert NotAPool();
        if (msg.sender != address(factory) && msg.sender != _pool) revert NoPermission();
        RateData memory _parsedRateData = parseRates(_ratesAndType);
        RateData storage poolRateData = poolFeesData[_pool];
        if (poolRateData.rateType != FeeType.NOT_SET && _parsedRateData.rateType != poolRateData.rateType) revert InvalidType(); // If a type is already set you can not change it.
        validateParams(_parsedRateData, _expiry, _protocolFee);

        poolRateData.startRate = _parsedRateData.startRate;
        poolRateData.endRate = _parsedRateData.endRate;
        poolRateData.auctionStartDate = _parsedRateData.auctionStartDate;
        poolRateData.auctionEndDate = _parsedRateData.auctionEndDate;
        poolRateData.rateType = _parsedRateData.rateType;
        poolRateData.poolExpiry = _expiry;
        
        emit ChangeFee(_pool, _parsedRateData.rateType, _parsedRateData.startRate, _parsedRateData.endRate, _parsedRateData.auctionStartDate, _parsedRateData.auctionEndDate);
    }

    /// @notice                  Get the fee rate in % for the given pool.
    /// @param _pool             Pool that we would like to get the rate for.
    /// @return                  1% = 10000
    function getCurrentRate(address _pool) external view returns (uint48) {
        RateData memory rateData = poolFeesData[_pool];
        if (rateData.rateType == FeeType.NOT_SET) revert NotAPool();
        if (block.timestamp > 2**48 - 1) revert InvalidExpiry(); // Per auditors suggestion if timestamp will overflow.
        if (rateData.poolExpiry <= block.timestamp) return 0; // Expired pool.
        if (rateData.rateType == FeeType.LINEAR_DECAY_WITH_AUCTION) {
            return computeDecayWithAuction(rateData, rateData.poolExpiry);       
        }else if(rateData.rateType == FeeType.FIXED){
            return rateData.startRate;
        }
        revert InvalidType();
    }

    /// @notice                  Helper function to account for the time decay and the auction decay.
    /// @param _rateData         Rate data for the given pool.
    /// @param _expiry           Expiry of the pool to compute time remaining.
    /// @return                  APR for the pool a.k.a annualized fee rate (1% = 10000).
    function computeDecayWithAuction(RateData memory _rateData, uint48 _expiry) view private returns (uint48){
        uint48 time = uint48(block.timestamp); // The conversion is safe due to check in calling function.
        uint48 apr;
        if (time <= _rateData.auctionStartDate){
            apr = _rateData.startRate;
        }else if (time >= _rateData.auctionEndDate){
            apr = _rateData.endRate;
        }else{
            // Please refer to the dev docs for the explanation.
            apr = _rateData.endRate + 
                ((_rateData.startRate - _rateData.endRate) * // startRate >= endRate, checked in validation function.
                (_rateData.auctionEndDate - time) / (_rateData.auctionEndDate - _rateData.auctionStartDate)); // endDate > startDate, checked in validation.
        }
        return apr * (_expiry - time) / SECONDS_IN_YEAR; //Time is less than _expiry, checked in the calling function.
    }

    /// @notice                   Validate the newly passed parameters depending on type. Will revert if something is wrong.
    /// @param _expiry            The expiry timestamp of the pool.
    /// @param _protocolFee       The fee percentage for the protocol.
    function validateParams(RateData memory _rateData, uint48 _expiry, uint48 _protocolFee) view private {
        if (_rateData.rateType == FeeType.LINEAR_DECAY_WITH_AUCTION){
            if (_rateData.auctionEndDate <= _rateData.auctionStartDate) revert InvalidFeeDates();
            if (_protocolFee + (_rateData.startRate * (_expiry - uint48(block.timestamp)) / SECONDS_IN_YEAR) >= HUNDRED_PERCENT ||
                _protocolFee + (_rateData.endRate * (_expiry - uint48(block.timestamp)) / SECONDS_IN_YEAR) >= HUNDRED_PERCENT) 
                revert InvalidFeeRate();
        }else if(_rateData.rateType == FeeType.FIXED){ 
            if (_protocolFee + _rateData.startRate > HUNDRED_PERCENT) revert InvalidFeeRate();
        }else{
            revert InvalidType();
        }
    }

    /// @notice                  Convert the bytes string into a rates object.
    /// @param _ratesAndType     Encoded rate parameters. See docs or the setter function for encoding.
    /// @return                  RateData object filled in returned in memory, not stored. 
    function parseRates(bytes32 _ratesAndType) pure private returns (RateData memory){
        return RateData({
            rateType: FeeType(uint256(_ratesAndType >> 31*8)),                  // Fee Type: Get the left most byte.
            auctionStartDate: uint48(uint256((_ratesAndType << 8*8) >> 26*8)),  // Auction Start Date: Shift left, then right to prevent overflow, ensures 6 bytes.
            auctionEndDate: uint48(uint256((_ratesAndType << 14*8) >> 26*8)),   // Auction End Date: Shift left, then right to prevent overflow, ensures 6 bytes.
            startRate: uint48(uint256((_ratesAndType << 20*8) >> 26*8)),        // Start Rate: Shift left, then right to prevent overflow, ensures 6 bytes.
            endRate: uint48(uint256((_ratesAndType << 26*8) >> 26*8)),          // End Rate: Shift left, then right to prevent overflow, ensures 6 bytes.
            poolExpiry: 0                                                         // Expiry is not parsed from the bytes.
        });
    }

    /* ========== UPGRADES ========== */
    /// @notice                 Contract version for history.
    /// @return                 Contract version.
    function version() external pure returns (uint256) {
        return 1;
    }

    ///@notice                  Pre-upgrade checks
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}