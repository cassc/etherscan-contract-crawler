// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/* External Imports */
import {AccessControl} from "AccessControl.sol";
import {ERC721} from "ERC721.sol";
import {ERC721Enumerable} from "ERC721Enumerable.sol";
import {Ownable} from "Ownable.sol";
import {ReentrancyGuard} from "ReentrancyGuard.sol";
import {Strings} from "Strings.sol";

/* Internal Imports */
import {BaseErrorCodes} from "ErrorCodes.sol";
import {ERC721Metadata} from "ERC721Metadata.sol";
import {Modifiers} from "Modifiers.sol";

//=====================================================================================================================
/// 😎 Free Internet Money 😎
//=====================================================================================================================

/**
 * @dev Essential state and behavior that every ERC721 contract should have.
 */
contract ERC721Essentials is AccessControl, ERC721Enumerable, ERC721Metadata, Modifiers, Ownable, ReentrancyGuard {
    using Strings for uint256;

    //=================================================================================================================
    /// State Variables
    //=================================================================================================================

    /* Internal */
    uint16 internal _maxSupply;
    uint16 internal _maxMintPerTx;
    uint256 internal _priceInWei;
    bool internal _publicMintingEnabled;

    //=================================================================================================================
    /// Constructor
    //=================================================================================================================

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256[] memory uintArgs_,
        bool publicMintingEnabled_
    ) ERC721(name_, symbol_) {
        _maxSupply = uint16(uintArgs_[0]);
        _priceInWei = uintArgs_[1];
        _maxMintPerTx = uint16(uintArgs_[2]);
        _publicMintingEnabled = publicMintingEnabled_;

        _setBaseURI(baseURI_);
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    //=================================================================================================================
    /// Minting Functionality
    //=================================================================================================================

    /**
     * @dev Public function that mints a specified number of ERC721 tokens.
     * @param numMint uint16: The number of tokens that are going to be minted.
     */
    function mint(uint16 numMint)
        public
        payable
        virtual
        nonReentrant
        whenPublicMintingOpen
        costs(numMint, _priceInWei)
    {
        _mint(numMint);
    }

    /**
     * @dev Internal function that mints a specified number of ERC721 tokens. Contains
     * safety checks related to supply.
     * @param numMint uint16: The number of tokens that are going to be minted.
     */
    function _mint(uint16 numMint) internal virtual _supplySafetyChecks(numMint) {
        _safeMintTokens(_msgSender(), numMint);
    }

    /**
     * @dev Public function that mints tokens to a set of wallet addresses. Each address has a specified number of
     * ERC721 tokens minted to it. Contains basic safety checks to ensure supply of tokens stays within limits.
     * This function is non-payable and thus is only callable by contract admins. The function is a naïve way to perform an
     * an airdrop and is pretty rough on gas. That being said, for small drops, the added surprise of users just "finding it"
     * in their wallet is kind of cool. Unless you don't mind eating a ton of gas, a merkle tree redemption method is recommended
     * for anything large scale.
     * @param addrs address[] memory: List of addresses to which tokens will be sent to. Setting this to an empty list will mint
     * the tokens to _msgSender().
     * @param numMint uint16: The number of tokens that are going to be minted to each address.
     */
    function mintAirDrop(address[] memory addrs, uint16 numMint)
        public
        virtual
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (addrs.length == 0) {
            // If no specified addresses, mint to the caller.
            address[] memory temp = new address[](1);
            temp[0] = _msgSender();
            _mintAirDrop(temp, numMint);
        } else {
            _mintAirDrop(addrs, numMint);
        }
    }

    /**
     * @dev Internal function that mints tokens to set a of wallet addresses.
     * @param addrs address[] memory: List of addresses to which tokens will be sent to. Setting this to an empty list will mint
     * the tokens to _msgSender().
     * @param numMint uint16: The number of tokens that are going to be minted to each address.
     */
    function _mintAirDrop(address[] memory addrs, uint16 numMint)
        internal
        virtual
        _supplySafetyChecks(uint16(addrs.length * numMint))
    {
        for (uint16 i = 0; i < addrs.length; i += 1) {
            _safeMintTokens(addrs[i], numMint);
        }
    }

    /**
     * @dev Internal function that mints a specified number of ERC721 tokens to a specific address.
     * contains NO SAFETY CHECKS and thus should be wrapped in a function that does.
     * @param to_ address: The address to mint the tokens to.
     * @param numMint uint16: The number of tokens to be minted.
     */
    function _safeMintTokens(address to_, uint16 numMint) internal {
        for (uint16 i = 0; i < numMint; i += 1) {
            _safeMint(to_, totalSupply() + 1);
        }
    }

    //=================================================================================================================
    /// Accessors
    //=================================================================================================================

    /**
     * @dev returns minting access.
     */
    function publicMintingEnabled() public view virtual returns (bool) {
        return _publicMintingEnabled;
    }

    /**
     * @dev Public function that returns the maximum number of ERC721 tokens that can exist under this contract.
     */
    function maxSupply() public view virtual returns (uint16) {
        return _maxSupply;
    }

    /**
     * @dev Public function that returns the price for the mint.
     */
    function priceInWei() public view virtual returns (uint256) {
        return _priceInWei;
    }

    /**
     * @dev Public function that returns the max number of mints per sent transaction.
     */
    function maxMintPerTx() public view virtual returns (uint16) {
        return _maxMintPerTx;
    }

    //=================================================================================================================
    /// Mutators
    //=================================================================================================================

    /**
     * @dev Set minting access. Only callable by contract admins.
     */
    function setPublicMinting(bool publicMintingEnabled_) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _publicMintingEnabled = publicMintingEnabled_;
    }

    /**
     * @dev Public function that sets the maximum number of ERC721 tokens that can exist under this contract.
     * @param newSupply uint16: The new maximum number of tokens.
     */
    function setSupply(uint16 newSupply) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _maxSupply = newSupply;
    }

    /**
     * @dev Public function that sets the price for the mint. Only callable by contract admins.
     * @param newPrice uint256: The new price.
     */
    function setPriceInWei(uint256 newPrice) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _priceInWei = newPrice;
    }

    /**
     * @dev Public function that sets the max number of mints per sent transaction. Only callable by contract admins.
     * @param newMaxMintPerTx uint256: The new max.
     */
    function setMaxMintPerTx(uint16 newMaxMintPerTx) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _maxMintPerTx = newMaxMintPerTx;
    }

    //=================================================================================================================
    /// Metadata URI
    //=================================================================================================================

    /**
     * @dev Public function that sets the baseURI of this ERC721 token.
     * @param newBaseURI string memory: The baseURI of the contract.
     */
    function setBaseURI(string memory newBaseURI) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(newBaseURI);
    }

    /**
     * @dev Internal function that retrieves the baseURI of this ERC721 token.
     * @return string memory: The baseURI of the contract.
     */
    function _baseURI() internal view virtual override(ERC721, ERC721Metadata) returns (string memory) {
        return super._baseURI();
    }

    /**
     * @dev Public function that retrieves the tokenURI of a ERC721 token. For more info please view the
     * ERC721 spec: https://eips.ethereum.org/EIPS/eip-721.
     * @param tokenId uint256: The tokenId to be queried.
     * @return string memory: The tokenURI of the queried token.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721Metadata) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    //=================================================================================================================
    /// Required Overrides
    //=================================================================================================================

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    //=================================================================================================================
    /// Useful Checks & Modifiers
    //=================================================================================================================

    /**
     * @dev A function to verify that the token supply will is in a valid state and will remain in a valid
     * state after the creation of a set number of tokens.
     * @param numMint uint16: The number of tokens requested to be created.
     */
    function _requireBasicSupplySafetyChecks(uint16 numMint) internal view {
        require(totalSupply() < _maxSupply, kErrSoldOut);
        require(totalSupply() + numMint <= _maxSupply, kErrRequestTooLarge);
        require(
            (numMint > 0 && numMint <= _maxMintPerTx) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            kErrOutsideMintPerTransaction
        );
    }

    /**
     * See {ERC721BasicMint-_requireBasicSupplySafetyChecks}
     */
    modifier _supplySafetyChecks(uint16 numMint) {
        _requireBasicSupplySafetyChecks(numMint);
        _;
    }

    /**
     * @dev A modifier to guard the minting functions thus allowing minting to be enabled & disabled.
     */
    modifier whenPublicMintingOpen() {
        require(_publicMintingEnabled || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), kErrMintingIsDisabled);
        _;
    }
}