// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract Sudelbucher is
    DefaultOperatorFilterer,
    ERC721,
    ERC721Enumerable,
    Ownable,
    ERC721Burnable
{
    uint256 private _tokenIdCounter;

    string private _baseUri;

    event Mint(address indexed _minter, uint256 _tokenId);

    constructor(string memory baseUri)
        ERC721("Sudelbucher", "SDLBCR")
    {
        _baseUri = baseUri;
    }

    function safeMint(address[] calldata to, uint8[] calldata amt) public onlyOwner {
        require(to.length == amt.length, "different param lengths");

        for (uint8 i = 0; i < to.length; i++) {
            for (uint j = 0; j < amt[i]; j++) {
                uint256 tokenId = _tokenIdCounter;
                _tokenIdCounter++;
                _safeMint(to[i], tokenId);
                emit Mint(msg.sender, tokenId);
            }
        }
    }

    // withdraw all ether from this contract to owner
    function withdraw() public onlyOwner {
        // get the amount of ether stored in this contract
        uint256 amount = address(this).balance;

        // send all ether to owner
        (bool success, ) = payable(owner()).call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        _baseUri = newBaseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    // OPENZEPPELIN GENERATED CODE: end

    // OPERATOR FILTERER: start
    function setApprovalForAll(address operator, bool approved) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
    // OPERATOR FILTERER: end
}