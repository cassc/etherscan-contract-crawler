// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title Moses Hosiery 1.0 x CHAIN/SAW

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

error Unauthorized();
error AlreadyFroze();

contract MosesHosieryV1 is ERC721Enumerable, ERC721URIStorage, ERC721Burnable, AccessControl {
    uint256 private nextTokenId;
    bytes32 public constant MINTER = keccak256("MINTER");
    mapping(uint256 => bool) public metadataFrozen;
    
    constructor() ERC721("MOSES HOSIERY 1.0 x CHAIN/SAW", "MOHOCO") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyOwner() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
            revert Unauthorized();
        _;
    }
    
    modifier onlyMinter() {
        if (!hasRole(MINTER, _msgSender()) && !hasRole(DEFAULT_ADMIN_ROLE, msg.sender))
            revert Unauthorized();
        _;
    }

    function mint(address to, string memory uri) public onlyMinter {
        uint256 tokenId = nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, string calldata _tokenURI) external onlyMinter {
        if (metadataFrozen[tokenId]) revert AlreadyFroze();
        _setTokenURI(tokenId, _tokenURI);
    }

    function freezeMetadata(uint256 tokenId) external onlyMinter {
        _requireMinted(tokenId);
        if(metadataFrozen[tokenId]) revert AlreadyFroze();
        metadataFrozen[tokenId] = true;
    }

    function addMinter(address minter) external onlyOwner {
        _setupRole(MINTER, minter);
    }

    function removeMinter(address minter) external onlyOwner {
        _revokeRole(MINTER, minter);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    } 

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}