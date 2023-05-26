// DELTA-BUG-BOUNTY
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./../../../common/OVLTokenTypes.sol";
import "../../../interfaces/IOVLVestingCalculator.sol";
import "../../libs/SafeMath.sol";

contract OVLVestingCalculator is IOVLVestingCalculator {
    using SafeMath for uint256;

    function getTransactionDetails(VestingTransaction memory _tx) public view override returns (VestingTransactionDetailed memory dtx) {
        return getTransactionDetails(_tx, block.timestamp);
    }

    function getTransactionDetails(VestingTransaction memory _tx, uint256 _blockTimestamp) public pure override returns (VestingTransactionDetailed memory dtx) {
        if(_tx.fullVestingTimestamp == 0) {
            return dtx;
        }

        dtx.amount = _tx.amount;
        dtx.fullVestingTimestamp = _tx.fullVestingTimestamp;

        // at precision E4, 1000 is 10%
        uint256 timeRemaining;
        if(_blockTimestamp >= dtx.fullVestingTimestamp) {
            // Fully vested
            dtx.mature = _tx.amount;
            return dtx;
        } else {
            timeRemaining = dtx.fullVestingTimestamp - _blockTimestamp;
        }

        uint256 percentWaitingToVestE4 = timeRemaining.mul(1e4) / FULL_EPOCH_TIME;
        uint256 percentWaitingToVestE4Scaled = percentWaitingToVestE4.mul(90) / 100;

        dtx.immature = _tx.amount.mul(percentWaitingToVestE4Scaled) / 1e4;
        dtx.mature = _tx.amount.sub(dtx.immature);
    }

    function getMatureBalance(VestingTransaction memory _tx, uint256 _blockTimestamp) public pure override returns (uint256 mature) {
        if(_tx.fullVestingTimestamp == 0) {
            return 0;
        }
        
        uint256 timeRemaining;
        if(_blockTimestamp >= _tx.fullVestingTimestamp) {
            // Fully vested
            return _tx.amount;
        } else {
            timeRemaining = _tx.fullVestingTimestamp - _blockTimestamp;
        }

        uint256 percentWaitingToVestE4 = timeRemaining.mul(1e4) / FULL_EPOCH_TIME;
        uint256 percentWaitingToVestE4Scaled = percentWaitingToVestE4.mul(90) / 100;

        mature = _tx.amount.mul(percentWaitingToVestE4Scaled) / 1e4;
        mature = _tx.amount.sub(mature); // the subtracted value represents the immature balance at this point
    }

    function calculateTransactionDebit(VestingTransactionDetailed memory dtx, uint256 matureAmountNeeded, uint256 currentTimestamp) public pure override returns (uint256 outputDebit) {
        if(dtx.fullVestingTimestamp > currentTimestamp) {
            // This will be between 0 and 100*pm representing how much of the mature pool is needed
            uint256 percentageOfMatureCoinsConsumed = matureAmountNeeded.mul(PM).div(dtx.mature);
            require(percentageOfMatureCoinsConsumed <= PM, "OVLTransferHandler: Insufficient funds");

            // Calculate the number of immature coins that need to be debited based on this ratio
            outputDebit = dtx.immature.mul(percentageOfMatureCoinsConsumed) / PM;
        }

        // shouldnt this use outputDebit
        require(dtx.amount <= dtx.mature.add(dtx.immature), "DELTAToken: Balance maximum problem"); // Just in case
    }
}