// SPDX-FileCopyrightText: 2022 nawoo (@NowAndNawoo)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LightSculpture is ERC721Royalty, Ownable {
    mapping(uint256 => bytes) public uri;
    mapping(uint256 => bool) public frozen;

    constructor() ERC721("Light Sculpture", "LSR") {}

    function mint(uint256 tokenId) external onlyOwner {
        _safeMint(_msgSender(), tokenId);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function appendUri(uint256 tokenId, bytes calldata partialUri) external onlyOwner {
        require(!frozen[tokenId], "Data is frozen");
        uri[tokenId] = abi.encodePacked(uri[tokenId], partialUri);
    }

    function clearUri(uint256 tokenId) external onlyOwner {
        require(!frozen[tokenId], "Data is frozen");
        uri[tokenId] = "";
    }

    function freeze(uint256 tokenId) external onlyOwner {
        require(uri[tokenId].length != 0, "URI is not set");
        frozen[tokenId] = true;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return string(uri[tokenId]);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() external onlyOwner {
        _deleteDefaultRoyalty();
    }
}