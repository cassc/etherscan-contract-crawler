// contracts/GuildOfGuardiansHeroesNFT.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Minting.sol";
import "./GuildOfGuardiansNFTCommon.sol";

contract GuildOfGuardiansHeroesNFT is GuildOfGuardiansNFTCommon {
    mapping(uint256 => uint8) chromas;

    event MintFor(
        address to,
        uint256 amount,
        uint256 tokenId,
        uint16 proto,
        uint256 serialNumber,
        uint8 chroma,
        string tokenURI
    );

    constructor() ERC721("Guild of Guardians Heroes", "GOGH") {}

    /**
     * @dev Called by IMX to mint each NFT
     *
     * @param to the address to mint to
     * @param amount not relavent for NFTs
     * @param mintingBlob all NFT details
     */
    function mintFor(
        address to,
        uint256 amount,
        bytes memory mintingBlob
    ) external override {
        (
            uint256 tokenId,
            uint16 proto,
            uint256 serialNumber,
            uint8 chroma,
            string memory tokenURI
        ) = Minting.deserializeMintingBlobWithChroma(mintingBlob);
        _mintCommon(to, tokenId, tokenURI, proto, serialNumber);
        chromas[tokenId] = chroma;
        emit MintFor(
            to,
            amount,
            tokenId,
            proto,
            serialNumber,
            chroma,
            tokenURI
        );
    }

    /**
     * @dev Retrieve the proto, serial and special edition for a particular NFT represented by it's token id
     *
     * @param tokenId the id of the NFT you'd like to retrieve details for
     * @return proto The proto (type) of the specified NFT
     * @return serialNumber The serial number of the specified NFT
     * @return chroma The special edition of the specified NFT
     */
    function getDetails(uint256 tokenId)
        public
        view
        returns (
            uint16 proto,
            uint256 serialNumber,
            uint8 chroma
        )
    {
        return (protos[tokenId], serialNumbers[tokenId], chromas[tokenId]);
    }
}