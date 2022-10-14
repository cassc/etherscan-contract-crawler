// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

interface IX2y2 {

    enum InvStatus {
        NEW,
        AUCTION,
        COMPLETE,
        CANCELLED,
        REFUNDED
    }

    function inventoryStatus(bytes32) external view returns (InvStatus status);
}