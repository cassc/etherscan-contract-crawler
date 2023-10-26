// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// BadBugBear Figure Collection

contract BadBugBearFigure is ERC721A, Ownable {
    string public baseURI;
    uint256 private initialSupply;
    mapping(uint256 => string) private _tokenURIs;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseUri,
        uint256 _initialSupply
    ) ERC721A(name, symbol) {
        baseURI = baseUri;
        initialSupply = _initialSupply;
    }

    function mintBatch(uint256 quantity) external onlyOwner {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(quantity > 0, "Not enough quantity to mint!");
        require(
            _totalMinted() + quantity <= initialSupply,
            "cannot batch mint more than initial supply!"
        );
        _safeMint(msg.sender, quantity);
    }

    function mintSingle(string memory uri) external onlyOwner {
        require(
            _totalMinted() >= initialSupply,
            "initial supply must be batch minted before using single mint functionality!"
        );
        uint256 tokenId = _totalMinted();
        _safeMint(msg.sender, 1);
        _setTokenURI(tokenId, uri);
    }

    function batchNFTsTransfer(
        address[] memory addresses,
        uint256[] memory tokens
    ) external onlyOwner {
        require(
            addresses.length == tokens.length,
            "Fields length does not match!"
        );
        for (uint256 i = 0; i < tokens.length; i++) {
            super.transferFrom(msg.sender, addresses[i], tokens[i]);
        }
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI)
        internal
        virtual
    {
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory _tokenURI = _tokenURIs[tokenId];
        if (bytes(_tokenURI).length > 0) {
            return string(_tokenURI);
        }

        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : "";
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    function burnToken(uint256 tokenId) external onlyOwner {
        _burn(tokenId, true);
    }
}