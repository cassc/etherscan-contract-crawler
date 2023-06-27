/**
 *Submitted for verification at Etherscan.io on 2023-06-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ISkateContractV2AuctionHouseV2 {
    function settleCurrentAndCreateNewAuction() external;
}

contract BlockProtect {
    address public constant AUCTION_HOUSE =
        0xC28e0d3c00296dD8c5C3F2E9707361920f92a209;
        
    function settleAuction(uint expectedBlock) external {
        require(block.number <= expectedBlock, "Gnar missed");

        ISkateContractV2AuctionHouseV2(AUCTION_HOUSE)
            .settleCurrentAndCreateNewAuction();
    }
}