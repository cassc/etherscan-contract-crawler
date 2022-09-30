// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../../../common/WithdrawExtension.sol";
import "../../../common/LicenseExtension.sol";
import "../../../common/meta-transactions/ERC2771ContextOwnable.sol";
import "../../ERC721/extensions/ERC721RoyaltyExtension.sol";
import "../extensions/ERC721ACollectionMetadataExtension.sol";
import "../extensions/ERC721APrefixedMetadataExtension.sol";
import "../extensions/ERC721AMinterExtension.sol";
import "../extensions/ERC721AOwnerMintExtension.sol";
import "../extensions/ERC721ATieringExtension.sol";
import "../extensions/ERC721ARoleBasedMintExtension.sol";
import "../extensions/ERC721ARoleBasedLockableExtension.sol";

contract ERC721ATieredSalesCollection is
    Ownable,
    ERC165Storage,
    WithdrawExtension,
    LicenseExtension,
    ERC721ACollectionMetadataExtension,
    ERC721APrefixedMetadataExtension,
    ERC721AOwnerMintExtension,
    ERC721ATieringExtension,
    ERC721ARoleBasedMintExtension,
    ERC721ARoleBasedLockableExtension,
    ERC721RoyaltyExtension,
    ERC2771ContextOwnable
{
    struct Config {
        string name;
        string symbol;
        string contractURI;
        string placeholderURI;
        string tokenURIPrefix;
        uint256 maxSupply;
        Tier[] tiers;
        address defaultRoyaltyAddress;
        uint16 defaultRoyaltyBps;
        address proceedsRecipient;
        address trustedForwarder;
        LicenseVersion licenseVersion;
    }

    constructor(Config memory config) ERC721A(config.name, config.symbol) {
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
        __ERC721ACollectionMetadataExtension_init(
            config.name,
            config.symbol,
            config.contractURI
        );
        __ERC721APrefixedMetadataExtension_init(
            config.placeholderURI,
            config.tokenURIPrefix
        );
        __ERC721AMinterExtension_init(config.maxSupply);
        __ERC721AOwnerMintExtension_init();
        __ERC721ARoleBasedMintExtension_init(deployer);
        __ERC721ARoleBasedLockableExtension_init();
        __ERC721ATieringExtension_init(config.tiers);
        __ERC721RoyaltyExtension_init(
            config.defaultRoyaltyAddress,
            config.defaultRoyaltyBps
        );
        __ERC2771ContextOwnable_init(config.trustedForwarder);
    }

    function _msgSender()
        internal
        view
        virtual
        override(ERC2771ContextOwnable, Context)
        returns (address sender)
    {
        return ERC2771ContextOwnable._msgSender();
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC2771ContextOwnable, Context)
        returns (bytes calldata)
    {
        return ERC2771ContextOwnable._msgData();
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override(ERC721A, ERC721ALockableExtension) {
        ERC721ALockableExtension._beforeTokenTransfers(
            from,
            to,
            startTokenId,
            quantity
        );
    }

    /* PUBLIC */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC165Storage,
            ERC721ACollectionMetadataExtension,
            ERC721APrefixedMetadataExtension,
            ERC721AOwnerMintExtension,
            ERC721ARoleBasedMintExtension,
            ERC721RoyaltyExtension,
            ERC721ARoleBasedLockableExtension,
            LicenseExtension
        )
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    function name()
        public
        view
        override(ERC721A, ERC721ACollectionMetadataExtension)
        returns (string memory)
    {
        return ERC721ACollectionMetadataExtension.name();
    }

    function symbol()
        public
        view
        override(ERC721A, ERC721ACollectionMetadataExtension)
        returns (string memory)
    {
        return ERC721ACollectionMetadataExtension.symbol();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721A, ERC721APrefixedMetadataExtension)
        returns (string memory)
    {
        return ERC721APrefixedMetadataExtension.tokenURI(_tokenId);
    }

    function setMaxSupply(uint256 newValue)
        public
        virtual
        override(ERC721AMinterExtension, ERC721ATieringExtension)
        onlyOwner
    {
        ERC721ATieringExtension.setMaxSupply(newValue);
    }
}