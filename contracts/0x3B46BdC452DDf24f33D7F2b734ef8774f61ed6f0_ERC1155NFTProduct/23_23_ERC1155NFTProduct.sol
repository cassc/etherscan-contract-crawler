// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../lib/GranularRoles.sol";
import "../lib/Base64.sol";
import "../lib/Config.sol";
import "../lib/ITemplate.sol";

/*
 * ERC-1155 proxy contract, meaning it does not make use of a constructor,
 * but rather uses `initialize` with `initializer` modifier, see {Initializable}
 *
 * Minting and other write transactions only supported for accounts with relevant access rights.
 */
contract ERC1155NFTProduct is
    ERC1155Upgradeable,
    GranularRoles,
    ITemplate,
    ReentrancyGuardUpgradeable
{
    /*******************************
     * Extensions, structs, events *
     *******************************/

    using Strings for uint256;

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
    string public constant NAME = "ERC1155NFTProduct";
    // Template version
    uint256 public constant VERSION = 1_00_01;

    // Basis for calculating royalties.
    // This has to be 10k for royaltiesBps to be in basis points.
    uint16 public constant ROYALTIES_BASIS = 10000;
    // Default URI for tokens, each minted token will have a token URI, so default URI is empty
    string public constant DEFAULT_URI = "";

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

    // Token name
    string public name;
    // Token symbol
    string public symbol;
    // Token IDs are returned as `baseURI` + `tokenURI`
    string public baseURI;

    // Address where royalties will be transferred to
    address public royaltiesAddress;
    // Secondary market royalties in basis points (100 bps = 1%). Royalties use ERC2981 standard and support
    // OpenSea standard.
    uint256 public royaltiesBasisPoints;

    // Mapping of individually frozen tokens
    mapping(uint256 => bool) public freezeTokenUris;
    // Mapping of token ID to supply
    mapping(uint256 => uint256) public tokenSupply;

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
        __ERC1155_init(DEFAULT_URI);
        __ReentrancyGuard_init();

        _setRoyalties(
            runtimeConfig.royaltiesAddress,
            runtimeConfig.royaltiesBps
        );

        metadataUpdatable = runtimeConfig.metadataUpdatable;
        tokensBurnable = deploymentConfig.tokensBurnable;
        tokensTransferable = runtimeConfig.tokensTransferable;

        name = deploymentConfig.name;
        symbol = deploymentConfig.symbol;
        baseURI = runtimeConfig.baseURI;

        _initRoles(deploymentConfig.owner, rolesAddresses);
    }

    /*******************
     * Write functions *
     *******************/

    // Allows to set a default URI for tokens, which is only returned if token URI does not exist for given token ID
    function setURI(string memory _newURI)
        public
        onlyRole(UPDATE_CONTRACT_ROLE)
    {
        _setURI(_newURI);
    }

    /*
     * Allows to update token URI for given `_tokenId` and freeze it.
     * For the transaction to succeed either `_newUri` or `_isFreezeTokenUri` as true must be specified, or both.
     * The `_newURI` cannot be the same as the current URI for the token.
     *
     * Token ID must exist, `metadataUpdatable` must be true and token URI for given token cannot be frozen.
     * Only callable by accounts with `UPDATE_TOKEN_ROLE` or `ADMIN_ROLE`.
     */
    function updateTokenUri(
        uint256 _tokenId,
        string memory _newUri,
        bool _isFreezeTokenUri
    ) public onlyRole(UPDATE_TOKEN_ROLE) {
        require(_exists(_tokenId), "Token does not exist");
        require(metadataUpdatable, "Metadata is frozen");
        require(freezeTokenUris[_tokenId] != true, "Token is frozen");
        require(
            _isFreezeTokenUri || (bytes(_newUri).length != 0),
            "Either _newUri or _isFreezeTokenUri=true required"
        );

        if (bytes(_newUri).length != 0) {
            require(
                keccak256(bytes(_tokenURIs[_tokenId])) !=
                    keccak256(bytes(string(abi.encodePacked(_newUri)))),
                "New token URI is same as updated"
            );
            _tokenURIs[_tokenId] = _newUri;
            emit URI(_newUri, _tokenId);
        }
        if (_isFreezeTokenUri) {
            freezeTokenUris[_tokenId] = true;
            emit PermanentURI(_tokenURIs[_tokenId], _tokenId);
        }
    }

    /*
     * Allows to burn given `value` amount of tokens with `id`.
     * `tokensBurnable` must be true in order for the transaction to succeed and
     * at least `value` amount of tokens must exist.
     * Only callable by accounts with `BURN_ROLE` or `ADMIN_ROLE`.
     */
    function burn(uint256 id, uint256 value) public onlyRole(BURN_ROLE) {
        require(tokensBurnable, "Burns are disabled");

        _burn(_owner, id, value);
        tokenSupply[id] -= value;
    }

    /*
     * Same functionality as `burn` but for a batch of tokens.
     * Input `ids` and `values` must be in direct correlation,
     * an index in both lists referring to the same token.
     */
    function burnBatch(uint256[] memory ids, uint256[] memory values)
        public
        onlyRole(BURN_ROLE)
    {
        require(tokensBurnable, "Burns are disabled");
        _burnBatch(_owner, ids, values);
        for (uint256 i = 0; i < ids.length; i++) {
            tokenSupply[ids[i]] -= values[i];
        }
    }

    /*
     * Allows to transfer given `value` amount of tokens with `id`.
     * `tokensTransferable` must be true and the tokens to be transferred must be owned by the `_owner`,
     * at least `value` amount of tokens must exist.
     * Only callable by accounts with `TRANSFER_ROLE` or `ADMIN_ROLE`.
     */
    function transferByOwner(
        address to,
        uint256 id,
        uint256 amount
    ) public onlyRole(TRANSFER_ROLE) {
        require(tokensTransferable, "Transfers are disabled");
        _safeTransferFrom(_owner, to, id, amount, "");
    }

    /*
     * Same functionality as `transferByOwner` but for a batch of tokens.
     * Input `ids` and `values` must be in direct correlation,
     * an index in both lists referring to the same token.
     */
    function transferByOwnerBatch(
        address[] memory to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public onlyRole(TRANSFER_ROLE) {
        require(tokensTransferable, "Transfers are disabled");
        require(
            to.length == ids.length && ids.length == amounts.length,
            "Mismatched input arrays"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            _safeTransferFrom(_owner, to[i], ids[i], amounts[i], "");
        }
    }

    /*
     * Allows to update contract configuration and revoke NFTPort's access to the contract.
     * `baseURI` can only be updated if  `metadataUpdatable` is true.
     * Tokens can only be made to not be transferable or updatable, not vice-versa.
     * Only callable by accounts with `UPDATE_CONTRACT_ROLE` or `ADMIN_ROLE`.
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
            "Metadata is frozen"
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

    /*
     * Allows to mint tokens by the contract `_owner`.
     * Only callable by accounts with `MINT_ROLE` or `ADMIN_ROLE`.
     */
    function mintByOwner(
        address account,
        uint256 id,
        uint256 amount,
        string memory tokenUri
    ) public onlyRole(MINT_ROLE) nonReentrant {
        require(!_exists(id), "NFT: token already minted");
        if (bytes(tokenUri).length > 0) {
            _tokenURIs[id] = tokenUri;
            emit URI(tokenUri, id);
        }
        tokenSupply[id] += amount;
        _mint(account, id, amount, "");
    }

    /*
     * Same functionality as `mintByOwner` but for a batch of tokens.
     * Input `ids` and `values` must be in direct correlation,
     * an index in both lists referring to the same token.
     */
    function mintByOwnerBatch(
        address[] memory to,
        uint256[] memory ids,
        uint256[] memory amounts,
        string[] memory uris
    ) public onlyRole(MINT_ROLE) nonReentrant {
        require(
            to.length == ids.length &&
                ids.length == amounts.length &&
                amounts.length == uris.length,
            "Mismatched input arrays"
        );

        for (uint256 i = 0; i < ids.length; i++) {
            require(!_exists(ids[i]), "One of tokens is already minted");
            require(
                to[i] == address(to[i]),
                "NFT: one of addresses is invalid"
            );
            require(amounts[i] > 0, "NFT: all amounts must be > 0");
            tokenSupply[ids[i]] += amounts[i];
            if (bytes(uris[i]).length > 0) {
                _tokenURIs[ids[i]] = uris[i];
                emit URI(uris[i], ids[i]);
            }
            _mint(to[i], ids[i], amounts[i], "");
        }
    }

    /******************
     * View functions *
     ******************/

    // Returns total supply for the given token ID
    function totalSupply(uint256 _id) public view returns (uint256) {
        return tokenSupply[_id];
    }

    /*
     * Returns token URI for the given token ID.
     * If token URI is not empty and base URI is not empty then returns base URI + token URI,
     * if base URI is empty and token URI is not empty then returns just token URI.
     * If the token URI for the given token ID is empty then returns the default token URI.
     */
    function uri(uint256 _id) public view override returns (string memory) {
        if (bytes(_tokenURIs[_id]).length > 0) {
            if (bytes(baseURI).length > 0) {
                return string(abi.encodePacked(baseURI, _tokenURIs[_id]));
            } else {
                return _tokenURIs[_id];
            }
        } else {
            return super.uri(_id);
        }
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
                        // solium-disable-next-line quotes
                        '{"seller_fee_basis_points": ', // solhint-disable-line
                        royaltiesBasisPoints.toString(),
                        // solium-disable-next-line quotes
                        ', "fee_recipient": "', // solhint-disable-line
                        uint256(uint160(royaltiesAddress)).toHexString(20),
                        // solium-disable-next-line quotes
                        '"}' // solhint-disable-line
                    )
                )
            )
        );

        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return
            ERC1155Upgradeable.supportsInterface(interfaceId) ||
            interfaceId == type(IERC2981).interfaceId;
    }

    /*************
     * Internals *
     *************/

    // Mapping of token ID to URI
    mapping(uint256 => string) private _tokenURIs;

    // Used for checking if token with given ID exists
    function _exists(uint256 _tokenId) internal view virtual returns (bool) {
        return tokenSupply[_tokenId] > 0;
    }

    function _setRoyalties(address newAddress, uint256 newBps) internal {
        require(newBps <= ROYALTIES_BASIS, "Cannot set royalties to over 100%");

        royaltiesAddress = newAddress;
        royaltiesBasisPoints = newBps;
    }
}