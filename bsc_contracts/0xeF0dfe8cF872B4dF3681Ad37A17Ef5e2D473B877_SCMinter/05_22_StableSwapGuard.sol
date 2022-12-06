// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
* @title StableSwapGuard
* @author Geminon Protocol
* @notice Calculates safety fees to make oracle front-running exploit unprofitable.
*/
contract StableSwapGuard {

    struct priceRecord {
        uint64 lastTimestamp;
        uint32 weightedPrice;
        uint256 volume;
    }

    mapping(address => priceRecord) public priceRecordsLongs;
    mapping(address => priceRecord) public priceRecordsShorts;
    
    
    /// @dev Updates the price record of the stablecoin for the given trade direction
    function _updatePriceRecord(address stable, uint256 usdPrice, uint256 amount, bool isOpLong) internal {
        if (isOpLong) {
            priceRecord memory record = priceRecordsLongs[stable];
            priceRecordsLongs[stable] = _modifyRecord(record, usdPrice, amount);
        } else {
            priceRecord memory record = priceRecordsShorts[stable];
            priceRecordsShorts[stable] = _modifyRecord(record, usdPrice, amount);
        }
    }

    /// @dev Calculates the minimum fee rate to avoid front-running exploits for a pair of stablecoins (6 decimals)
    function _safetyFeeStablecoins(
        address stableIn, 
        address stableOut, 
        uint256 usdPriceIn, 
        uint256 usdPriceOut
    ) internal view returns(uint256) {
        uint256 fee1 = _safetyFeeStablecoin(stableIn, usdPriceIn, false);
        uint256 fee2 = _safetyFeeStablecoin(stableOut, usdPriceOut, true);
        return fee1 > fee2 ? fee1 : fee2;
    }
    
    /// @dev Calculates the minimum fee rate to avoid front-running exploits for a single stablecoin (6 decimals)
    function _safetyFeeStablecoin(address stable, uint256 usdPrice, bool isOpLong) internal view returns(uint256) {
        return _volatility(stable, usdPrice, isOpLong) / 1e12;
    }

    
    /// @dev Calculates a weighted mean of the price for the last 5 minutes
    function _modifyRecord(
        priceRecord memory record, 
        uint256 usdPrice, 
        uint256 amount
    ) private view returns(priceRecord memory) {
        uint64 timestamp;
        uint32 weightedPrice;
        uint256 volume;

        if (block.timestamp - record.lastTimestamp > 300) {
            weightedPrice = uint32(usdPrice/1e12);
            volume = amount;
        } else {
            uint256 w = (amount * 1e6) / (amount + record.volume);
            weightedPrice = uint32((w*usdPrice/1e12 + (1e6-w)*record.weightedPrice) / 1e6);
            volume = record.volume + amount;
        }
        timestamp = uint64(block.timestamp);

        return priceRecord(timestamp, weightedPrice, volume);
    }


    /// @dev Calculates the price variation of the stablecoin for a given trade direction (18 decimals)
    function _volatility(address stable, uint256 usdPrice, bool isOpLong) private view returns(uint256) {
        uint32 weightedPrice;
        
        if (isOpLong)
            weightedPrice = priceRecordsLongs[stable].weightedPrice;
        else
            weightedPrice = priceRecordsShorts[stable].weightedPrice;
        
        return _absRet(usdPrice, uint256(weightedPrice)*1e12);
    }

    /// @dev Calculates the absolute return of two prices
    function _absRet(uint256 price, uint256 basePrice) private pure returns(uint256) {
        if (basePrice == 0) 
            return 0;
            
        if (price >= basePrice)
            return ((price - basePrice) * 1e18) / basePrice;
        else
            return ((basePrice - price) * 1e18) / basePrice;
    }
}