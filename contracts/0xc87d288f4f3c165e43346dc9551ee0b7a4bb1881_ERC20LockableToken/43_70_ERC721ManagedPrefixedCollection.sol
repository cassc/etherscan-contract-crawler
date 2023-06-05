// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../../../common/meta-transactions/ERC2771ContextOwnable.sol";
import "../extensions/ERC721CollectionMetadataExtension.sol";
import "../extensions/ERC721PrefixedMetadataExtension.sol";
import "../extensions/ERC721AutoIdMinterExtension.sol";
import "../extensions/ERC721OwnerMintExtension.sol";
import "../extensions/ERC721OwnerManagedExtension.sol";
import "../extensions/ERC721BulkifyExtension.sol";

contract ERC721ManagedPrefixedCollection is
    Initializable,
    Ownable,
    ERC165Storage,
    ERC2771ContextOwnable,
    ERC721CollectionMetadataExtension,
    ERC721PrefixedMetadataExtension,
    ERC721AutoIdMinterExtension,
    ERC721OwnerMintExtension,
    ERC721OwnerManagedExtension,
    ERC721BulkifyExtension
{
    struct Config {
        string name;
        string symbol;
        string contractURI;
        string baseURI;
        string placeholderURI;
        address[] initialHolders;
        uint256[] initialAmounts;
        uint256 maxSupply;
        address trustedForwarder;
    }

    constructor(Config memory config)
        ERC721(config.name, config.symbol)
        ERC721CollectionMetadataExtension(config.contractURI)
        ERC721PrefixedMetadataExtension(config.placeholderURI)
        ERC721AutoIdMinterExtension(maxSupply)
        ERC2771ContextOwnable(config.trustedForwarder)
    {
        initialize(config);
    }

    function initialize(Config memory config) public initializer {
        require(
            config.initialHolders.length == config.initialAmounts.length,
            "ERC721/INVALID_INITIAL_ARGS"
        );

        maxSupply = config.maxSupply;

        for (uint256 i = 0; i < config.initialHolders.length; i++) {
            _mintTo(config.initialHolders[i], config.initialAmounts[i]);
        }

        _baseTokenURI = config.baseURI;
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

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override(ERC721, ERC721OwnerManagedExtension)
        returns (bool)
    {
        return ERC721OwnerManagedExtension.isApprovedForAll(owner, operator);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC165Storage,
            ERC721AutoIdMinterExtension,
            ERC721CollectionMetadataExtension,
            ERC721OwnerMintExtension,
            ERC721OwnerManagedExtension,
            ERC721PrefixedMetadataExtension,
            ERC721BulkifyExtension
        )
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
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
            uint256 _senderBalance
        )
    {
        uint256 balance = 0;

        if (_msgSender() != address(0)) {
            balance = this.balanceOf(_msgSender());
        }

        return (maxSupply, this.totalSupply(), balance);
    }
}