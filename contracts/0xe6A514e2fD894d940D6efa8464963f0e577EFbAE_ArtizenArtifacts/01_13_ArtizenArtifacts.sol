// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ArtizenArtifacts is ERC1155URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public tokenIds;

    constructor() ERC1155("") {}

    /*------ State Changing Functions ------*/

    function mint(
        address to,
        uint256 amount,
        bytes memory data,
        string memory tokenURI
    ) public onlyOwner {
        tokenIds.increment();
        uint256 id = tokenIds.current();

        _mint(to, id, amount, data);
        _setURI(id, tokenURI);
    }

    function batchMint(
        address to,
        uint256[] memory amounts,
        bytes memory data,
        string[] memory tokenURIs
    ) public onlyOwner {
        uint256[] memory ids = new uint256[](amounts.length);
        for (uint256 i = 0; i < amounts.length; i++) {
            tokenIds.increment();
            ids[i] = tokenIds.current();
        }

        _mintBatch(to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _setURI(ids[i], tokenURIs[i]);
        }
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function setURI(uint256 tokenId, string memory tokenURI) public onlyOwner {
        _setURI(tokenId, tokenURI);
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        _setBaseURI(_uri);
    }
}