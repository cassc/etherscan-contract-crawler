// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

library LibERC721LazyMint {
    bytes4 constant public ERC721_LAZY_ASSET_CLASS = bytes4(keccak256("ERC721_LAZY"));
    bytes4 constant _INTERFACE_ID_MINT_AND_TRANSFER = 0x8486f69f;

    struct Mint721Data {
        uint tokenId;
        string tokenURI;
        address creator;
        uint royaltyFee;                
        bytes signature;        
    }

    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH = keccak256("Mint721(uint256 tokenId,string tokenURI,address creator,uint royaltyFee)");

    function hash(Mint721Data memory data) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                MINT_AND_TRANSFER_TYPEHASH,
                data.tokenId,
                keccak256(bytes(data.tokenURI)),
                data.creator,
                data.royaltyFee              
            ));
    }
}