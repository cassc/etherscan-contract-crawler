// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// NOTE: We can also use the interfaces for reading/changing the state of already deployed/existing (e.g. others') contracts and libraries. Only include the methods needed/used, because just those methods will be imported and compiled to ABI, so you save gas on contract/library deployment. You create an instance of such interfaced contract/library from their address, preferably by passing it in the constuctor or/and initializer when deploying.
interface IAkshunSeasonPassNft {
    function mint(uint16 subcollectionIdx, uint8 tokenPresetURIIdx, uint8 tokenBaseURIIdx, address to) external returns(uint256);
    function burn(uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external returns(address);
}