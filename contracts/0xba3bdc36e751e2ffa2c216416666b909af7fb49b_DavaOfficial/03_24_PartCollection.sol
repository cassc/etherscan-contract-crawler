//SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;
pragma abicoder v2;

import {ERC1155Supply} from "./ERC1155Supply.sol";
import {ERC1155, IERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControl, IAccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IPartCollection} from "../interfaces/IPartCollection.sol";
import {IAvatar} from "../interfaces/IAvatar.sol";
import {IGatewayHandler} from "../interfaces/IGatewayHandler.sol";
import {GatewayHandler} from "./GatewayHandler.sol";
import {OnchainMetadata} from "./OnchainMetadata.sol";
import {URICompiler} from "./URICompiler.sol";

struct PartInfo {
    mapping(uint256 => string) titles;
    mapping(uint256 => string) descriptions;
    mapping(uint256 => string) ipfsHashes;
    mapping(uint256 => uint256) maxSupply;
    mapping(uint256 => IPartCollection.Attribute[]) attributes;
    mapping(uint256 => bytes32) categoryIds;
}

struct CollectionInfo {
    // categoryId => zIndex
    mapping(bytes32 => uint256) zIndex;
    // categoryId => title
    mapping(bytes32 => string) titles;
    // categoryId => current contract tokenId
    mapping(bytes32 => uint256) backgroundImagePart;
    // categoryId => current contract tokenId
    mapping(bytes32 => uint256) foregroundImagePart;
    // zIndex => bool
    mapping(uint256 => bool) zIndexExists;
}

