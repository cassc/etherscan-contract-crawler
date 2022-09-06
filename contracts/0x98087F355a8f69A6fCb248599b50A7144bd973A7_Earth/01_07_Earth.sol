// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Earth is Ownable, ERC721AQueryable {
    // ============ State Variables ============

    string public _baseTokenURI;
    string public hiddenMetadataUri;
    bool public revealed;
    string private _name;
    string private _symbol;
    string public uriSuffix;

    // ============ Constructor ============

    constructor(string memory __name, string memory __symbol, string memory _hiddenMetadataUri) ERC721A(__name, __symbol) {
        _name = __name;
        _symbol = __symbol;
        hiddenMetadataUri = _hiddenMetadataUri;
        _mint(0x77A4e81f999DcBB7677674565Ed525a9a3de266F, 77);
    }

    // ============ Core Functions ============

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override(IERC721A, ERC721A) returns (string memory) {
        require(_exists(tokenId), "ERC721AMetadata: URI query for nonexistent token");

        if (revealed == false) {
            return hiddenMetadataUri;
        }

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), uriSuffix)) : hiddenMetadataUri;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function withdraw() external onlyOwner {
        address _owner = owner();
        uint256 amount = address(this).balance;
        (bool sent, ) =  _owner.call{value: amount}("");
        require(sent, "Failed to send Ether");
    }

    function name() public view virtual override(IERC721A, ERC721A) returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override(IERC721A, ERC721A) returns (string memory) {
        return _symbol;
    }

    // ============ Setters (OnlyOwner) ============

    function setURISuffix(string memory _uriSuffix) external onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setBaseURI(string memory baseTokenURI) external onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    function setRevealed(bool _state) external onlyOwner {
        revealed = _state;
    }

    function setNameAndSymbol(string memory __name, string memory __symbol) external onlyOwner {
        _name = __name;
        _symbol = __symbol;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) external onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    receive() external payable {}

    fallback() external payable {}
}