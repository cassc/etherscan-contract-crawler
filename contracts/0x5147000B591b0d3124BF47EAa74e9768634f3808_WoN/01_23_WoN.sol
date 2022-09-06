// SPDX-License-Identifier: UNLICENSED
// Author: KDon.eth <[email protected]>
// Date: August 12th, 2022
// Purpose: Issue NFTs for the Women of Narcolepsy project

pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721Burnable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import {ERC2981} from "@openzeppelin/contracts/token/common/ERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

/**
 * @title Women of Narcolepsy
 *
 * @author KDon.eth <[email protected]>
 *
 * @notice The Women of Narcolepsy (WoN) NFT Collection was created with the goal
 * of raising awareness and funds for Narcolepsy research. Each unique artwork
 * was created by Kylie Pine – a self-taught digital artist, who was diagnosed
 * with Narcolepsy at an early age. 
 * 
 * To learn more, please visit [the Women of Narcolepsy site.](https://womenofnarcolepsy.com/)
 *
 * @dev Women of Narcolepsy is an ERC-721 smart contract that implements the Metadata,
 * Enumerable, and Burnable extensions, and additionally conform to the ERC-2981
 * royalty standard. The smart contract utilizes Openzeppelin's Ownable and Access
 * Control (Enumerable) libraries for access control, and Reentrancy Guard for
 * Security purposes.
 *
 * @custom:security-contact KDon.eth <[email protected]>
 */
