// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MichaelMatternConstructiveImagery is 
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    AccessControl
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");

    uint256 public constant MIN_TOKEN_ID = 1;
    
    string private _contractUri;
    string private _baseUri;

    constructor(
        string memory contractUri,
        string memory baseUri
    ) ERC721("MichaelMatternConstructiveImagery", "MMCI") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);

        _setContractURI(contractUri);
        _setBaseURI(baseUri);
    }

    modifier canMint(
        uint256 tokenId
    )
    {
        require(tokenId >= MIN_TOKEN_ID, "TokenId needs to be >= MIN_TOKEN_ID");
        _;
    }

    function safeMint(
        address to,
        uint256 tokenId
    )
        public
        onlyRole(MINTER_ROLE)
        canMint(tokenId)
    {
        _safeMint(to, tokenId);
    }

    function contractURI() public view returns (string memory) {
        return _contractUri;
    }

    function setContractURI(
        string memory newContractUri
    )
        public
        onlyRole(URI_SETTER_ROLE)
    {
        _setContractURI(newContractUri);
    }

    function _setContractURI(
        string memory newContractUri
    ) 
        internal 
        virtual 
    {
        _contractUri = newContractUri;
    }

    function setBaseURI(
        string memory newBaseUri
    )
        public
        onlyRole(URI_SETTER_ROLE)
    {
        _setBaseURI(newBaseUri);
    }

    function _setBaseURI(
        string memory newBaseUri
    ) 
        internal 
        virtual 
    {
        _baseUri = newBaseUri;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseUri;
    }

    function burn(
        uint256 tokenId
    )
        public
        override
        onlyRole(BURNER_ROLE)
    {
        _burn(tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}