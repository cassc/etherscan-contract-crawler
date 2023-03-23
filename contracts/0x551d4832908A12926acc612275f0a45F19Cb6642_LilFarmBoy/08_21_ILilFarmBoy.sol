// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ILilFarmBoy {
   enum Phase {
      TEAM,
      FARMER,
      EARLY,
      WHITELIST,
      PUBLIC
   }

   struct Mint {
      uint256 price;
      uint256 maxSupply;
      uint256 maxWallet;
      uint256 totalMinted;
      uint256 phaseEnd;
      bytes32 merkleRoot;
   }

   struct Nft {
      uint256 maxSupply;
      uint256 burned;
      address treasury;
      bool sale;
      string baseUri;
   }

   struct User {
      mapping(Phase => uint256) mintCount;
      uint256 farmerPhaseAllocation;
      bool farmerPhaseMinted;
      bool earlyPhaseMinted;
      uint256 totalBurned;
   }
}