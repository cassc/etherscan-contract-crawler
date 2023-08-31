// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../../../common/meta-transactions/ERC2771ContextOwnable.sol";
import "../extensions/ERC721CollectionMetadataExtension.sol";
import "../extensions/ERC721PrefixedMetadataExtension.sol";
import "../extensions/ERC721AutoIdMinterExtension.sol";
import "../extensions/ERC721OwnerMintExtension.sol";
import "../extensions/ERC721PreSaleExtension.sol";
import "../extensions/ERC721PublicSaleExtension.sol";
import "../extensions/ERC721SimpleProceedsExtension.sol";
import "../extensions/ERC721RoleBasedMintExtension.sol";
import "../extensions/ERC721RoyaltyExtension.sol";
import "../extensions/ERC721BulkifyExtension.sol";
import "../extensions/ERC721OpenSeaNoGasExtension.sol";

contract ERC721FullFeaturedCollection is
    Ownable,
    ERC165Storage,
    ERC721,
    ERC2771ContextOwnable,
    ERC721CollectionMetadataExtension,
    ERC721PrefixedMetadataExtension,
    ERC721AutoIdMinterExtension,
    ERC721OwnerMintExtension,
    ERC721PreSaleExtension,
    ERC721PublicSaleExtension,
    ERC721SimpleProceedsExtension,
    ERC721RoleBasedMintExtension,
    ERC721RoyaltyExtension,
    ERC721OpenSeaNoGasExtension,
    ERC721BulkifyExtension
{
    struct Config {
        string name;
        string symbol;
        string contractURI;
        string placeholderURI;
        uint256 maxSupply;
        uint256 preSalePrice;
        uint256 preSaleMaxMintPerWallet;
        uint256 publicSalePrice;
        uint256 publicSaleMaxMintPerTx;
        address defaultRoyaltyAddress;
        uint16 defaultRoyaltyBps;
        address openSeaProxyRegistryAddress;
        address openSeaExchangeAddress;
        address trustedForwarder;
    }

    constructor(Config memory config)
        ERC721(config.name, config.symbol)
        ERC721CollectionMetadataExtension(config.contractURI)
        ERC721PrefixedMetadataExtension(config.placeholderURI)
        ERC721AutoIdMinterExtension(config.maxSupply)
        ERC721PreSaleExtension(
            config.preSalePrice,
            config.preSaleMaxMintPerWallet
        )
        ERC721PublicSaleExtension(
            config.publicSalePrice,
            config.publicSaleMaxMintPerTx
        )
        ERC721RoyaltyExtension(
            config.defaultRoyaltyAddress,
            config.defaultRoyaltyBps
        )
        ERC721OpenSeaNoGasExtension(
            config.openSeaProxyRegistryAddress,
            config.openSeaExchangeAddress
        )
        ERC2771ContextOwnable(config.trustedForwarder)
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
    }

    function _msgSender()
        internal
        view
        virtual
        override(ERC2771ContextOwnable, Context)
        returns (address sender)
    {
        return super._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC2771ContextOwnable, Context)
        returns (bytes calldata)
    {
        return super._msgData();
    }

    // PUBLIC

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC165Storage,
            ERC721,
            ERC721CollectionMetadataExtension,
            ERC721PrefixedMetadataExtension,
            ERC721AutoIdMinterExtension,
            ERC721PreSaleExtension,
            ERC721PublicSaleExtension,
            ERC721SimpleProceedsExtension,
            ERC721OwnerMintExtension,
            ERC721RoleBasedMintExtension,
            ERC721RoyaltyExtension,
            ERC721OpenSeaNoGasExtension,
            ERC721BulkifyExtension
        )
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) ||
            ERC165Storage.supportsInterface(interfaceId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721, ERC721OpenSeaNoGasExtension)
        returns (bool)
    {
        return super.isApprovedForAll(owner, operator);
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721, ERC721PrefixedMetadataExtension)
        returns (string memory)
    {
        return ERC721PrefixedMetadataExtension.tokenURI(_tokenId);
    }

    function getInfo()
        external
        view
        returns (
            uint256 _maxSupply,
            uint256 _totalSupply,
            uint256 _senderBalance,
            uint256 _preSalePrice,
            uint256 _preSaleMaxMintPerWallet,
            uint256 _preSaleAlreadyClaimed,
            bool _preSaleActive,
            uint256 _publicSalePrice,
            uint256 _publicSaleMaxMintPerTx,
            bool _publicSaleActive
        )
    {
        uint256 balance = 0;

        if (_msgSender() != address(0)) {
            balance = this.balanceOf(_msgSender());
        }

        return (
            maxSupply,
            this.totalSupply(),
            balance,
            preSalePrice,
            preSaleMaxMintPerWallet,
            preSaleAllowlistClaimed[_msgSender()],
            preSaleStatus,
            publicSalePrice,
            publicSaleMaxMintPerTx,
            publicSaleStatus
        );
    }
}