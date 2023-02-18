// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { ERC721Pausable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { DefaultOperatorFilterer } from "operator-filter-registry/src/DefaultOperatorFilterer.sol";
import { CoreRoles } from "./CoreRoles.sol";
import { IERC721Core } from "./interfaces/IERC721Core.sol";
import { RoyaltyInfo } from "./RoyaltyInfo.sol";

contract ERC721Core is
    ERC721Pausable,
    IERC721Core,
    ReentrancyGuard,
    DefaultOperatorFilterer,
    RoyaltyInfo,
    CoreRoles
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _totalSupply;
    uint256 private _maxSupply;
    string private _tokenURIPrefix;
    string private _tokenURISuffix;
    address private _saleAddress;

    /*------------------------------------------------
     * ERC721Core
     *----------------------------------------------*/

    modifier onlyOperatorOrSale() {
        address caller = msg.sender;
        require(
            operator() == caller || _saleAddress == caller,
            "invalid caller"
        );
        _;
    }

    event SaleAddress(
        address indexed previousAddress,
        address indexed newAddress
    );

    event TokenURI(string prefix, string suffix);

    constructor(
        string memory name,
        string memory symbol,
        address royaltyReceiver,
        uint96 royaltyFraction,
        uint256 newMaxSupply,
        string memory newTokenURIPrefix,
        string memory newTokenURISuffix
    ) ERC721(name, symbol) RoyaltyInfo(royaltyReceiver, royaltyFraction) {
        _maxSupply = newMaxSupply;
        _setTokenURI(newTokenURIPrefix, newTokenURISuffix);
    }

    function saleAddress() external view returns (address) {
        return _saleAddress;
    }

    function setSaleAddress(address newSaleAddress) external onlyAdmin {
        address previousSaleAddress = _saleAddress;
        _saleAddress = newSaleAddress;
        emit SaleAddress(previousSaleAddress, _saleAddress);
    }

    /*------------------------------------------------
     * IERC721Core
     *----------------------------------------------*/

    function mint(address to, uint256 amount)
        external
        override
        onlyOperatorOrSale
        nonReentrant
    {
        require(
            (_totalSupply.current() + amount) <= _maxSupply,
            "over max supply"
        );
        while (0 < amount) {
            _totalSupply.increment();
            _safeMint(to, _totalSupply.current());
            amount--;
        }
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply.current();
    }

    function maxSupply() external view returns (uint256) {
        return _maxSupply;
    }

    function remainSupply() external view override returns (uint256) {
        if (_maxSupply <= _totalSupply.current()) {
            return 0;
        }
        return _maxSupply - _totalSupply.current();
    }

    function supplies()
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 total = _totalSupply.current();
        uint256 remain = 0;
        if (total < _maxSupply) {
            remain = _maxSupply - total;
        }
        return (total, _maxSupply, remain);
    }

    /*------------------------------------------------
     * ERC165
     *----------------------------------------------*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(RoyaltyInfo, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*------------------------------------------------
     * ERC721
     *----------------------------------------------*/

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "not exist token");
        return
            string(
                abi.encodePacked(
                    _tokenURIPrefix,
                    tokenId.toString(),
                    _tokenURISuffix
                )
            );
    }

    function setTokenURI(
        string memory newTokenURIPrefix,
        string memory newTokenURISuffix
    ) external onlyOperator {
        _setTokenURI(newTokenURIPrefix, newTokenURISuffix);
    }

    function _setTokenURI(
        string memory newTokenURIPrefix,
        string memory newTokenURISuffix
    ) internal {
        _tokenURIPrefix = newTokenURIPrefix;
        _tokenURISuffix = newTokenURISuffix;
        emit TokenURI(_tokenURIPrefix, _tokenURISuffix);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return super.isApprovedForAll(owner, operator);
    }

    /*------------------------------------------------
     * ERC2981
     *----------------------------------------------*/

    function setRoyaltyInfo(address newReceiver, uint96 newFraction)
        external
        onlyOperator
    {
        _setRoyaltyInfo(newReceiver, newFraction);
    }
}