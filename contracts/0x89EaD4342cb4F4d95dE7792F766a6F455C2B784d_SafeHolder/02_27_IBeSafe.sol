// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeHolder} from "./SafeHolder.sol";

contract IBeSafe is ERC721URIStorage, Ownable {
    using Strings for uint256;
    using Strings for address;
    uint256 public numberOfMintedTokens;

    constructor() ERC721("iBeSafe", "IBS") {}

    function mint(address to, address safe)
        external
        onlyOwner
        returns (uint256 newTokenId)
    {
        newTokenId = ++numberOfMintedTokens;
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, getTokenURI(newTokenId, safe));
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);
        return getTokenURI(tokenId, SafeHolder(owner()).tokenToSafe(tokenId));
    }

    function getTokenURI(uint256 tokenId, address safe)
        internal
        pure
        returns (string memory)
    {
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "Safe NFT #',
            tokenId.toString(),
            '",',
            '"image": "ipfs://QmT2YzhGiz993t8ZVmhkEZ8GbYwXXbQrZAMdNpH18ZBXWX/',
            (tokenId % 4).toString(),
            '.jpg",',
            '"description": "Safe wrapped in an NFT",',
            '"attributes": [{"trait_type": "Safe Address", "value": "',
            safe.toHexString(),
            '" }]',
            "}"
        );
        return
            string(
                abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI))
            );
    }

    // this makes it not show in open sea
    function contractURI() external view returns (string memory) {
        return SafeHolder(owner()).nftMetadata();
    }
}