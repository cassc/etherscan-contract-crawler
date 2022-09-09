// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../../../common/WithdrawExtension.sol";
import "../../../common/LicenseExtension.sol";
import "../../../common/meta-transactions/ERC2771ContextOwnable.sol";
import "../extensions/ERC721CollectionMetadataExtension.sol";
import "../extensions/ERC721PrefixedMetadataExtension.sol";
import "../extensions/ERC721AutoIdMinterExtension.sol";
import "../extensions/ERC721OwnerMintExtension.sol";
import "../extensions/ERC721PreSaleExtension.sol";
import "../extensions/ERC721PublicSaleExtension.sol";
import "../extensions/ERC721RoleBasedMintExtension.sol";
import "../extensions/ERC721RoyaltyExtension.sol";
import "../extensions/ERC721RoleBasedLockableExtension.sol";
import "../extensions/ERC721BulkifyExtension.sol";

contract ERC721SimpleSalesCollection is
    Initializable,
    Ownable,
    ERC165Storage,
    WithdrawExtension,
    LicenseExtension,
    ERC721PrefixedMetadataExtension,
    ERC721OwnerMintExtension,
    ERC721PreSaleExtension,
    ERC721PublicSaleExtension,
    ERC721RoleBasedMintExtension,
    ERC721RoleBasedLockableExtension,
    ERC721RoyaltyExtension,
    ERC2771ContextOwnable,
    ERC721BulkifyExtension
{
    struct Config {
        string name;
        string symbol;
        string contractURI;
        string placeholderURI;
        string tokenURIPrefix;
        uint256 maxSupply;
        uint256 preSalePrice;
        uint256 preSaleMaxMintPerWallet;
        uint256 publicSalePrice;
        uint256 publicSaleMaxMintPerTx;
        address defaultRoyaltyAddress;
        uint16 defaultRoyaltyBps;
        address proceedsRecipient;
        address trustedForwarder;
        LicenseVersion licenseVersion;
    }

    constructor(Config memory config) ERC721(config.name, config.symbol) {
        initialize(config, msg.sender);
    }

    function initialize(Config memory config, address deployer)
        public
        initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, deployer);

        _transferOwnership(deployer);

        __WithdrawExtension_init(config.proceedsRecipient, WithdrawMode.ANYONE);
        __LicenseExtension_init(config.licenseVersion);
        __ERC721CollectionMetadataExtension_init(
            config.name,
            config.symbol,
            config.contractURI
        );
        __ERC721PrefixedMetadataExtension_init(
            config.placeholderURI,
            config.tokenURIPrefix
        );
        __ERC721AutoIdMinterExtension_init(config.maxSupply);
        __ERC721OwnerMintExtension_init();
        __ERC721RoleBasedMintExtension_init(deployer);
        __ERC721RoleBasedLockableExtension_init();
        __ERC721PreSaleExtension_init_unchained(
            config.preSalePrice,
            config.preSaleMaxMintPerWallet
        );
        __ERC721PublicSaleExtension_init(
            config.publicSalePrice,
            config.publicSaleMaxMintPerTx
        );
        __ERC721RoyaltyExtension_init(
            config.defaultRoyaltyAddress,
            config.defaultRoyaltyBps
        );
        __ERC2771ContextOwnable_init(config.trustedForwarder);
        __ERC721BulkifyExtension_init();
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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721LockableExtension) {
        return ERC721LockableExtension._beforeTokenTransfer(from, to, tokenId);
    }

    /* PUBLIC */

    function name()
        public
        view
        override(ERC721, ERC721CollectionMetadataExtension)
        returns (string memory)
    {
        return ERC721CollectionMetadataExtension.name();
    }

    function symbol()
        public
        view
        override(ERC721, ERC721CollectionMetadataExtension)
        returns (string memory)
    {
        return ERC721CollectionMetadataExtension.symbol();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC165Storage,
            ERC721PrefixedMetadataExtension,
            ERC721PreSaleExtension,
            ERC721PublicSaleExtension,
            ERC721OwnerMintExtension,
            ERC721RoleBasedMintExtension,
            ERC721RoyaltyExtension,
            ERC721RoleBasedLockableExtension,
            ERC721BulkifyExtension,
            LicenseExtension
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