abstract contract PartCollection is
    IPartCollection,
    AccessControl,
    Ownable,
    ERC1155Supply
{
    using Strings for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 public constant IPFS_GATEWAY_KEY = keccak256("IPFS_GATEWAY");
    bytes32 public constant DAVA_GATEWAY_KEY = keccak256("DAVA_GATEWAY");
    bytes32 public constant DEFAULT_CATEGORY = keccak256("DEFAULT_CATEGORY");

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");

    address public override dava;

    PartInfo private _partInfo;
    CollectionInfo private _collectionInfo;
    IGatewayHandler public gatewayHandler;

    uint256 public override numberOfParts;

    EnumerableSet.Bytes32Set private _supportedCategoryIds;

    event PartCreated(uint256 partId);

    constructor(IGatewayHandler gatewayHandler_, address dava_)
        ERC1155("")
        Ownable()
    {
        gatewayHandler = gatewayHandler_;
        dava = dava_;

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(CREATOR_ROLE, msg.sender);
        _setRoleAdmin(CREATOR_ROLE, DEFAULT_ADMIN_ROLE);

        _supportedCategoryIds.add(DEFAULT_CATEGORY);
    }

    function unsafeCreatePart(
        bytes32 categoryId_,
        string memory title_,
        string memory description_,
        string memory ipfsHash_,
        Attribute[] memory attributes,
        uint256 maxSupply_,
        uint256 filledSupply_
    ) external onlyRole(CREATOR_ROLE) {
        _unsafeSetTotalSupply(numberOfParts, filledSupply_);
        createPart(
            categoryId_,
            title_,
            description_,
            ipfsHash_,
            attributes,
            maxSupply_
        );
    }

    function createPart(
        bytes32 categoryId_,
        string memory title_,
        string memory description_,
        string memory ipfsHash_,
        Attribute[] memory attributes,
        uint256 maxSupply_
    ) public virtual override onlyRole(CREATOR_ROLE) {
        uint256 tokenId = numberOfParts;
        _partInfo.titles[tokenId] = title_;
        _partInfo.descriptions[tokenId] = description_;
        _partInfo.ipfsHashes[tokenId] = ipfsHash_;
        _partInfo.maxSupply[tokenId] = maxSupply_;

        // default part
        require(
            _supportedCategoryIds.contains(categoryId_),
            "Part: non existent category"
        );
        if (categoryId_ == DEFAULT_CATEGORY) {
            require(
                maxSupply_ == 0,
                "Part: maxSupply of default category should be zero"
            );
        } else {
            require(
                maxSupply_ != 0,
                "Part: maxSupply should be greater than zero"
            );
            emit PartCreated(tokenId);
        }
        _partInfo.categoryIds[tokenId] = categoryId_;

        for (uint256 i = 0; i < attributes.length; i += 1) {
            _partInfo.attributes[tokenId].push(attributes[i]);
        }

        numberOfParts += 1;
    }

    function createCategory(
        string memory title_,
        uint256 backgroundImageTokenId_,
        uint256 foregroundImageTokenId_,
        uint256 zIndex_
    ) public virtual override onlyRole(CREATOR_ROLE) {
        bytes32 _categoryId = keccak256(abi.encodePacked(title_));
        require(
            !_supportedCategoryIds.contains(_categoryId),
            "Part: already exists category"
        );
        require(
            !_collectionInfo.zIndexExists[zIndex_],
            "Part: already used zIndex"
        );

        require(
            _partInfo.categoryIds[backgroundImageTokenId_] ==
                DEFAULT_CATEGORY &&
                _partInfo.categoryIds[foregroundImageTokenId_] ==
                DEFAULT_CATEGORY,
            "Part: frame image is not created"
        );

        _collectionInfo.zIndex[_categoryId] = zIndex_;
        _collectionInfo.titles[_categoryId] = title_;
        _collectionInfo.backgroundImagePart[
            _categoryId
        ] = backgroundImageTokenId_;
        _collectionInfo.foregroundImagePart[
            _categoryId
        ] = foregroundImageTokenId_;
        _collectionInfo.zIndexExists[zIndex_] = true;

        _supportedCategoryIds.add(_categoryId);
    }

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        require(
            totalSupply(id) + amount <= maxSupply(id),
            "Part: Out of stock."
        );

        return super._mint(account, id, amount, data);
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyRole(MINTER_ROLE) {
        for (uint256 i = 0; i < ids.length; i += 1) {
            require(
                totalSupply(ids[i]) + amounts[i] <= maxSupply(ids[i]),
                "Part: Out of stock."
            );
        }
        return super._mintBatch(to, ids, amounts, data);
    }

    function unsafeMintBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external onlyRole(MINTER_ROLE) {
        super._unsafeMintBatch(to, ids, amounts, "");
    }

    // viewers

    function uri(uint256 tokenId) public view override returns (string memory) {
        string[] memory imgURIs = new string[](3);
        uint256 backgroundTokenId = _collectionInfo.backgroundImagePart[
            _partInfo.categoryIds[tokenId]
        ];
        uint256 foregroundTokenId = _collectionInfo.foregroundImagePart[
            _partInfo.categoryIds[tokenId]
        ];

        string memory ipfsBaseUri = gatewayHandler.gateways(IPFS_GATEWAY_KEY);
        imgURIs[0] = string(
            abi.encodePacked(
                ipfsBaseUri,
                "/",
                _partInfo.ipfsHashes[backgroundTokenId]
            )
        );
        imgURIs[1] = string(
            abi.encodePacked(ipfsBaseUri, "/", _partInfo.ipfsHashes[tokenId])
        );
        imgURIs[2] = string(
            abi.encodePacked(
                ipfsBaseUri,
                "/",
                _partInfo.ipfsHashes[foregroundTokenId]
            )
        );

        string memory thisAddress = uint256(uint160(address(this))).toHexString(
            20
        );
        string[] memory imgParams = new string[](1);
        imgParams[0] = "images";
        string[] memory infoParams = new string[](3);
        infoParams[0] = "info";
        infoParams[1] = thisAddress;
        infoParams[2] = tokenId.toString();

        URICompiler.Query[] memory queries = new URICompiler.Query[](3);
        queries[0] = URICompiler.Query(
            thisAddress,
            backgroundTokenId.toString()
        );
        queries[1] = URICompiler.Query(thisAddress, tokenId.toString());
        queries[2] = URICompiler.Query(
            thisAddress,
            foregroundTokenId.toString()
        );

        // partInfo => maxSupply, collection title
        Attribute[] memory attributes = new Attribute[](
            _partInfo.attributes[tokenId].length + 1
        );
        for (uint256 i = 0; i < _partInfo.attributes[tokenId].length; i += 1) {
            attributes[i] = _partInfo.attributes[tokenId][i];
        }
        attributes[_partInfo.attributes[tokenId].length] = Attribute(
            "TYPE",
            categoryTitle(tokenId)
        );

        return
            OnchainMetadata.toMetadata(
                _partInfo.titles[tokenId],
                _partInfo.descriptions[tokenId],
                imgURIs,
                URICompiler.getFullUri(
                    gatewayHandler.gateways(DAVA_GATEWAY_KEY),
                    imgParams,
                    queries
                ),
                URICompiler.getFullUri(
                    gatewayHandler.gateways(DAVA_GATEWAY_KEY),
                    infoParams,
                    new URICompiler.Query[](0)
                ),
                attributes
            );
    }

    function description(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _partInfo.descriptions[tokenId];
    }

    function imageUri(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory ipfsGateway = gatewayHandler.gateways(IPFS_GATEWAY_KEY);
        return
            string(
                abi.encodePacked(
                    ipfsGateway,
                    "/",
                    _partInfo.ipfsHashes[tokenId]
                )
            );
    }

    function image(uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        string memory ipfsGateway = gatewayHandler.gateways(IPFS_GATEWAY_KEY);
        string[] memory imgURIs = new string[](1);
        imgURIs[0] = string(
            abi.encodePacked(ipfsGateway, "/", _partInfo.ipfsHashes[tokenId])
        );
        return OnchainMetadata.compileImages(imgURIs);
    }

    function getAllSupportedCategoryIds()
        public
        view
        returns (bytes32[] memory)
    {
        return _supportedCategoryIds.values();
    }

    function maxSupply(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _partInfo.maxSupply[tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, AccessControl, ERC1155)
        returns (bool)
    {
        return
            interfaceId == type(IPartCollection).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function categoryTitle(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        bytes32 _categoryId = _partInfo.categoryIds[tokenId];
        return _collectionInfo.titles[_categoryId];
    }

    /**
     * @dev return registered part title
     */
    function partTitle(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _partInfo.titles[tokenId];
    }

    function categoryInfo(bytes32 categoryId_)
        public
        view
        override
        returns (
            string memory title_,
            uint256 backgroundImgTokenId_,
            uint256 foregroundImgTokenId_,
            uint256 zIndex_
        )
    {
        title_ = _collectionInfo.titles[categoryId_];
        backgroundImgTokenId_ = _collectionInfo.backgroundImagePart[
            categoryId_
        ];
        foregroundImgTokenId_ = _collectionInfo.foregroundImagePart[
            categoryId_
        ];
        zIndex_ = _collectionInfo.zIndex[categoryId_];
    }

    function categoryId(uint256 tokenId)
        public
        view
        override
        returns (bytes32)
    {
        return _partInfo.categoryIds[tokenId];
    }

    /**
     * @dev zIndex value decides the order of image layering
     */
    function zIndex(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        bytes32 _categoryId = _partInfo.categoryIds[tokenId];
        uint256 zIndex_ = _collectionInfo.zIndex[_categoryId];
        return zIndex_;
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override(ERC1155, IERC1155)
        returns (bool)
    {
        return super.isApprovedForAll(account, operator) || operator == dava;
    }
}