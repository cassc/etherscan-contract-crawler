// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IAllowlist {

    struct Allowlist {
       bytes32 typedata;
       bool isActive;
       string metadataUri;
       string name;
       uint256 price;
       uint256 maxMintPerWallet;
       uint256 tokenPool;
       uint256 startTime;
       uint256 endTime;
       uint256 maxSupply;
   }

   struct Allowlists {
     uint256 currentStartId;
     uint256 count;
     mapping(uint256 => Allowlist) lists;
   }

}