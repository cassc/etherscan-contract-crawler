// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "hardhat/console.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { DefaultOperatorFilterer } from "../operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract RIFFMON is
    ERC721Enumerable,
    Ownable,
    ERC2981,
    DefaultOperatorFilterer,
    AccessControl,
    IAccessControlEnumerable
{
    using Strings for uint256;

    uint256 private constant START_TOKEN_ID = 1;

    uint256 private maxSupply;

    /**
     * @dev The base URI of metadata
     */
    string private baseTokenURI;

    /**
     * @dev Percentage basis points of the royalty
     */
    uint96 private defaultFeeNumerator;

    /**
     * @dev Max royalty this contract allows to set. It's 20% in the basis points.
     */
    uint256 private constant MAX_ROYALTY_BASIS_POINTS = 2000;

    uint256 private salePrice;

    uint256 public SALE_START_ID;

    uint256 public SALE_END_ID;

    /** @dev white list */

    bool public isPublicMint = false;

    bool public isWhiteListMint = false;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /** @dev IAccessControlEnumerable */

    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenUri,
        uint256 _maxSupply,
        uint96 _feeNumerator,
        address _ownerAddress
    ) ERC721(_name, _symbol) {
        require(
            _feeNumerator <= MAX_ROYALTY_BASIS_POINTS,
            "must be less than or equal to 20%"
        );

        baseTokenURI = _baseTokenUri;
        maxSupply = _maxSupply;
        defaultFeeNumerator = _feeNumerator;

        _transferOwnership(_ownerAddress);
        _setDefaultRoyalty(_ownerAddress, _feeNumerator);
    }

    /**
     * @dev Set baseTokenURI.
     * @param newBaseTokenURI The value being set to baseTokenURI.
     */
    function setBaseTokenURI(string calldata newBaseTokenURI)
        external
        onlyOwner
    {
        baseTokenURI = newBaseTokenURI;
    }

    /**
     * @dev Set mint token.
     * @param _startId This is the TokenId you want to change
     * @param _endId This is the value you want to change
     */
    function setSaleTokenId(uint256 _startId, uint256 _endId)
        external
        onlyOwner
    {
        SALE_START_ID = _startId;
        SALE_END_ID = _endId;
    }

    /**
     * @dev Return baseTokenURI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    /**
     * @dev Do nothing for disable renouncing ownership.
     */
    function renounceOwnership() public override onlyOwner {}

    /**
     * @dev Set the royalty recipient.
     * @param newDefaultRoyaltiesReceipientAddress The address of the new royalty receipient.
     */
    function setDefaultRoyaltiesReceipientAddress(
        address payable newDefaultRoyaltiesReceipientAddress
    ) external onlyOwner {
        require(
            newDefaultRoyaltiesReceipientAddress != address(0),
            "invalid address"
        );
        _setDefaultRoyalty(
            newDefaultRoyaltiesReceipientAddress,
            defaultFeeNumerator
        );
    }

    /**
     * @dev set the price of the sales contract.
     */
    function setSalePrice(uint256 _salePrice) external onlyOwner {
        salePrice = _salePrice;
    }

    /**
     * @dev Returns the price of the sales contract.
     */
    function getSalePrice() external view returns (uint256) {
        return salePrice;
    }

    function ownerMint(uint256 _tokenId, address _address) internal onlyOwner {
        require(
            _tokenId >= START_TOKEN_ID && _tokenId < START_TOKEN_ID + maxSupply,
            "invalid token id"
        );
        _safeMint(_address, _tokenId);
    }

    function operationMint(uint256 _startTokenId, uint256 _endTokenId)
        external
        onlyOwner
    {
        for (uint256 i = _startTokenId; i <= _endTokenId; i++) {
            ownerMint(i, owner());
        }
    }

    function mint(uint256 _tokenId, address _address) external payable {
        require(
            _tokenId >= START_TOKEN_ID && _tokenId < START_TOKEN_ID + maxSupply,
            "invalid token id"
        );
        require(
            msg.value == salePrice,
            "must submit the asking price in order to complete the purchase"
        );
        require(
            SALE_START_ID <= _tokenId &&
                _tokenId <= SALE_END_ID &&
                (isWhiteListMint || isPublicMint),
            "The sale has not started yet"
        );
        if (isWhiteListMint) {
            _checkRole(MINTER_ROLE, msg.sender);
        }

        if (msg.value != 0) {
            payable(owner()).transfer(msg.value);
        }

        _safeMint(_address, _tokenId);
    }

    /** @dev white list */

    function grantMinterRole(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            address minter = accounts[i];
            _setupRole(MINTER_ROLE, minter);
        }
    }

    function revokeMinterRole(address[] memory accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            address minter = accounts[i];
            _revokeRole(MINTER_ROLE, minter);
        }
    }

    function revokeAllMinterRole() external onlyOwner {
        address[] memory accounts = getMinterRoleMember();
        for (uint256 i = 0; i < accounts.length; i++) {
            address minter = accounts[i];
            _revokeRole(MINTER_ROLE, minter);
        }
    }

    function getMinterRoleMember() public view returns (address[] memory) {
        return EnumerableSet.values(_roleMembers[MINTER_ROLE]);
    }

    function stopMint() external onlyOwner {
        isPublicMint = false;
        isWhiteListMint = false;
    }

    function setPublicMintSale(
        uint256 _mintPrice,
        bool _isPublicMint,
        uint256 _startId,
        uint256 _endId
    ) external onlyOwner {
        require(_startId < _endId, "_startId must be less than _endId.");
        require(_endId < maxSupply, "Use a value smaller than maxSupply.");

        isPublicMint = _isPublicMint;
        if (_isPublicMint) {
            isWhiteListMint = false;
        }

        salePrice = _mintPrice;
        SALE_START_ID = _startId;
        SALE_END_ID = _endId;
    }

    function setWhiteListMintSale(
        uint256 _mintPrice,
        bool _isWhiteListMint,
        uint256 _startId,
        uint256 _endId
    ) external onlyOwner {
        require(_startId < _endId, "_startId must be less than _endId.");
        require(_endId < maxSupply, "Use a value smaller than maxSupply.");

        isWhiteListMint = _isWhiteListMint;
        if (_isWhiteListMint) {
            isPublicMint = false;
        }
        salePrice = _mintPrice;
        SALE_START_ID = _startId;
        SALE_END_ID = _endId;
    }

    /** @dev Opensea operator-filter-registry */

    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /** @dev IAccessControlEnumerable */

    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        virtual
        override
        returns (address)
    {
        return _roleMembers[role].at(index);
    }

    function getRoleMemberCount(bytes32 role)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _roleMembers[role].length();
    }

    function _grantRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    function _revokeRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev See {supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, ERC2981, AccessControl)
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlEnumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}