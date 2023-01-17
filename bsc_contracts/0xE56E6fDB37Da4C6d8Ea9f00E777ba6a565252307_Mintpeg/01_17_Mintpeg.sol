// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./MintpegErrors.sol";

/// @title Mintpeg Contract
/// @author Trader Joe
/// @notice ERC721 contracts for artists to mint NFTs
contract Mintpeg is
    ERC721URIStorageUpgradeable,
    ERC2981Upgradeable,
    OwnableUpgradeable
{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    /// @notice Emmited on setRoyaltyInfo()
    /// @param royaltyReceiver Royalty fee collector
    /// @param feePercent Royalty fee numerator; denominator is 10,000. So 500 represents 5%
    event RoyaltyInfoChanged(
        address indexed royaltyReceiver,
        uint96 feePercent
    );

    /// @notice Emmited on setTokenRoyaltyInfo()
    /// @param tokenId Token ID royalty to be set
    /// @param royaltyReceiver Royalty fee collector
    /// @param feePercent Royalty fee numerator; denominator is 10,000. So 500 represents 5%
    event TokenRoyaltyInfoChanged(
        uint256 tokenId,
        address indexed royaltyReceiver,
        uint96 feePercent
    );

    /// @notice Emmited on initialize()
    /// @param _collectionName ERC721 name
    /// @param _collectionSymbol ERC721 symbol
    /// @param _projectOwner function caller
    /// @param _royaltyReceiver Royalty fee collector
    /// @param _feePercent Royalty fee numerator; denominator is 10,000. So 500 represents 5%
    event InitializedMintpeg(
        string indexed _collectionName,
        string indexed _collectionSymbol,
        address indexed _projectOwner,
        address _royaltyReceiver,
        uint96 _feePercent
    );

    /// @notice Mintpeg initialization
    /// @param _collectionName ERC721 name
    /// @param _collectionSymbol ERC721 symbol
    /// @param _royaltyReceiver Royalty fee collector
    /// @param _feePercent Royalty fee numerator; denominator is 10,000. So 500 represents 5%
    function initialize(
        string memory _collectionName,
        string memory _collectionSymbol,
        address _projectOwner,
        address _royaltyReceiver,
        uint96 _feePercent
    ) external initializer {
        __Ownable_init();
        __ERC2981_init();
        __ERC721_init(_collectionName, _collectionSymbol);
        setRoyaltyInfo(_royaltyReceiver, _feePercent);
        transferOwnership(_projectOwner);

        emit InitializedMintpeg(
            _collectionName,
            _collectionSymbol,
            msg.sender,
            _royaltyReceiver,
            _feePercent
        );
    }

    /// @notice Function to mint new tokens
    /// @dev Can only be called by project owner
    /// @param _tokenURIs Array of tokenURIs (probably IPFS) of the tokenIds to be minted
    function mint(string[] memory _tokenURIs) external onlyOwner {
        uint256 newTokenId;
        for (uint256 i = 0; i < _tokenURIs.length; i++) {
            newTokenId = _tokenIds.current();
            _tokenIds.increment();
            _mint(msg.sender, newTokenId);
            _setTokenURI(newTokenId, _tokenURIs[i]);
        }
    }

    /// @notice Function for changing royalty information
    /// @dev Can only be called by project owner
    /// @dev owner can prevent any sale by setting the address to any address that can't receive AVAX.
    /// @param _royaltyReceiver Royalty fee collector
    /// @param _feePercent Royalty fee numerator; denominator is 10,000. So 500 represents 5%
    function setRoyaltyInfo(address _royaltyReceiver, uint96 _feePercent)
        public
        onlyOwner
    {
        // Royalty fees are limited to 25%
        if (_feePercent > 2_500) {
            revert Mintpeg__InvalidRoyaltyInfo();
        }
        _setDefaultRoyalty(_royaltyReceiver, _feePercent);
        emit RoyaltyInfoChanged(_royaltyReceiver, _feePercent);
    }

    /// @notice Function for changing token royalty information
    /// @dev Can only be called by project owner
    /// @dev owner can prevent any sale by setting the address to any address that can't receive AVAX.
    /// @param _tokenId Token ID royalty to be set
    /// @param _royaltyReceiver Royalty fee collector
    /// @param _feePercent Royalty fee numerator; denominator is 10,000. So 500 represents 5%
    function setTokenRoyaltyInfo(
        uint256 _tokenId,
        address _royaltyReceiver,
        uint96 _feePercent
    ) public onlyOwner {
        // Royalty fees are limited to 25%
        if (_feePercent > 2_500) {
            revert Mintpeg__InvalidRoyaltyInfo();
        }
        _setTokenRoyalty(_tokenId, _royaltyReceiver, _feePercent);
        emit TokenRoyaltyInfoChanged(_tokenId, _royaltyReceiver, _feePercent);
    }

    /// @notice Function to burn a token
    /// @dev Can only be called by token owner
    /// @param _tokenId Token ID to be burnt
    function burn(uint256 _tokenId) external {
        if (ownerOf(_tokenId) != msg.sender) {
            revert Mintpeg__InvalidTokenOwner();
        }
        super._burn(_tokenId);
        _resetTokenRoyalty(_tokenId);
    }

    /// @notice Returns true if this contract implements the interface defined by `interfaceId`
    /// @dev Needs to be overridden cause two base contracts implement it
    /// @param _interfaceId InterfaceId to consider. Comes from type(InterfaceContract).interfaceId
    /// @return bool True if the considered interface is supported
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(_interfaceId) ||
            ERC2981Upgradeable.supportsInterface(_interfaceId) ||
            super.supportsInterface(_interfaceId);
    }
}