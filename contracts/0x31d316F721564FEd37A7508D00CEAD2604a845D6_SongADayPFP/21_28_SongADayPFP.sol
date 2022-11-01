// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./BID721/BID721.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./BID721/extensions/BID721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./extensions/CustomAttributeAndURI.sol";

/// @custom:security-contact [email protected]
contract SongADayPFP is
    AccessControl,
    BID721,
    BID721Enumerable,
    ReentrancyGuard,
    Pausable,
    CustomAttributeAndURI
{
    using Counters for Counters.Counter;

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    Counters.Counter private _tokenIdCounter;

    string private _baseTokenURI;

    uint256 private _maxPerWallet = 1;
    uint256 private _maxSupply = 2**256 - 1;

    constructor(
        address verifier_,
        bytes32 context_,
        bytes memory soulboundMessage_,
        string memory name,
        string memory symbol,
        string memory baseTokenURI,
        bytes4 baseTokenURIPrefix,
        address minter
    ) BID721(verifier_, context_, soulboundMessage_, name, symbol) {
        _baseTokenURI = baseTokenURI;
        _baseTokenURIPrefix = baseTokenURIPrefix;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, minter);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // function totalSupply() public view virtual returns (uint256) {
    //     return _tokenIdCounter.current();
    // }

    function setMaxPerWallet(uint256 maxPerWallet)
        public
        virtual
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _maxPerWallet = maxPerWallet;
    }

    function safeMint(
        address to,
        address[] calldata contextIds,
        uint256 timestamp,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 inputTokenURI,
        bytes32 inputTokenAttribute,
        bytes calldata signature
    ) public virtual whenNotPaused nonReentrant {
        require(totalSupply() < _maxSupply, "has reached max supply");

        _validate(contextIds, timestamp, v, r, s);

        require(contextIds.length > 0, "BID721: need 1 member to mint");
        require(to == contextIds[0], "to must match newest context");
        require(to != address(0), "can not mint to zero address");

        uint256 balance;
        for (uint256 i = 0; i < contextIds.length; i++) {
            if (contextIds[i] != address(0)) {
                balance += BID721.balanceOf(contextIds[i]);
            }
        }

        require(balance < _maxPerWallet, "has reached max per wallet");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(to, tokenId);
        _setTokenURIAndAttribute(
            tokenId,
            to,
            inputTokenURI,
            inputTokenAttribute,
            signature
        );
    }

    function changeTokenURIAndAttribute(
        uint256 tokenId,
        bytes32 inputTokenURI,
        bytes32 inputTokenAttribute,
        bytes calldata signature
    ) public virtual whenNotPaused {
        require(_exists(tokenId), "URI set of nonexistent token");
        require(ownerOf(tokenId) == _msgSender(), "URI set of unowned token");

        _setTokenURIAndAttribute(
            tokenId,
            ownerOf(tokenId),
            inputTokenURI,
            inputTokenAttribute,
            signature
        );
    }

    function _setTokenURIAndAttribute(
        uint256 tokenId,
        address approvedAddress,
        bytes32 inputTokenURI,
        bytes32 inputTokenAttribute,
        bytes calldata signature
    ) internal virtual {
        address signer = _getTokenURIAndAttributeHashSigner(
            approvedAddress,
            inputTokenURI,
            inputTokenAttribute,
            signature
        );

        require(
            hasRole(MINTER_ROLE, signer),
            "URI must be signed by mint role"
        );

        _setTokenURI(tokenId, inputTokenURI);
        _setTokenAttribute(tokenId, inputTokenAttribute);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(BID721, BID721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function tokenURI(uint256 tokenId)
        public
        view
        override(BID721, CustomAttributeAndURI)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(BID721, BID721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}