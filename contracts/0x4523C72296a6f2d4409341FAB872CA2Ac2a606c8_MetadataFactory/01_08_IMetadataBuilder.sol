pragma solidity ^0.8.0;

import './IMetadataFactory.sol';

interface IMetadataBuilder{
    function buildMetadata(IMetadataFactory.nftMetadata memory nft, bool survivor,uint id) external view returns(string memory);
    function survivorMetadataBytes(IMetadataFactory.nftMetadata memory survivor,uint id) external view returns(bytes memory);
    function zombieMetadataBytes(IMetadataFactory.nftMetadata memory zombie,uint id) external view returns(bytes memory);
}