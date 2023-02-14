//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "../VaultStorage.sol";
import "../interfaces/IComputationalView.sol";
import "../../common/LibConstants.sol";
import "./ComputationalView.sol";
import "../interfaces/IRewardHandler.sol";
import "../interfaces/V1Migrateable.sol";

abstract contract RewardHandler is IRewardHandler {

    /**
     * Modification functions
     */
    function rewardTrader(address trader, address feeToken, uint amount) external override {
        VaultStorage.VaultData storage rs = VaultStorage.load();
        require(msg.sender == rs.dexible, "Unauthorized");
        uint volumeUSD = IComputationalView(address(this)).computeVolumeUSD(feeToken, amount);

        //make the volume adjustment to the pool first to prevent large orders from 
        //minting tokens for cheaper rate
        _adjustVolume(volumeUSD);

        //determine the mint rate
        uint rate = IComputationalView(address(this)).currentMintRateUSD();

        //get the number of DXBL per $1 of volume
        uint tokens = (volumeUSD*1e18) / rate;

        //we are minter on token, so request to mint tokens
        rs.dxbl.mint(trader, tokens);

        if(V1Migrateable(address(this)).canMigrate()) {
            V1Migrateable(address(this)).migrateV1();
        }
    }


    function _adjustVolume(uint volumeUSD) internal {
        VaultStorage.VaultData storage rs = VaultStorage.load();

        //get the current hour
        uint lastTrade = rs.lastTradeTimestamp;

        //record when we last adjusted volume
        rs.lastTradeTimestamp = block.timestamp;
        uint newVolume = volumeUSD;
        if(lastTrade > 0 && lastTrade <= (block.timestamp - LibConstants.DAY)) {
            delete rs.hourlyVolume;
        } else {
            //otherwise, since we never rolled over 24hrs, just delete the volume
            //that accrued 24hrs ago
            uint hr = (block.timestamp % LibConstants.DAY) / LibConstants.HOUR;
            uint slot = 0;
            //remove guard for some efficiency gain
            unchecked{slot = (hr+1)%24; }

            //get the volume bin 24hrs ago by wrapping around to next hour in 24hr period
            uint yesterdayTotal = rs.hourlyVolume[slot];

            //if we get called multiple times in the block, the same hourly total
            //would be deducted multiple times. So we reset it here so that we're 
            //not deducting it multiple times in the hour. Only the first deduction
            //will be applied and 0'd out.
            rs.hourlyVolume[slot] = 0;

            //add new volume to current hour bin
            rs.hourlyVolume[hr] += volumeUSD;

            //manipulate volume in memory not storage
            newVolume = rs.currentVolume + volumeUSD;

            //Remove volume from 24hr's ago if there was anything
            if(yesterdayTotal > 0) {
                //note that because currentVolume includes yesterday's, then this subtraction 
                //is safe.
                newVolume -= yesterdayTotal;
            } 
        }
        rs.currentVolume = newVolume;
        _adjustMintRate(rs, uint16(newVolume / LibConstants.MM_VOLUME));
    }

    /**
     * Make an adjustment to the mint rate if the 24hr volume falls into a new rate bucket
     */
    function _adjustMintRate(VaultStorage.VaultData storage rs, uint16 normalizedMMInVolume) internal {
        
        VaultStorage.MintRateRange memory mr = rs.currentMintRate;
        //if the current rate bucket's max is less than current normalized volume
        if(mr.maxMMVolume <= normalizedMMInVolume) {
            //we must have increased volume so we have to adjust the rate up
            _adjustMintRateUp(rs, normalizedMMInVolume);
            //otherwise if the current rate's min is more than the current volume
        } else if(mr.minMMVolume >= normalizedMMInVolume) {
            //it means we're trading less volume than the current rate, so we need
            //to adjust it down
            _adjustMintRateDown(rs, normalizedMMInVolume);
        } //else rate stays the same
    }

    /**
     * Increase the minimum volume required to mint a single token
     */
    function _adjustMintRateUp(VaultStorage.VaultData storage rs, uint16 mm) internal {
        VaultStorage.MintRateRange memory mr = rs.currentMintRate;
        while(!_rateInRange(mr,mm)) {
            //move to the next higher rate if one is configured, otherwise stay where we are
            VaultStorage.MintRateRange storage next = rs.mintRateRanges[mr.index + 1];
            if(next.rate == 0) {
                //reached highest rate, that will be the capped rate 
                break;
            }
            mr = next;
        }

        //don't waste gas storing if not changed
        if(rs.currentMintRate.rate != mr.rate) {
            rs.currentMintRate = mr;
        }
        
    }
    
    /**
     * Decrease minimum volume required to mint a DXBL token
     */
    function _adjustMintRateDown(VaultStorage.VaultData storage rs, uint16 mm) internal {
        VaultStorage.MintRateRange memory mr = rs.currentMintRate;
        while(!_rateInRange(mr,mm)) {
            if(mr.index > 0) {
                //move to the next higher rate if one is configured, otherwise stay where we are
                VaultStorage.MintRateRange storage next = rs.mintRateRanges[mr.index - 1];
                mr = next;
            } else {
                //we go to the lowest rate then
                break;
            }
        }
        rs.currentMintRate = mr;
    }

    //test to see if volume is range for a rate bucket
    function _rateInRange(VaultStorage.MintRateRange memory range, uint16 mm) internal pure returns (bool) {
        return range.minMMVolume <= mm && mm < range.maxMMVolume;
    }
    
}