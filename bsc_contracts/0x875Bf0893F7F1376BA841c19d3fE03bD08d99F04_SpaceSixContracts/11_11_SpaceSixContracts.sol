// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./GetLandNft.sol";
import "./GetShipNFT.sol";
import "./GetSegmentNFT.sol";
import "./GetResourcesNFT.sol";
import "./GetMintNFTBOX.sol";

contract SpaceSixContracts is
    GetShipNFT(0xa47cf3CE42C2045e071f1119e3e305ef1638a20A),
    GetLandNFT(0xcB9ed56dB9960aa9ea305a1A2776e7eF64aa34d3),
    GetSegmentNFT(0x7FE1a9e8ac319bb886BA249a8e9496CA5ddF4776),
    GetResourcesNFT(0x1399992B1fe7Ea36E643dc2C1C51a1227Ea2aE6e),
    GetMintNFTBOX(0x40a5Fc85D02561dF5fAC18FCFb86Bcd26b26b8Cb)
{}