// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

library NFTRental {
    // tokenAmounts: to be 1 per tokenIds for ERC721
    struct Mission {
        string uuid;
        string dappId;
        address owner;
        address tenant;
        address managedBy;
        address[] collections;
        uint256[][] tokenIds;
        uint256[][] tokenAmounts;
        uint256 tenantShare;
    }

    struct MissionDates {
        uint256 postDate;
        uint256 startDate;
        uint256 cancelDate;
        uint256 stopDate;
    }
}