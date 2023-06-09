// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0 <0.9.0;

import { ERC721A } from "erc721a/contracts/ERC721A.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract ForgottenToken is ERC721A, Ownable {
    string private _metadataRoot;
    string private _contractMetadata;

    constructor() ERC721A("The Forgottens", "FORGOTTEN") {
        _metadataRoot = "https://metadata.blokpax.com/lost-miners-ai-art/";
        _contractMetadata = "https://metadata.blokpax.com/lost-miners-ai-art/opensea.json";

        _mint(0x419E8e063D7EAb01eBBF2D853e73bc6F3b53dB83, 25);
    }

    function _baseURI() internal view override returns (string memory) {
        return _metadataRoot;
    }

    function setBaseURI(string memory uri) onlyOwner public {
        _metadataRoot = uri;
    }

    function contractURI() public view returns(string memory) {
        return _contractMetadata;
    }

    function setContractURI(string memory uri) onlyOwner public {
        _contractMetadata = uri;
    }

    event MetadataUpdate(uint256 _tokenId);
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);

    function updateMetadata(uint256 id) public onlyOwner {
        emit MetadataUpdate(id);
    }

    function updateAllMetadata() public onlyOwner {
        emit BatchMetadataUpdate(0, type(uint256).max);
    }

    function updateMetadataBatch(uint256 start, uint256 end) public onlyOwner {
	emit BatchMetadataUpdate(start, end);
    }
}