// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ERC165 } from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { MerkleProof } from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import { CoreRoles } from "./CoreRoles.sol";
import { ERC721MetadataOnly } from "./ERC721MetadataOnly.sol";
import { RoyaltyInfo } from "./RoyaltyInfo.sol";
import { IERC721CoreMint } from "./interfaces/IERC721CoreMint.sol";

contract ERC721Core is
    ERC165,
    ERC721MetadataOnly,
    ReentrancyGuard,
    IERC721CoreMint,
    RoyaltyInfo,
    CoreRoles
{
    using Address for address;
    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 private constant TOKEN_IDS_BY_OWNER_ONCE_COUNT = 20;

    Counters.Counter private _totalSupply;
    uint256 private _maxSupply;
    mapping(uint256 => address) private _tokenOwners;
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
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

    constructor(
        string memory name,
        string memory symbol,
        address royaltyReceiver,
        uint96 royaltyFraction,
        uint256 newMaxSupply,
        string memory newTokenURIPrefix,
        string memory newTokenURISuffix
    )
        ERC721MetadataOnly(name, symbol, newTokenURIPrefix, newTokenURISuffix)
        RoyaltyInfo(royaltyReceiver, royaltyFraction)
    {
        _maxSupply = newMaxSupply;
    }

    function tokenIdsByOwnerOnceCount() external pure returns (uint256) {
        return TOKEN_IDS_BY_OWNER_ONCE_COUNT;
    }

    function tokenIdsByOwner(address owner, uint256 offset)
        external
        view
        returns (
            uint256[TOKEN_IDS_BY_OWNER_ONCE_COUNT] memory,
            uint256,
            bool
        )
    {
        uint256[TOKEN_IDS_BY_OWNER_ONCE_COUNT] memory tokenIds;
        uint256 tokenIdCount = 0;
        bool isNext = true;
        uint256 len = _balances[owner];
        for (uint256 i = 0; i < TOKEN_IDS_BY_OWNER_ONCE_COUNT; i++) {
            uint256 index = i + offset;
            if (index < len) {
                tokenIds[i] = _ownedTokens[owner][index];
                tokenIdCount++;
            } else {
                tokenIds[i] = 0;
                isNext = false;
            }
        }

        return (tokenIds, tokenIdCount, isNext);
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

    function setTokenURI(
        string memory newTokenURIPrefix,
        string memory newTokenURISuffix
    ) external onlyOperator {
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
     * IERC721CoreMint
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

    /*------------------------------------------------
     * ERC165
     *----------------------------------------------*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(RoyaltyInfo, ERC721MetadataOnly, ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /*------------------------------------------------
     * Enumerable
     *----------------------------------------------*/

    function totalSupply() external view returns (uint256) {
        return _totalSupply.current();
    }

    /*------------------------------------------------
     * Metadata
     *----------------------------------------------*/

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "not exist token");
        return _tokenURI(tokenId);
    }

    /*------------------------------------------------
     * IERC2981
     *----------------------------------------------*/

    function setRoyaltyInfo(address newReceiver, uint96 newFraction)
        external
        onlyOperator
    {
        _setRoyaltyInfo(newReceiver, newFraction);
    }

    /*------------------------------------------------
     * IERC721
     *----------------------------------------------*/

    function balanceOf(address tokenOwner)
        external
        view
        virtual
        override
        returns (uint256)
    {
        require(tokenOwner != address(0), "invalid token owner");
        return _balances[tokenOwner];
    }

    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address tokenOwner = _tokenOwners[tokenId];
        require(tokenOwner != address(0), "invalid token ID");
        return tokenOwner;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address tokenOwner = ownerOf(tokenId);
        require(to != tokenOwner, "can't approval to current owner");
        if (msg.sender != tokenOwner) {
            require(
                isApprovedForAll(tokenOwner, msg.sender),
                "owner is not sender or operator"
            );
        }

        _approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(_exists(tokenId), "invalid token ID");

        return _tokenApprovals[tokenId];
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId),
            "must be approved for token"
        );

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "non ERC721Receiver implementer"
        );
    }

    /*------------------------------------------------
     * IERC721 internal
     *----------------------------------------------*/

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _tokenOwners[tokenId] != address(0);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "non ERC721Receiver implementer"
        );
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "mint to the zero address");
        require(!_exists(tokenId), "token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        emit Transfer(address(0), to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ownerOf(tokenId) == from, "transfer from incorrect owner");
        require(to != address(0), "transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        _approve(address(0), tokenId);

        emit Transfer(from, to, tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        if (from != address(0)) {
            if (from != to) {
                uint256 lastTokenIndex = _balances[from] - 1;
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

            _balances[from] -= 1;
        }
        if (to != address(0)) {
            if (from != to) {
                uint256 length = _balances[to];
                _ownedTokens[to][length] = tokenId;
                _ownedTokensIndex[tokenId] = length;
            }

            _balances[to] += 1;
        }
        _tokenOwners[tokenId] = to;
    }
}