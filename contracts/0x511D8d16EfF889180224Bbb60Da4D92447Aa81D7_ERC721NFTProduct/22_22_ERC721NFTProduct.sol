// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

import "../lib/Base64.sol";
import "../lib/GranularRoles.sol";
import "../lib/Config.sol";

contract ERC721NFTProduct is ERC721URIStorageUpgradeable, GranularRoles {
    /*******************************
     * Extensions, structs, events *
     *******************************/

    using StringsUpgradeable for uint256;

    // https://docs.opensea.io/docs/metadata-standards
    event PermanentURI(string _value, uint256 indexed _id);
    event PermanentURIGlobal();

    /*************
     * Constants *
     *************/

    uint256 public constant VERSION = 1_00_01;
    uint16 public constant ROYALTIES_BASIS = 10000;

    /********************
     * Public variables *
     ********************/

    bool public metadataUpdatable;
    bool public tokensBurnable;
    bool public tokensTransferable;

    // Mapping of individually frozen tokens
    mapping(uint256 => bool) public freezeTokenUris;

    string public baseURI;

    address public royaltiesAddress;
    uint256 public royaltiesBasisPoints;

    /***************************
     * Contract initialization *
     ***************************/

    constructor() initializer {
        // solhint-disable-previous-line no-empty-blocks
    }

    function initialize(
        Config.Deployment memory deploymentConfig,
        Config.Runtime memory runtimeConfig,
        RolesAddresses[] memory rolesAddresses
    ) public initializer {
        __ERC721_init(deploymentConfig.name, deploymentConfig.symbol);

        royaltiesAddress = runtimeConfig.royaltiesAddress;
        royaltiesBasisPoints = runtimeConfig.royaltiesBps;

        metadataUpdatable = runtimeConfig.metadataUpdatable;
        tokensBurnable = deploymentConfig.tokensBurnable;
        tokensTransferable = runtimeConfig.tokensTransferable;

        baseURI = runtimeConfig.baseURI;

        _initRoles(deploymentConfig.owner, rolesAddresses);
    }

    /*******************
     * Write functions *
     *******************/

    function mintToCaller(
        address caller,
        uint256 tokenId,
        string memory tokenURI
    ) public onlyRole(MINT_ROLE) returns (uint256) {
        _safeMint(caller, tokenId);
        _setTokenURI(tokenId, tokenURI);
        return tokenId;
    }

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

    function transferByOwner(address _to, uint256 _tokenId)
        public
        onlyRole(TRANSFER_ROLE)
    {
        require(tokensTransferable, "Transfer: Transfers are disabled");
        _safeTransfer(_owner, _to, _tokenId, "");
    }

    function burn(uint256 _tokenId) public onlyRole(BURN_ROLE) {
        require(tokensBurnable, "Burn: Burns are disabled");
        require(_exists(_tokenId), "Burn: Token does not exist");
        require(
            ERC721Upgradeable.ownerOf(_tokenId) == _owner,
            "Burn: not held by contract owner"
        );
        _burn(_tokenId);
    }

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
        royaltiesAddress = newConfig.royaltiesAddress;
        royaltiesBasisPoints = newConfig.royaltiesBps;

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

    function totalSupply() public view virtual returns (uint256) {
        return _allTokens.length;
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        returns (uint256)
    {
        require(index < balanceOf(owner), "Owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        require(index < totalSupply(), "Global index out of bounds");
        return _allTokens[index];
    }

    /*************
     * Internals *
     *************/

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    function _baseURI()
        internal
        view
        virtual
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}