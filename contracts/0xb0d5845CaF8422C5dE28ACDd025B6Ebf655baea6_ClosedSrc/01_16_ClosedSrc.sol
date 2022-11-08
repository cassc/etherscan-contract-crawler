// SPDX-License-Identifier: UNLICENSED
// Author: Kai Aldag <[email protected]>
// Date: November 1st, 2022
// Purpose: Reissue ClosedSrc x NFTLX UJ4-DNX

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


/**
 * @title ClosedSrc
 * 
 * @notice ClosedSrc x NFTLX smart contract for issuing NFTs for the Union Jordan 4 x
 * Nike Dunk mashup.
 */
contract ClosedSrc is ERC721, ERC2981, Ownable, AccessControl, ReentrancyGuard {

    // ────────────────────────────────────────────────────────────────────────────────
    // Events
    // ────────────────────────────────────────────────────────────────────────────────

    /** 
     * @dev emitted once a token has been redeemed.
     */
    event TokenRedeemed(uint256 indexed tokenId);

    // ────────────────────────────────────────────────────────────────────────────────
    // Types
    // ────────────────────────────────────────────────────────────────────────────────

    using Strings for uint256;

    // ────────────────────────────────────────────────────────────────────────────────
    // Fields
    // ────────────────────────────────────────────────────────────────────────────────

    /// @dev stores whether a tokens been redeemed for physical shoe or not
    mapping(uint256 => bool) internal tokenRedemptions;

    /// @dev base URI for all unredeemed shoes
    string internal unredeemedURI;
    /// @dev base URI for all redeemed shoes
    string internal redeemedURI;


    // ────────────────────────────────────────────────────────────────────────────────
    // Setup
    // ────────────────────────────────────────────────────────────────────────────────

    /**
     * @param _name the contract's permanent name.
     * @param _symbol the contract's permanent abbreviation symbol.
     * @param _unredeemedURI IPFS CID to directory containing token metadata, at path extension `tokenId`, for unredeemed tokens
     * @param _redeemedURI IPFS CID to directory containing tokens' metadata, at path extension `tokenId`, for redeemed tokens
     */
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _unredeemedURI,
        string memory _redeemedURI,
        address payable _royaltyReceiver,
        uint96 _royaltyRate
    ) ERC721(_name, _symbol) ERC2981() Ownable() AccessControl() ReentrancyGuard() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setDefaultRoyalty(_royaltyReceiver, _royaltyRate);
        unredeemedURI = _unredeemedURI;
        redeemedURI = _redeemedURI;
    }


    // ────────────────────────────────────────────────────────────────────────────────
    // User Functionality
    // ────────────────────────────────────────────────────────────────────────────────

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string storage baseURI = tokenRedemptions[tokenId] ? redeemedURI : unredeemedURI;
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return 100;
    }


    // ────────────────────────────────────────────────────────────────────────────────
    // Admin Functionality
    // ────────────────────────────────────────────────────────────────────────────────

    /**
     * @dev airdropToken will issue a new unredeemed token
     * 
     * @param recipient address to receive token
     * @param tokenId token ID to issue
     * @param redeemed marks token's redemption status
     *
     * Requirements:
     *
     * - the caller must be an admin authority
     *
     */
    function airdropToken(address recipient, uint256 tokenId, bool redeemed) external onlyAdminRole nonReentrant {
        require(
            tokenId > 0 && tokenId <= 100,
            "ClosedSrc: invalid token ID"
        );
        require(
            !_exists(tokenId),
            "ClosedSrc: token already exists"
        );
        _safeMint(recipient, tokenId);

        if (redeemed) {
            tokenRedemptions[tokenId] = true;
            emit TokenRedeemed(tokenId);
        }
    }

    /**
     * @dev airdropTokenBatch will issue a new unredeemed token
     * 
     * @param recipients addresses to receive token
     * @param tokenIds token IDs to issue 
     * @param redeemed if the tokens have been redeemed
     *
     * Requirements:
     *
     * - the caller must be an admin authority
     *
     */
    function airdropTokenBatch(address[] calldata recipients, uint256[] calldata tokenIds, bool redeemed) external onlyAdminRole nonReentrant {
        require(
            recipients.length == tokenIds.length, 
            "ClosedSrc: lengths of recipients and tokenIds must match"
        );
        uint256 length = recipients.length;

        for (uint256 i = 0; i < length; i++) {
            address recipient = recipients[i];
            uint256 tokenId = tokenIds[i];

            require(
                tokenId > 0 && tokenId <= 100,
                "ClosedSrc: invalid token ID"
            );
            require(
                !_exists(tokenId),
                "ClosedSrc: token already exists"
            );
            _safeMint(recipient, tokenId);
            if (redeemed) {
                tokenRedemptions[tokenId] = true;
                emit TokenRedeemed(tokenId);
            }
        }
    }

    /**
     * @dev redeemToken allows admins to mark a token as redeemed. 
     * NOTE: this cannot be reversed.
     * 
     * @param tokenId Id of the token to mark redeemed
     *
     * Requirements:
     *
     * - the caller must be an admin authority
     *
     */
    function redeemToken(uint256 tokenId) external onlyAdminRole {
        require(
            tokenId > 0 && tokenId <= 100,
            "ClosedSrc: invalid token ID"
        );
        require(
            tokenRedemptions[tokenId] == false, 
            "ClosedSrc: token already redeemed"
        );
        _requireMinted(tokenId);

        tokenRedemptions[tokenId] = true;

        emit TokenRedeemed(tokenId);
    }


    /**
     * @dev updates the default royalty rate and receiver
     */
    function updateRoyalties(address payable _royaltyReceiver, uint96 _royaltyRate) onlyOwner external {
        _setDefaultRoyalty(_royaltyReceiver, _royaltyRate);
    }


    /**
     * @dev updateRedeemedURI allows the contract owner to update the base
     * URI of redeemed tokens
     * 
     * @param newURI new base URI to use for redeemed tokens
     *
     * Requirements:
     *
     * - the caller must be contract's `owner`.
     *
     */
    function updateRedeemedURI(string calldata newURI) external onlyOwner {
        redeemedURI = newURI;
    }


    /**
     * @dev updateUnredeemedURI allows the contract owner to update the base
     * URI of unredeemed tokens
     * 
     * @param newURI new base URI to use for unredeemed tokens
     *
     * Requirements:
     *
     * - the caller must be contract's `owner`.
     *
     */
    function updateUnredeemedURI(string calldata newURI) external onlyOwner {
        unredeemedURI = newURI;
    }

    //  ──────────────────────  Ownable and Access Control  ───────────────────────  \\

    /**
     * @dev grantAdminRole allows the contract owner to create a new admin.
     *
     * Requirements:
     *
     * - the caller must be contract's `owner`.
     *
     */
    function grantAdminRole(address account) external onlyOwner {
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @dev revokeAdminRole allows the contract owner to remove an admin.
     *
     * Requirements:
     *
     * - the caller must be contract's `owner`.
     *
     */
    function revokeAdminRole(address account) external onlyOwner {
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @dev Throws if called by any account without admin or owner role.
     */
    modifier onlyAdminRole() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || 
            owner() == msg.sender,
            "ClosedSrc: insufficient privileges"
        );
        _;
    }


    // ────────────────────────────────────────────────────────────────────────────────
    // Overrides
    // ────────────────────────────────────────────────────────────────────────────────

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}