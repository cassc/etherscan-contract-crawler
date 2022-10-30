// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "../BaseOverrides/BaseERC721.sol";
import "../BaseOverrides/BaseERC721Enumerable.sol";
import "../BaseOverrides/BaseERC721URIStorage.sol";

import "../v2/QurableRegistryManagedV2.sol";
import "../IERC721Minter.sol";
import "../IHasVersion.sol";
import {MarketLibV2} from "../libs/MarketLibV2.sol";

import "hardhat/console.sol";

contract QurableERC721BaseTokenURI is
    BaseERC721,
    BaseERC721Enumerable,
    QurableRegistryManagedV2,
    IERC721Minter,
    UUPSUpgradeable,
    IHasVersion
{
    bool private _isPaused;
    uint256 private _tokenIdCounter;

    mapping(uint256 => string) private _tokenURIs;

    bool public isBaseTokenURIFrozen;
    string public baseTokenURI;
    uint256 public collectionId;

    event PermanentURI(string _value, uint256 indexed _id);
    event CollectionIdChanged(uint256 collectionId);
    event BaseTokenURIChanged(string baseTokenURI);

    event Minted(
        uint256 indexed collectionId,
        address indexed to,
        uint256 tokenId
    );

    function initialize(
        address qurableRegistry_,
        uint256 collectionId_,
        string calldata baseTokenURI_,
        string calldata name_,
        string calldata symbol_
    ) public virtual initializer {
        require(collectionId_ >= 1e7, "InvalidCollectionId");

        __BaseERC721_init(name_, symbol_);
        __BaseERC721Enumerable_init();
        __Ownable_init();

        _setRegistry(qurableRegistry_);

        baseTokenURI = baseTokenURI_;
        collectionId = collectionId_;
    }

    function _authorizeUpgrade(address) internal virtual override onlyOwner {}

    function version() external pure virtual override returns (string memory) {
        return "1";
    }

    modifier onlyOperatorOrOwner() {
        require(
            owner() == _msgSender() ||
                _qurableRegistry.transferOperators(_msgSender()),
            "NotOperatorOrOwner"
        );
        _;
    }

    modifier whenNotPaused() {
        require(!_isPaused, "ContractPaused");
        _;
    }

    function pause() external onlyOwner {
        _isPaused = true;
    }

    function unpause() external onlyOwner {
        _isPaused = false;
    }

    function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
        require(bytes(_baseTokenURI).length > 0, "InvalidBaseTokenURI");
        require(!isBaseTokenURIFrozen, "BaseTokenURIFrozen");

        baseTokenURI = _baseTokenURI;

        emit BaseTokenURIChanged(_baseTokenURI);
    }

    function setCollectionId(uint256 collectionId_) external onlyOwner {
        require(collectionId_ > 0, "InvalidCollectionId");
        collectionId = collectionId_;

        emit CollectionIdChanged(collectionId_);
    }

    function freezeBaseTokenURI() external onlyOwner {
        require(collectionId > 0, "InvalidCollectionId");
        require(!isBaseTokenURIFrozen, "BaseTokenURIAlreadyFrozen");

        isBaseTokenURIFrozen = true;
    }

    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

    function mint(
        address from,
        address to,
        string memory relativeTokenURI,
        bool
    ) external virtual override onlyOperatorOrOwner returns (uint256) {
        return _mintInternal(from, to, relativeTokenURI);
    }

    function mintMultiple(
        address from,
        address[] calldata to,
        string[] calldata relativeTokenURIs
    ) external onlyOwner {
        require(relativeTokenURIs.length > 0, "InvalidFileURIs");
        require(
            to.length == relativeTokenURIs.length,
            "ToAndTokenURIsNotSameLength"
        );

        uint256 startTokenIdCounter = _tokenIdCounter;
        _tokenIdCounter += relativeTokenURIs.length;

        for (uint256 index = 0; index < relativeTokenURIs.length; index++) {
            uint256 newTokenId = collectionId + startTokenIdCounter + index;

            require(
                bytes(relativeTokenURIs[index]).length > 0,
                "InvalidFileURIs"
            );

            _tokenURIs[newTokenId] = relativeTokenURIs[index];
            _mintSingle(from, to[index], newTokenId);
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string storage relativeTokenURI = _tokenURIs[tokenId];

        require(bytes(relativeTokenURI).length > 0, "NonExistentToken");

        return string(abi.encodePacked(baseTokenURI, "/", relativeTokenURI));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(BaseERC721, BaseERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * Override isApprovedForAll to auto-approve OS's proxy contract
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        override(BaseERC721)
        returns (bool isOperator)
    {
        if (_qurableRegistry.transferOperators(_operator)) {
            return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    function decimals() external pure returns (uint8) {
        return 0;
    }

    // ** Private Function **

    function _mintInternal(
        address from,
        address to,
        string memory relativeTokenURI
    ) internal onlyOperatorOrOwner returns (uint256) {
        uint256 newTokenId = collectionId + _tokenIdCounter;

        _mintSingle(from, to, newTokenId);
        _tokenURIs[newTokenId] = relativeTokenURI;

        if (isBaseTokenURIFrozen) {
            emit PermanentURI(tokenURI(newTokenId), newTokenId);
        }

        _tokenIdCounter += 1;

        return newTokenId;
    }

    function _mintSingle(
        address from,
        address to,
        uint256 newTokenId
    ) internal {
        require(collectionId > 0, "InvalidCollectionId");
        require(to != address(0), "InvalidTo");

        require(
            _tokenIdCounter < MarketLibV2.MAX_ALLOWED_MINTING_COUNT,
            "MaxMintingReached"
        );

        _safeMint(from, to, newTokenId);

        emit Minted(collectionId, to, newTokenId);
    }

    // The following functions are overrides required by Solidity.
    function _burn(uint256 tokenId)
        internal
        override(BaseERC721)
        whenNotPaused
    {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(BaseERC721, BaseERC721Enumerable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}