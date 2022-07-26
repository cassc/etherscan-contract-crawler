// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.0;

library LibERC1155LazyMint {
    bytes4 constant public ERC1155_LAZY_ASSET_CLASS = bytes4(keccak256("ERC1155_LAZY"));
    bytes4 constant _INTERFACE_ID_MINT_AND_TRANSFER = 0x6db15a0f;

    struct Mint1155Data {
        uint256 tokenId;
        string tokenURI;
        uint256 supply;
        address creator;
        uint256 royaltyFee;
        bytes signature;      
    }

    bytes32 public constant MINT_AND_TRANSFER_TYPEHASH = keccak256("Mint1155(uint256 tokenId,uint256 supply,string tokenURI,address creator,uint256 royaltyFee)");

    function hash(Mint1155Data memory data) internal pure returns (bytes32) {        
        return keccak256(abi.encode(
                MINT_AND_TRANSFER_TYPEHASH,
                data.tokenId,
                data.supply,
                keccak256(bytes(data.tokenURI)),
                data.creator,
                data.royaltyFee    
            ));
    }
}