contract WoN is
    ERC721,
    ERC721Enumerable,
    ERC721Burnable,
    ERC2981,
    Ownable,
    AccessControlEnumerable,
    ReentrancyGuard
{
    // ────────────────────────────────────────────────────────────────────────────────
    // Contract Definitions
    // ────────────────────────────────────────────────────────────────────────────────

    //  ────────────────────────────────  Events  ─────────────────────────────────  \\

    /**
     * @dev Notifies when mint price is updated
     */
    event MintPriceChanged(uint256 price);

    /**
     * @dev Notifies when token URI is updated
     */
    event URIUpdate(string newURI);


    //  ────────────────────────────────  Fields  ─────────────────────────────────  \\

    /// @dev for setting a maximum supply
    uint256 public immutable maxSupply;

    /// @dev for token URI encoding
    string private baseURI;

    /// @dev mint price in wei
    uint256 public mintPrice;

    /// @dev address that will receive all initial payments
    address payable private mintPaymentReceiver;

    //  ────────────────────────────  Initialization  ─────────────────────────────  \\

    /**
     * @param _name token's display name. Women of Narcolepsy
     * @param _symbol token's ticker symbol. WoN
     * @param _uri base URI for tokens. Token URI will return baseURI concatenating tokenID
     * @param _maxSupply maximum number of tokens that may be issued. Cannot be overwritten
     * @param _mintPrice initial mint price for tokens
     * @param _mintPaymentReceiver payable address that will receive mint ETH
     * @param _royaltyReceiver payable address that will receive royalty. 0xSplit wallet
     * @param _defaultRoyaltyRate royalty rate in basis points
     */
    constructor(
        string memory _name, 
        string memory _symbol, 
        string memory _uri, 
        uint256 _maxSupply, 
        uint256 _mintPrice,
        address payable _mintPaymentReceiver,
        address payable _royaltyReceiver,
        uint96 _defaultRoyaltyRate
    ) ERC721(_name, _symbol) {
        baseURI = _uri;
        maxSupply = _maxSupply;
        mintPrice = _mintPrice;
        mintPaymentReceiver = _mintPaymentReceiver;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setDefaultRoyalty(_royaltyReceiver, _defaultRoyaltyRate);
    }


    // ────────────────────────────────────────────────────────────────────────────────
    // User Functionality
    // ────────────────────────────────────────────────────────────────────────────────

    //  ─────────────────────────────────  Mint  ──────────────────────────────────  \\

    /**
     * @notice mints a single token
     * 
     * @param to address that will receive the token
     */
    function mint(address to) payable nonReentrant external {
        require(
            msg.value >= mintPrice,
            "WoN: Insufficient funds"
        );
        mintPaymentReceiver.transfer(msg.value);

        _mint(to);
    }

    /**
     * @notice mints numerous tokens in one call
     * 
     * @dev requires the msg.value to be equal to or greater than the 
     * product of quantity and mintPrice
     * 
     * @param to the address that will receive the newly minted tokens
     * @param quantity the number of tokens to mint
     */
    function batchMint(address to, uint256 quantity) payable nonReentrant external {
        uint256 totalPrice = mintPrice * quantity;
        require(
            msg.value >= totalPrice, 
            "WoN: Insufficient funds"
        );
        mintPaymentReceiver.transfer(msg.value);
        
        _batchMint(to, quantity);
    }

    /// @dev required for contract can receive ETH
    receive() payable external {}
    
    //  ─────────────────────────────  Transferring  ──────────────────────────────  \\

    /**
     * @dev required overwrite due to conflicting implementations. Added totalSupply
     * check when address is from 0x0 (indicating a new mint)
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        if (from == address(0) && maxSupply != 0) {
            require(totalSupply() + 1 <= maxSupply, "WoN: exceeds max supply.");
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }


    //  ───────────────────────────────  Metadata  ────────────────────────────────  \\

    /// @dev overwrite hook to optimize memory layout
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }


    // ────────────────────────────────────────────────────────────────────────────────
    // Admin Functionality
    // ────────────────────────────────────────────────────────────────────────────────

    //  ────────────────────────────  Access Control  ─────────────────────────────  \\

    /**
     * @dev grantAdminRole allows the contract owner to give admin privileges
     * to a new admin.
     *
     * Requires:
     * Caller must be contract `owner`
     *
     */
    function grantAdminRole(address account) external onlyOwner {
        _grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @dev revokeAdminRole allows the contract owner to remove an admin.
     *
     * Requires:
     * Caller must be contract `owner`.
     *
     */
    function revokeAdminRole(address account) external onlyOwner {
        _revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    /**
     * @dev Throws if called by any account without admin or owner role.
     */
    modifier onlyAdmin() {
        require(
            isPrivileged(_msgSender()),
            "WoN: Caller is not an Admin or contract owner."
        );
        _;
    }

    /**
     * @dev Check is account is `owner` or has admin privileges.
     *
     * @param account address whose privileges will be checked.
     *
     * @return `true` if account is `owner` or Admin, `false` otherwise.
     */
    function isPrivileged(address account) private view returns (bool) {
        return account == owner() || hasRole(DEFAULT_ADMIN_ROLE, account);
    }


    //  ────────────────────────────  Token Minting  ──────────────────────────────  \\

    /**
     * @dev allows admin to mint a single token at next available ID for free
     * 
     * @param to address to send token to
     * 
     * Requirements:
     *     - caller requires admin priveleges
     */
    function mintAdmin(address to) external nonReentrant onlyAdmin {
        _mint(to);
    }

    /// @dev private mint function to allow nonReentrant functions to share implementation
    function _mint(address to) private {
        uint256 nextAvailableId = totalSupply();
        _safeMint(to, nextAvailableId);
        assert(totalSupply() == nextAvailableId + 1 && ownerOf(nextAvailableId) == to);
    }

    /**
     * @dev allows admin to mint multiple tokens for free
     * 
     * @param to address to send token to
     * @param quantity number of tokens to mint
     * 
     * Requirements:
     *     - caller requires admin priveleges
     */
    function batchMintAdmin(address to, uint256 quantity) external nonReentrant onlyAdmin {
        _batchMint(to, quantity);
    }

    /// @dev private batch mint function to allow nonReentrant functions to share implementation
    function _batchMint(address to, uint256 quantity) private {
        uint256 nextAvailableId = totalSupply();
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(to, nextAvailableId + i);
        }
        assert(totalSupply() == nextAvailableId + quantity);
    }

    //  ────────────────────────────  Sale Price  ─────────────────────────────────  \\

    /**
     * @dev updates the mint price
     * 
     * @param newPrice price in wei for new mints
     * 
     * Requirements:
     *     - caller requires owner priveleges
     * 
     * Emits a {MintPriceChanged} event.
     */
    function updateMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;

        emit MintPriceChanged(newPrice);
    }

    //  ──────────────────────────────  Funds  ────────────────────────────────────  \\

    /**
     * @dev withdraw any Eth held by contract
     * 
     * Requirements:
     *     - caller requires owner priveleges
     */
    function withdrawEth(address payable recipient) external onlyOwner {
        recipient.transfer(address(this).balance);
    }

    //  ─────────────────────────────  Royalties  ─────────────────────────────────  \\

    /**
     * @dev updates the royalty receiver and rate in basis points
     * 
     * @param receiver address that will receive funds
     * @param rate royalty rate in basis points
     * 
     * Requirements:
     *     - caller requires owner priveleges
     */
    function updateRoyalty(address receiver, uint96 rate) external onlyOwner {
        _setDefaultRoyalty(receiver, rate);
    }

    //  ─────────────────────────────  Update URI  ────────────────────────────────  \\

    /**
     * @dev updates the base URI of the contract.
     * 
     * * Requirements:
     *     - caller requires owner priveleges
     * 
     * Emits a {URIUpdate} event.
     */
    function updateURI(string memory uri) external onlyOwner {
        baseURI = uri;

        emit URIUpdate(uri);
    }


    // ──────────────────────  Supports Interface {ERC165}  ──────────────────────   \\

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControlEnumerable, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}