// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFraxFerry {
    struct Batch {
        uint64 start;
        uint64 end;
        uint64 departureTime;
        uint64 status;
        bytes32 hash;
    }

    function batches(uint256) external view returns (Batch memory);

    function getTransactionsHash(uint256 start, uint256 end)
        external
        view
        returns (bytes32);

    function disputeBatch(uint256 batchNo, bytes32 hash) external;
}