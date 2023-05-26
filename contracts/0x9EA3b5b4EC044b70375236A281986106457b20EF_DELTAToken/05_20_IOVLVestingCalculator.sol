pragma solidity ^0.7.6;
pragma abicoder v2;

import "../common/OVLTokenTypes.sol";

interface IOVLVestingCalculator {
    function getTransactionDetails(VestingTransaction memory _tx) external view returns (VestingTransactionDetailed memory dtx);

    function getTransactionDetails(VestingTransaction memory _tx, uint256 _blockTimestamp) external pure returns (VestingTransactionDetailed memory dtx);

    function getMatureBalance(VestingTransaction memory _tx, uint256 _blockTimestamp) external pure returns (uint256 mature);

    function calculateTransactionDebit(VestingTransactionDetailed memory dtx, uint256 matureAmountNeeded, uint256 currentTimestamp) external pure returns (uint256 outputDebit);
}