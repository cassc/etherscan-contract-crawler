// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "../../../common/meta-transactions/ERC2771ContextOwnable.sol";
import "../extensions/ERC721CollectionMetadataExtension.sol";
import "../extensions/ERC721PerTokenMetadataExtension.sol";
import "../extensions/ERC721OneOfOneMintExtension.sol";
import "../extensions/ERC721AutoIdMinterExtension.sol";
import "../extensions/ERC721OwnerMintExtension.sol";
import "../extensions/ERC721RoyaltyExtension.sol";

contract ERC721OneOfOneCollection is
    Initializable,
    Ownable,
    ERC165Storage,
    ERC721PerTokenMetadataExtension,
    ERC721OwnerMintExtension,
    ERC721RoyaltyExtension,
    ERC721OneOfOneMintExtension,
    ERC2771ContextOwnable
{
    struct Config {
        string name;
        string symbol;
        string contractURI;
        uint256 maxSupply;
        address defaultRoyaltyAddress;
        uint16 defaultRoyaltyBps;
        address trustedForwarder;
    }

    constructor(Config memory config) ERC721(config.name, config.symbol) {
        initialize(config, msg.sender);
    }

    function initialize(Config memory config, address deployer)
        public
        initializer
    {
        _setupRole(DEFAULT_ADMIN_ROLE, deployer);
        _setupRole(MINTER_ROLE, deployer);

        _transferOwnership(deployer);

        __ERC721CollectionMetadataExtension_init(
            config.name,
            config.symbol,
            config.contractURI
        );
        __ERC721PerTokenMetadataExtension_init();
        __ERC721OwnerMintExtension_init();
        __ERC721OneOfOneMintExtension_init();
        __ERC721AutoIdMinterExtension_init(config.maxSupply);
        __ERC721RoyaltyExtension_init(
            config.defaultRoyaltyAddress,
            config.defaultRoyaltyBps
        );
        __ERC2771ContextOwnable_init(config.trustedForwarder);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721OneOfOneMintExtension, ERC721URIStorage)
    {
        return ERC721OneOfOneMintExtension._burn(tokenId);
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

    /* PUBLIC */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            ERC165Storage,
            ERC721OwnerMintExtension,
            ERC721OneOfOneMintExtension,
            ERC721PerTokenMetadataExtension,
            ERC721RoyaltyExtension
        )
        returns (bool)
    {
        return ERC165Storage.supportsInterface(interfaceId);
    }

    function name()
        public
        view
        override(
            ERC721,
            ERC721OneOfOneMintExtension,
            ERC721CollectionMetadataExtension
        )
        returns (string memory)
    {
        return ERC721CollectionMetadataExtension.name();
    }

    function symbol()
        public
        view
        override(
            ERC721,
            ERC721OneOfOneMintExtension,
            ERC721CollectionMetadataExtension
        )
        returns (string memory)
    {
        return ERC721CollectionMetadataExtension.symbol();
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        override(ERC721, ERC721OneOfOneMintExtension, ERC721URIStorage)
        returns (string memory)
    {
        return ERC721OneOfOneMintExtension.tokenURI(_tokenId);
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