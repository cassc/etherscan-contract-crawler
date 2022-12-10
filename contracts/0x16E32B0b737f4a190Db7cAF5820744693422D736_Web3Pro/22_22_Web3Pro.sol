// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import {ERC721URIStorageUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";

import {ERC721RoyaltyUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

contract Web3Pro is
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    ERC721RoyaltyUpgradeable,
    OwnableUpgradeable,
    AccessControlUpgradeable
{
    event BaseURIChanged(string previousURI, string newURI);
    event RoyaltyFeeChanged(uint256 previousFee, uint256 newFee);
    event NftMinted(uint256 ID, string tokenURI, address owner);
    string private _baseTokenURI;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function initialize(string calldata tokenName, string calldata tokenSymbol)
        external
        initializer
    {
        __ERC721_init(tokenName, tokenSymbol);
        __Ownable_init();
        __AccessControl_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function setRoyalties(address recipient, uint96 royaltyFee)
        external
        onlyOwner
    {
        _setDefaultRoyalty(recipient, royaltyFee);
        emit RoyaltyFeeChanged(royaltyFee, royaltyFee);
    }

     function safeMint(address to, string memory uri) public onlyOwner {
         _tokenIds.increment();
        uint256 ID = _tokenIds.current();
        _safeMint(to, ID);
        _setTokenURI(ID, uri);
        emit NftMinted(ID, uri,to);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC721Upgradeable,
            ERC721EnumerableUpgradeable,
            ERC721RoyaltyUpgradeable,
            AccessControlUpgradeable
        )
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC721EnumerableUpgradeable.supportsInterface(interfaceId) ||
            ERC721RoyaltyUpgradeable.supportsInterface(interfaceId) ||
            AccessControlUpgradeable.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);
    }

    function _burn(uint256 tokenId)
        internal
        override(
            ERC721Upgradeable,
            ERC721URIStorageUpgradeable,
            ERC721RoyaltyUpgradeable
        )
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function mint(
        string calldata tokenURL
    ) external  onlyRole(MINTER_ROLE) {
        _tokenIds.increment();
        uint256 ID = _tokenIds.current();
        
        _safeMint(msg.sender, ID);
        _setTokenURI(ID, tokenURL);
        emit NftMinted(ID, tokenURL,msg.sender);
    }

    function addMinter(address newAddress) external onlyOwner {
        _setupRole(MINTER_ROLE, newAddress);
    }

    function setTokenURI(uint256 tokenId, string calldata tokenURL)
        external
        onlyOwner
    {
        _setTokenURI(tokenId, tokenURL);
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function setBaseTokenURI(string calldata uri) external onlyOwner {
        _setBaseTokenURI(uri);
    }

    function _setBaseTokenURI(string memory newURI) internal {
        _baseTokenURI = newURI;
        emit BaseURIChanged(_baseTokenURI, newURI);
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}