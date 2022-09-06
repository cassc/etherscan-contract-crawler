// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "./Allowlist.sol";

/// @title A non-fungible token that represents ownership of a home.
/// @author Roofstock onChain team
contract HomeOnChainToken is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable, PausableUpgradeable, ERC721BurnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    string private _baseTokenURI;
    address private _allowlistContractAddress;
    event AllowlistContractAddressChanged(address indexed allowlistContractAddress);

    mapping(uint256 => uint256) private sellable;
    event SellableExpirationChanged(uint256 indexed tokenId, uint256 indexed expiration);

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SELLABLE_GRANTOR_ROLE = keccak256("SELLABLE_GRANTOR_ROLE");

    /// @notice Initializes the contract.
    /// @param allowlistContractAddress The default value of the allowlist contract address.
    function initialize(address allowlistContractAddress)
        initializer
        public
    {
        __ERC721_init("Home onChain", "HoC");
        __ERC721Enumerable_init();
        __AccessControl_init();

        _baseTokenURI = "https://onchain.roofstock.com/metadata/";

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(SELLABLE_GRANTOR_ROLE, msg.sender);

        setAllowlistContractAddress(allowlistContractAddress);
    }

    /// @notice Mints new tokens.
    /// @dev Only Roofstock onChain can mint new tokens.
    /// @param to The address that will own the token after the mint is complete.
    function mint(address to)
        public
        onlyRole(MINTER_ROLE)
    {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    /// @notice Sets the contract address for the allowlist.
    /// @param allowlistContractAddress The new allowlist contract address.
    function setAllowlistContractAddress(address allowlistContractAddress)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(allowlistContractAddress != address(0), "HomeOnChainToken: Allowlist smart contract address must exist");
        _allowlistContractAddress = allowlistContractAddress;
        emit AllowlistContractAddressChanged(allowlistContractAddress);
    }

    /// @notice Pauses transfers on the contract.
    /// @dev Can be called by Roofstock onChain to halt transfers.
    function pause()
        public
        onlyRole(PAUSER_ROLE)
    {
        _pause();
    }

    /// @notice Unpauses transfers on the contract.
    /// @dev Can be called by Roofstock onChain to resume transfers.
    function unpause()
        public 
        onlyRole(PAUSER_ROLE)
    {
        _unpause();
    }

    /// @notice Gets the base URI for all tokens.
    /// @return The token base URI.
    function _baseURI()
        internal
        view
        override(ERC721Upgradeable)
        returns (string memory)
    {
        return _baseTokenURI;
    }

    /// @notice Sets the base URI for all tokens.
    /// @param baseTokenURI The new base URI.
    function setBaseURI(string memory baseTokenURI)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _baseTokenURI = baseTokenURI;
    }

    /// @notice Override that is called before all transfers.
    /// @dev Verifies that the recipient is on the allowlist (unless burning) and the token is sellable (unless minting).
    /// @param from The address where the token is coming from.
    /// @param to The address where the token is going to.
    /// @param tokenId The id of the token
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        require(to == address(0) || isAllowed(to), "HomeOnChainToken: To address must be on the allowlist");
        require(from == address(0) || isSellable(tokenId), "HomeOnChainToken: TokenId must be sellable");
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Checks against the accompanied Allowlist contract.
    /// @param _address The address that you want to check.
    /// @return Whether the address is on the allowlist.
    function isAllowed(address _address)
        private
        view
        returns (bool)
    {
        Allowlist allowlistContract = Allowlist(_allowlistContractAddress);
        return allowlistContract.isAllowed(_address);
    }

    /// @notice Sets the date the token is sellable until.
    /// @dev Can only be set by Roofstock onChain after we verify the property is in good standing.
    /// @param tokenId The token for which the expiration is set.
    /// @param expiration The expiration date.
    function setSellableExpiration(uint256 tokenId, uint256 expiration)
        public
        onlyRole(SELLABLE_GRANTOR_ROLE)
    {
        require(_exists(tokenId), "HomeOnChainToken: TokenId must exist");
        sellable[tokenId] = expiration;
        emit SellableExpirationChanged(tokenId, expiration);
    }

    /// @notice Gets the date for which the token can no longer be sold.
    /// @param tokenId The token for which the expiration inquiry is made.
    /// @return The date that the token expires.
    function getSellableExpiration(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return sellable[tokenId];
    }

    /// @notice Gets whether a token is currently available to sell.
    /// @param tokenId The token to check sellability.
    /// @return A boolean that represents whether the token is sellable.
    function isSellable(uint256 tokenId)
        private
        view
        returns (bool)
    {
        return sellable[tokenId] > block.timestamp;
    }

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}