// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../lib/Base64.sol";
import "../lib/GranularRoles.sol";
import "../lib/Config.sol";
import "../lib/ITemplate.sol";

/*
 * ERC-721 proxy contract, meaning it does not make use of a constructor but rather uses `initialize` with `initializer`
 * modifier, see {Initializable}
 *
 * Minting and other write transactions only supported for accounts with relevant access rights.
 */
contract ERC721NFTProduct is
    ERC721URIStorageUpgradeable,
    GranularRoles,
    ITemplate,
    ReentrancyGuardUpgradeable
{
    /*******************************
     * Extensions, structs, events *
     *******************************/

    using StringsUpgradeable for uint256;

    /*
     * Event emitted to show opensea that metadata of a token is frozen,
     * see https://docs.opensea.io/docs/metadata-standards
     */
    event PermanentURI(string _value, uint256 indexed _id);
    // Event emitted to show that all tokens have their metadata frozen
    event PermanentURIGlobal();

    /*************
     * Constants *
     *************/

    // Template name
    string public constant NAME = "ERC721NFTProduct";
    // Template version
    uint256 public constant VERSION = 1_01_00;
    // Basis for calculating royalties.
    // This has to be 10k for royaltiesBps to be in basis points.
    uint16 public constant ROYALTIES_BASIS = 10000;

    /********************
     * Public variables *
     ********************/

    // If true then tokens metadata can be updated
    bool public metadataUpdatable;
    // If true then tokens can be burned by their owners
    bool public tokensBurnable;
    // If true then tokens can be transferred by having the correct access rights {GranularRoles-TRANSFER_ROLE}
    // if the token is owned by {GranularRoles-_owner} address
    bool public tokensTransferable;

    // Mapping of individually frozen tokens
    mapping(uint256 => bool) public freezeTokenUris;

    // Base URI of the tokens, token URIs are calculated as baseURI + tokenURI
    string public baseURI;

    // Address where royalties will be transferred to
    address public royaltiesAddress;
    // Secondary market royalties in basis points (100 bps = 1%). Royalties use ERC2981 standard and support
    // OpenSea standard.
    uint256 public royaltiesBasisPoints;

    // Counter for the total number of tokens minted in this contract
    uint256 public totalSupply;

    /***************************
     * Contract initialization *
     ***************************/

    constructor() initializer {
        // solhint-disable-previous-line no-empty-blocks
    }

    // Can only be called once, used because constructors cannot be used for proxy contracts
    function initialize(
        Config.Deployment memory deploymentConfig,
        Config.Runtime memory runtimeConfig,
        RolesAddresses[] memory rolesAddresses
    ) public initializer {
        // @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
        __ERC721_init(deploymentConfig.name, deploymentConfig.symbol);
        __ReentrancyGuard_init();

        _setRoyalties(
            runtimeConfig.royaltiesAddress,
            runtimeConfig.royaltiesBps
        );

        metadataUpdatable = runtimeConfig.metadataUpdatable;
        tokensBurnable = deploymentConfig.tokensBurnable;
        tokensTransferable = runtimeConfig.tokensTransferable;

        baseURI = runtimeConfig.baseURI;

        _initRoles(deploymentConfig.owner, rolesAddresses);
    }

    /*******************
     * Write functions *
     *******************/

    // Mint a token to input `caller` address
    function mintToCaller(
        address caller,
        uint256 tokenId,
        string memory tokenURI
    ) public onlyRole(MINT_ROLE) nonReentrant returns (uint256) {
        _safeMint(caller, tokenId);
        totalSupply += 1;

        _setTokenURI(tokenId, tokenURI);

        return tokenId;
    }

    /*
     * Function to update token URIs for individual tokens,
     * can be used to update and optionally freeze token URIs
     *
     * only callable if `metadataUpdatable` is true, the medatadata
     * for the token has not been frozen previously and the caller has `UPDATE_TOKEN_ROLE` (or `ADMIN_ROLE`) role
     */
    function updateTokenUri(
        uint256 _tokenId,
        string memory _tokenUri,
        bool _isFreezeTokenUri
    ) public onlyRole(UPDATE_TOKEN_ROLE) {
        require(_exists(_tokenId), "Token: Token does not exist");
        require(metadataUpdatable, "Token: Metadata is frozen");
        require(freezeTokenUris[_tokenId] != true, "Token: Token is frozen");
        require(
            _isFreezeTokenUri || (bytes(_tokenUri).length != 0),
            "Token: Token URI is missing"
        );

        if (bytes(_tokenUri).length != 0) {
            _setTokenURI(_tokenId, _tokenUri);
        }

        if (_isFreezeTokenUri) {
            freezeTokenUris[_tokenId] = true;
            emit PermanentURI(tokenURI(_tokenId), _tokenId);
        }
    }

    /*
     * Function to transfer tokens owned by the `_owner` address.
     *
     * only callable if `tokensTransferable` is true, the token to be transferred
     * is owned by `_owner` and the caller has `TRANSFER_ROLE` (or `ADMIN_ROLE`) role
     */
    function transferByOwner(address _to, uint256 _tokenId)
        public
        onlyRole(TRANSFER_ROLE)
    {
        require(tokensTransferable, "Transfer: Transfers are disabled");
        _safeTransfer(_owner, _to, _tokenId, "");
    }

    /*
     * Function to burn tokens owned by the `_owner` address.
     *
     * only callable if `tokensBurnable` is true, the token to be burned
     * is owned by `_owner` and the caller has `BURN_ROLE` (or `ADMIN_ROLE`) role
     */
    function burn(uint256 _tokenId) public onlyRole(BURN_ROLE) {
        require(tokensBurnable, "Burn: Burns are disabled");
        require(_exists(_tokenId), "Burn: Token does not exist");
        require(
            ERC721Upgradeable.ownerOf(_tokenId) == _owner,
            "Burn: not held by contract owner"
        );

        _burn(_tokenId);
        totalSupply -= 1;
    }

    /*
     * Function to update the collection configuration.
     *
     * Only callable if `metadataUpdatable` is true, or `baseURI` is not updated.
     * The ability to transfer tokens or update metadata can only be turned OFF with this, not vice-versa.
     *
     * This can also be used to revoke NFTPort access to the contract,
     * meaning access rights for NFTPort account will be removed.
     */
    function update(
        Config.Runtime calldata newConfig,
        RolesAddresses[] memory rolesAddresses,
        bool isRevokeNFTPortPermissions
    ) public onlyRole(UPDATE_CONTRACT_ROLE) {
        // If metadata is frozen, baseURI cannot be updated
        require(
            metadataUpdatable ||
                (keccak256(abi.encodePacked(newConfig.baseURI)) ==
                    keccak256(abi.encodePacked(baseURI))),
            "Update: Metadata is frozen"
        );

        baseURI = newConfig.baseURI;
        _setRoyalties(newConfig.royaltiesAddress, newConfig.royaltiesBps);

        if (!newConfig.tokensTransferable) {
            tokensTransferable = false;
        }
        if (!newConfig.metadataUpdatable && metadataUpdatable) {
            metadataUpdatable = false;
            emit PermanentURIGlobal();
        }

        _updateRoles(rolesAddresses);

        if (isRevokeNFTPortPermissions) {
            revokeNFTPortPermissions();
        }
    }

    /******************
     * View functions *
     ******************/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId;
    }

    // @dev ERC2981 token royalty info
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address, uint256)
    {
        return (
            royaltiesAddress,
            (royaltiesBasisPoints * salePrice) / ROYALTIES_BASIS
        );
    }

    /**
     * @dev OpenSea contract metadata, returns a base64 encoded JSON string containing royalties basis points
     * and royalties address
     */
    function contractURI() external view returns (string memory) {
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"seller_fee_basis_points": ', // solhint-disable-line quotes
                        royaltiesBasisPoints.toString(),
                        ', "fee_recipient": "', // solhint-disable-line quotes
                        uint256(uint160(royaltiesAddress)).toHexString(20),
                        '"}' // solhint-disable-line quotes
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    /*************
     * Internals *
     *************/

    function _baseURI()
        internal
        view
        virtual
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return baseURI;
    }

    function _setRoyalties(address newAddress, uint newBps) internal {
        require(newBps <= ROYALTIES_BASIS, "Cannot set royalties to over 100%");

        royaltiesAddress = newAddress;
        royaltiesBasisPoints = newBps;
    }
}