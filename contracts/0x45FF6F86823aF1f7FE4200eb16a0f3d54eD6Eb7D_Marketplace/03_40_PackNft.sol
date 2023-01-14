// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721RoyaltyUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';

import './eventListener/IEventListener.sol';

/// @title Pack NFT Contract
/// @notice Contract that implements ERC721Upgradeable token. Designed for minting new tokens

contract PackNft is
    ERC721Upgradeable,
    ERC721RoyaltyUpgradeable,
    ERC721URIStorageUpgradeable,
    AccessControlUpgradeable,
    OwnableUpgradeable
{
    string internal _baseTokenURI;
    string public uri;
    bytes32 public constant MARKETPLACE = keccak256('MARKETPLACE');
    IEventListener public eventListener;

    event SetTokenURI(uint256 tokenId, string _tokenURI);
    event SetBaseURI(string baseURI_);

    /// @dev Sets main dependencies in current implementation
    /// @param _name token name
    /// @param _symbol token symbol
    /// @param baseURI token base uri
    /// @param _uri token metadata uri
    /// @param feeCollector fee collector address

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory baseURI,
        string memory _uri,
        address feeCollector,
        address eventContract
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __Ownable_init();
        _baseTokenURI = baseURI;
        uri = _uri;
        _grantRole(MARKETPLACE, msg.sender);
        transferOwnership(feeCollector);
        eventListener = IEventListener(eventContract);
    }

    /// @dev Returns true if the id token exists
    /// @param tokenId token id

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    /// @dev Sets the royalty fee
    /// @param receiver fee receiver address
    /// @param feeNumerator new fee value

    function setRoyalty(address receiver, uint32 feeNumerator) external onlyOwner {
        require(feeNumerator <= 1000, 'Fee should be less or equal 10%.');
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    /// @dev Internal burn function
    /// @param tokenId token id

    function _burn(uint256 tokenId)
        internal
        override(ERC721Upgradeable, ERC721RoyaltyUpgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    /// @dev Sets the base URI
    /// @param baseURI_ Base path to metadata

    function setBaseURI(string memory baseURI_) public onlyOwner {
        _baseTokenURI = baseURI_;
        emit SetBaseURI(baseURI_);
    }

    /// @dev Sets the token URI
    /// @param tokenId token id
    /// @param _tokenURI token URI without base URI

    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyRole(MARKETPLACE) {
        super._setTokenURI(tokenId, _tokenURI);
        emit SetTokenURI(tokenId, _tokenURI);
    }

    /// @dev Get current base uri

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    /// @dev Get current token uri
    /// @param tokenId token id

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    /// @dev Mint new ERC721 token id
    /// @param to address of the recipient of the token
    /// @param tokenId new token id

    function safeMint(address to, uint256 tokenId) external onlyRole(MARKETPLACE) {
        _safeMint(to, tokenId);
        setTokenURI(tokenId, uri);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable) {
        eventListener.callEvent(from, to, tokenId);
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721RoyaltyUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}