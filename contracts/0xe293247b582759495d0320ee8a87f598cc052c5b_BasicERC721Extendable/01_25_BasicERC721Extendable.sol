// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC4906} from "@openzeppelin/contracts/interfaces/IERC4906.sol";
import {ERC721, IERC165} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Royalty} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IBaseERC721Extendable} from "./IBaseERC721Extendable.sol";
import {AccessContrownable} from "./AccessContrownable.sol";

contract BasicERC721Extendable is
    IERC4906,
    ERC721,
    ERC721Royalty,
    AccessContrownable,
    ReentrancyGuard,
    IBaseERC721Extendable
{
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;
    using Strings for uint256;

    mapping(uint256 tokenId => address extension) internal tokenExtension;
    mapping(address extension => string baseURI) private extensionBaseURI;
    mapping(uint256 tokenId => string tokenURI) private tokenURIMap;

    EnumerableSet.AddressSet internal extensions;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bool public metadataLocked;
    uint256 public maxSupply;
    uint256 public currentSupply;
    string public baseURI;

    event PermanentURI(string value, uint256 indexed id);
    event MetadataLocked();
    event MaxSupplyReduced(uint256 newMaxSupply);
    event BaseURISet(string baseURI);
    event BaseURIExtensionSet(string baseURI, address extension);

    error MetadataIsLocked();
    error MetadataMustBeLocked();
    error MustBeARegisteredExtension();
    error NewMaxSupplyMustBeSmallerThanCurrentMaxSupply(
        uint256 newMaxSupply,
        uint256 currentMaxSupply
    );
    error CurrentSupplyMustBeEqualOrLowerThanNewMaxSupply(
        uint256 newMaxSupply,
        uint256 currentSupply
    );
    error TokenWasNotCreatedByThisExtension(
        address callingExtension,
        address expectedExtension,
        uint256 tokenId
    );
    error InputArraysAreNotEqualInSize();
    error RegisterExtensionFailed();
    error ExtensionMusBeAContract();
    error MintExceedsMaximalAllowedTokenSupply();

    modifier metadataNotLocked() {
        if (metadataLocked) {
            revert MetadataIsLocked();
        }
        _;
    }

    modifier metadataIsLocked() {
        if (!metadataLocked) {
            revert MetadataMustBeLocked();
        }
        _;
    }
    /**
     * @dev Only allows registered extensions to call the specified function
     */
    modifier extensionRequired() {
        if (!extensions.contains(msg.sender)) {
            revert MustBeARegisteredExtension();
        }
        _;
    }

    constructor(
        address admin_,
        address minter_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256 maxSupply_,
        address royalReceiver_,
        uint96 royalFeeNumerator_
    ) payable AccessContrownable(admin_) ERC721(name_, symbol_) {
        baseURI = baseURI_;
        maxSupply = maxSupply_;
        _grantRole(MINTER_ROLE, admin_);
        _grantRole(MINTER_ROLE, minter_);
        if (royalReceiver_ != address(0)) {
            _setDefaultRoyalty(royalReceiver_, royalFeeNumerator_);
        }
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721, ERC721Royalty, AccessControl, IERC165)
        returns (bool)
    {
        return interfaceId == bytes4(0x49064906) || interfaceId == type(IBaseERC721Extendable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IBaseERC721Extendable-getExtensions}.
     */
    function getExtensions()
        external
        view
        override
        returns (address[] memory _extensions)
    {
        uint256 len = extensions.length();
        _extensions = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            _extensions[i] = extensions.at(i);
        }
        return _extensions;
    }

    /**
     * @dev See {IBaseERC721Extendable-registerExtension}.
     */
    function registerExtension(
        address _extension,
        string calldata _baseURI
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _registerExtension(_extension, _baseURI);
    }

    /**
     * @dev See {IBaseERC721Extendable-unregisterExtension}.
     */
    function unregisterExtension(
        address _extension
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _unregisterExtension(_extension);
    }

    function tokenURI(
        uint256 _tokenId
    ) public view override(ERC721) returns (string memory) {
        address extension = tokenExtension[_tokenId];

        if (extension != address(0)) {
            string memory _extensionBaseURI = extensionBaseURI[extension];

            if (bytes(tokenURIMap[_tokenId]).length != 0) {
                // case 1:
                // extensionBaseURI is a prefix like https://arweave.net/ and tokenURIMap[tokenId]
                // contains Arweave TX IDs for the metadata of each token of the extension
                //
                // case 2:
                // extensionBaseURI is an empty string and tokenURIMap[tokenId] contains customized
                // full URIs for the metadata of each token of the extension
                return
                    string(
                        abi.encodePacked(
                            _extensionBaseURI,
                            tokenURIMap[_tokenId]
                        )
                    );
            }

            if (bytes(_extensionBaseURI).length != 0) {
                // case: use a common URI for all tokens of the extension
                // e.g. for token ID 3 on an extension-specific server: https://cdn.some-extension.io/metadata/3
                // or for token ID 3 inside an Arweave "folder": https://arweave.net/SOME_ARWEAVE_TX_HASH/3
                return
                    string(
                        abi.encodePacked(_extensionBaseURI,_tokenId.toString())
                    );
            }
        } else if (bytes(tokenURIMap[_tokenId]).length != 0) {
            // case 1:
            // baseURI is a prefix like https://arweave.net/ and tokenURIMap[tokenId]
            // contains Arweave TX IDs for the metadata of each token
            //
            // case 2:
            // baseURI is an empty string and tokenURIMap[tokenId] contains customized
            // full URIs for each token
            return string(abi.encodePacked(baseURI, tokenURIMap[_tokenId]));
        }

        // case: if no tokenURIMap[tokenId] entry was specified for the token return the default fallback
        // e.g. for token ID 8 on a centralized server for dynamic metadata cases: https://cdn.tokengate.io/metadata/8
        // or for token ID 8 inside an Arweave "folder": https://arweave.net/SOME_ARWEAVE_TX_HASH/8
        return string(abi.encodePacked(baseURI, _tokenId.toString()));
    }

    function setDefaultRoyalty(
        address _receiver,
        uint96 _feeNumerator
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        super._setDefaultRoyalty(_receiver, _feeNumerator);
    }

    function deleteDefaultRoyalty() public onlyRole(DEFAULT_ADMIN_ROLE) {
        super._deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNumerator
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        super._setTokenRoyalty(_tokenId, _receiver, _feeNumerator);
    }

    function resetTokenRoyalty(
        uint256 _tokenId
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        super._resetTokenRoyalty(_tokenId);
    }

    function reduceMaxSupply(
        uint256 _newReducedMaxSupply
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_newReducedMaxSupply >= maxSupply) {
            revert NewMaxSupplyMustBeSmallerThanCurrentMaxSupply(
                _newReducedMaxSupply,
                maxSupply
            );
        }
        if (currentSupply > _newReducedMaxSupply) {
            revert CurrentSupplyMustBeEqualOrLowerThanNewMaxSupply(
                _newReducedMaxSupply,
                currentSupply
            );
        }
        maxSupply = _newReducedMaxSupply;
        emit MaxSupplyReduced(_newReducedMaxSupply);
    }

    function updateBaseURI(
        string memory _baseURI,
        bool _emitEvent
    ) public onlyRole(MINTER_ROLE) metadataNotLocked {
        baseURI = _baseURI;
        if (_emitEvent) {
            emit BatchMetadataUpdate(1, type(uint256).max);
        }
        emit BaseURISet(_baseURI);
    }

    function updateBaseURIExtension(
        string memory _baseURI,
        bool _emitEvent
    ) public virtual override nonReentrant metadataNotLocked extensionRequired {
        extensionBaseURI[msg.sender] = _baseURI;
        if (_emitEvent) {
            emit BatchMetadataUpdate(1, type(uint256).max);
        }
        emit BaseURIExtensionSet(_baseURI, msg.sender);
    }

    function batchMintExtension(
        address[] calldata _tos,
        uint256[] calldata _tokenIds,
        string[] calldata _tokenUris
    ) public virtual override nonReentrant extensionRequired {
        uint256 len = _tokenIds.length;
        for (uint256 i = 0; i < len; i++) {
            tokenExtension[_tokenIds[i]] = msg.sender;
        }
        _batchMint(_tos, _tokenIds, _tokenUris);
    }

    function mintExtension(
        address _to,
        uint256 _tokenId,
        string calldata _tokenUri
    ) public virtual override nonReentrant extensionRequired {
        tokenExtension[_tokenId] = msg.sender;
        _mint(_to, _tokenId, _tokenUri);
    }

    function mint(
        address _to,
        uint256 _tokenId,
        string calldata _tokenUri
    ) public nonReentrant onlyRole(MINTER_ROLE) {
        _mint(_to, _tokenId, _tokenUri);
    }

    function batchUpdateTokenUriExtension(
        uint256[] calldata _tokenIds,
        string[] calldata _tokenUris,
        bool _emitEvent
    ) public virtual override nonReentrant extensionRequired {
        uint256 len = _tokenIds.length;
        for (uint256 i = 0; i < len; i++) {
            if (tokenExtension[_tokenIds[i]] != msg.sender) {
                revert TokenWasNotCreatedByThisExtension(
                    msg.sender,
                    tokenExtension[_tokenIds[i]],
                    _tokenIds[i]
                );
            }
        }
        _batchUpdateTokenUri(_tokenIds, _tokenUris, _emitEvent);
    }

    function batchUpdateTokenUri(
        uint256[] calldata _tokenIds,
        string[] calldata _tokenUris,
        bool _emitEvent
    ) public onlyRole(MINTER_ROLE) {
        _batchUpdateTokenUri(_tokenIds, _tokenUris, _emitEvent);
    }

    function batchMint(
        address[] calldata _tos,
        uint256[] calldata _tokenIds,
        string[] calldata _tokenUris
    ) public onlyRole(MINTER_ROLE) {
        _batchMint(_tos, _tokenIds, _tokenUris);
    }

    function lockMetadata(
        uint256[] calldata _tokenIdsForMetadataLockedEvent
    ) public onlyRole(DEFAULT_ADMIN_ROLE) metadataNotLocked {
        metadataLocked = true;
        emit MetadataLocked();
        if (_tokenIdsForMetadataLockedEvent.length > 0) {
            emitTokenMetadataLockedEvent(_tokenIdsForMetadataLockedEvent);
        }
    }

    function emitTokenMetadataLockedEvent(
        uint256[] calldata _tokenIds
    ) public onlyRole(MINTER_ROLE) metadataIsLocked {
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            emit PermanentURI(tokenURI(_tokenIds[i]), _tokenIds[i]);
        }
    }

    function _mint(
        address _to,
        uint256 _tokenId,
        string calldata _tokenUri
    ) internal virtual {
        _safeMint(_to, _tokenId);
        tokenURIMap[_tokenId] = _tokenUri;
        ++currentSupply;
    }

    function _batchMint(
        address[] calldata _tos,
        uint256[] calldata _tokenIds,
        string[] calldata _tokenUris
    ) internal virtual {
        uint256 len = _tos.length;
        if (
            len != _tokenIds.length ||
            (_tokenUris.length > 0 && len != _tokenUris.length)
        ) {
            revert InputArraysAreNotEqualInSize();
        }

        if (len + currentSupply > maxSupply) {
            revert MintExceedsMaximalAllowedTokenSupply();
        }

        if (_tokenUris.length == 0) {
            for (uint256 i; i < len; ++i) {
                _safeMint(_tos[i], _tokenIds[i]);
                tokenURIMap[_tokenIds[i]] = "";
                ++currentSupply;
            }
        } else {
            for (uint256 i; i < len; ++i) {
                _safeMint(_tos[i], _tokenIds[i]);
                tokenURIMap[_tokenIds[i]] = _tokenUris[i];
                ++currentSupply;
            }
        }
    }

    function _batchUpdateTokenUri(
        uint256[] calldata _tokenIds,
        string[] calldata _tokenUris,
        bool _emitEvent
    ) internal metadataNotLocked {
        uint256 len = _tokenIds.length;
        if (_tokenUris.length > 0 && len != _tokenUris.length) {
            revert InputArraysAreNotEqualInSize();
        }
        if (_tokenUris.length == 0) {
            for (uint256 i; i < len; ++i) {
                uint256 tokenId = _tokenIds[i];
                tokenURIMap[tokenId] = "";
                if (_emitEvent) {
                    emit MetadataUpdate(tokenId);
                }
            }
        } else {
            for (uint256 i; i < len; ++i) {
                uint256 tokenId = _tokenIds[i];
                tokenURIMap[tokenId] = _tokenUris[i];
                if (_emitEvent) {
                    emit MetadataUpdate(tokenId);
                }
            }
        }
    }

    function emitMetadataUpdatedEvent(
        uint256 _tokenId
    ) public onlyRole(MINTER_ROLE) {
        emit MetadataUpdate(_tokenId);
    }

    function emitBatchMetadataUpdatedEvent(
        uint256 _fromTokenId,
        uint256 _toTokenId
    ) public onlyRole(MINTER_ROLE) {
        emit BatchMetadataUpdate(_fromTokenId, _toTokenId);
    }

    function _burn(uint256 _tokenId) internal override(ERC721Royalty, ERC721) {
        super._burn(_tokenId);
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _batchSize
    ) internal override(ERC721) {
        super._beforeTokenTransfer(_from, _to, _tokenId, _batchSize);
    }

    /**
     * @dev Register an extension
     */
    function _registerExtension(
        address _extension,
        string calldata _baseURI
    ) internal {
        if (_extension == address(this)) {
            revert RegisterExtensionFailed();
        }

        if (_extension.isContract() == false) {
            revert ExtensionMusBeAContract();
        }

        if (!extensions.contains(_extension)) {
            extensionBaseURI[_extension] = _baseURI;
            emit ExtensionRegistered(_extension, msg.sender);
            extensions.add(_extension);
        }
    }

    /**
     * @dev Unregister an extension
     */
    function _unregisterExtension(address _extension) internal {
        if (extensions.contains(_extension)) {
            emit ExtensionUnregistered(_extension, msg.sender);
            extensions.remove(_extension);
        }
    }

}