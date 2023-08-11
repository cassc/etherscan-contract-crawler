// SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.17;

//@title ILazyMint interface used for communicating with ERC721, ERC1155.
//@dev see{ERC721, ERC1155}.

interface ILazyMint {
    //@notice function used for ERC721Lazymint, it does NFT minting and NFT transfer.
    //@param from NFT to be minted on this address.
    //@param to NFT to be transffered from address to this address.
    //@param _tokenURI IPFS URI of NFT to be Minted.
    //@param _royaltyFee fee permiles for secondary sale.
    //@param _receivers fee receivers for secondary sale.
    //@dev see {ERC721}.

    function mintAndTransfer(
        address from,
        address to,
        string memory _tokenURI,
        uint96[] calldata _royaltyFee,
        address[] calldata _receivers
    ) external returns(uint256 _tokenId);

    //@notice function used for ERC1155Lazymint, it does NFT minting and NFT transfer.
    //@param from NFT to be minted on this address.
    //@param to NFT to be transffered from address to this address.
    //@param _tokenURI IPFS URI of NFT to be Minted.
    //@param _royaltyFee fee permiles for secondary sale.
    //@param _receivers fee receivers for secondary sale.
    //@param supply copies to minted to creator 'from' address.
    //@param qty copies to be transfer to receiver 'to' address.
    //@dev see {ERC1155}.

    function mintAndTransfer(
        address from,
        address to,
        string memory _tokenURI,
        uint96[] calldata _royaltyFee,
        address[] calldata _receivers,
        uint256 supply,
        uint256 qty
    ) external returns(uint256 _tokenId);
}