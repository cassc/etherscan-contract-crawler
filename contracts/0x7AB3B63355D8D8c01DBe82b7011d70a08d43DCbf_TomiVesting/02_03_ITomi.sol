// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITomi  {
    struct emissionCriteria{
         // tomi mints before auction first 2 weeks of NFT Minting
       uint256 beforeAuctionBuyer;
       uint256 beforeAuctionCoreTeam;
       uint256 beforeAuctionMarketing;

        // tomi mints after two weeks // auction everyday of NFT Minting
       uint256 afterAuctionBuyer;
       uint256 afterAuctionFutureTeam;
       
       // booleans for checks of minting
       bool mintAllowed;
    }

    function mintThroughNft(address buyer, uint256 quantity) external;

    function mintThroughVesting(address buyer, uint256 quantity) external returns(bool);

    function emissions() external returns (emissionCriteria memory emissions);
}