// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "solmate/tokens/ERC721.sol";
import "solmate/auth/Owned.sol";

contract Kram is Owned, ERC721 {
    string public baseURI;
    string public suffix;

    constructor(
        string memory name,
        string memory symbol,
        string memory _baseURI,
        string memory _suffix
    ) ERC721(name, symbol) Owned(msg.sender) {
        baseURI = _baseURI;
        suffix = _suffix;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        ownerOf(id);
        return string(abi.encodePacked(baseURI, id, suffix));
    }

    function setName(string memory _name) external onlyOwner {
        name = _name;
    }

    function setSymbol(string memory _symbol) external onlyOwner {
        symbol = _symbol;
    }

    function setURIComponents(string memory _baseURI, string memory _suffix)
        external
        onlyOwner
    {
        baseURI = _baseURI;
        suffix = _suffix;
    }

    function mint(uint256 tokenId) external onlyOwner {
        _mint(msg.sender, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override
        returns (bool)
    {
        return
            interfaceId == 0x7f5828d0 || // ERC165 Interface ID for ERC173
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC165
            interfaceId == 0x01ffc9a7; // ERC165 Interface ID for ERC721Metadata
    }
}