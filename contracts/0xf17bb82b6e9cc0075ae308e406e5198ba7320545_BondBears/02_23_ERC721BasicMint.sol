// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/* External Imports */
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/* Internal Imports */
import {ERC721URIStorageLite} from "./ERC721URIStorageLite.sol";
import {Constants} from "../../utils/Constants.sol";
import {Modifiers} from "../../utils/Modifiers.sol";

//=====================================================================================================================
/// 😎 Free Internet Money 😎
//=====================================================================================================================

contract ERC721BasicMint is
    ERC721URIStorageLite,
    ERC721Enumerable,
    AccessControl,
    Ownable,
    Pausable,
    ReentrancyGuard,
    Modifiers
{
    using Counters for Counters.Counter;
    using SafeMath for uint16;
    using SafeMath for uint256;
    using Strings for string;

    //=================================================================================================================
    /// State Variables
    //=================================================================================================================

    /* Public */
    uint16 public maxSupply;
    uint16 public maxMintPerTx;
    uint256 public priceInWei;
    uint256 public launchTime;
    bool public publicMintingEnabled;

    /* Private */
    Counters.Counter private _tokenIdCounter;

    //=================================================================================================================
    /// Constructor
    //=================================================================================================================

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_
    ) ERC721(name_, symbol_) {
        _setBaseURI(baseURI_);
        _setContractURI(contractURI_);
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
        whenNotPaused
        opensAt(launchTime, "Minting has not started yet")
        costs(numMint, priceInWei)
    {
        _mint(numMint);
    }

    /**
     * @dev Internal function that mints a specified number of ERC721 tokens. Contains
     * safety checks related to payment, security and supply.
     * @param numMint uint16: The number of tokens that are going to be minted.
     */
    function _mint(uint16 numMint) internal virtual _supplySafetyChecks(numMint) {
        _safeMintTokens(_msgSender(), numMint);
    }

    /**
     * @dev Public function that mints tokens to a set of wallet addresses. Each address has a specified number of 
     * ERC721 tokens minted to it. Contains basic safety checks to ensure supply of tokens stays within limits. 
     * This function is non-payable and thus is only callable by contract admins.
     * @param addrs address[] memory: List of addresses to which tokens will be sent to.
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
     * @dev Internal function that mints tokens to set a of wallet addresses. Each address is minted
     * a specified number of ERC721 token. Contains basic safety checks to ensure supply of tokens stays within limits.
     * @param addrs address[] memory: List of addresses to which tokens will be sent to.
     * @param numMint uint16: The number of tokens that are going to be minted to each address.
     */
    function _mintAirDrop(address[] memory addrs, uint16 numMint)
        internal
        virtual
        _supplySafetyChecks(uint16((addrs.length).mul(numMint)))
    {
        for (uint16 i = 0; i < addrs.length; ++i) {
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
        for (uint16 i = 0; i < numMint; ++i) {
            _tokenIdCounter.increment();
            _safeMint(to_, _tokenIdCounter.current());
        }
    }

    //=================================================================================================================
    /// Metadata URI
    //=================================================================================================================

    /**
     * @dev External function that sets the contractURI Only callable by contract admins.
     * For more info: https://docs.opensea.io/docs/contract-level-metadata
     * @param newContractURI string memory: The new contractURI.
     */
    function setContractURI(string memory newContractURI) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _setContractURI(newContractURI);
    }

    /**
     * @dev External function that sets the base string of TokenURIs. Only callable by contract admins.
     * @param newBaseURI string memory: The new baseURI.
     */
    function setBaseURI(string memory newBaseURI) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _setBaseURI(newBaseURI);
    }

    /**
     * @dev Internal function that retrieves the baseURI of this ERC721 token.
     * @return string memory: The baseURI of the contract.
     */
    function _baseURI() internal view virtual override(ERC721, ERC721URIStorageLite) returns (string memory) {
        return super._baseURI();
    }

    /**
     * @dev Public function that retrieves the tokenURI of a ERC721 token. For more info please view the
     * ERC721 spec: https://eips.ethereum.org/EIPS/eip-721.
     * @param tokenId uint256: The tokenId to be queried.
     * @return string memory: The tokenURI of the queried token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721, ERC721URIStorageLite)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    //=================================================================================================================
    /// Misc. Administrative
    //=================================================================================================================

    /**
     * @dev External function that pauses the contract. Only callable by contract admins.
     * FOR EMERGENCY USE ONLY - Pauses all aspects of the contract, not overly applicable for
     * ERC721BasicMint, but may be quite useful for future children of this contract.
     *
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * @dev External function that unpauses the contract. Only callable by contract admins.
     * FOR EMERGENCY USE ONLY - Unpauses all aspects of the contract, not overly applicable for
     * ERC721BasicMint, but may be quite useful for future children of this contract.
     */
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * @dev Set minting access. Only callable by contract admins.
     */
    function setPublicMinting(bool _publicMintingEnabled) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        publicMintingEnabled = _publicMintingEnabled;
    }

    /**
     * @dev Public function that sets the maximum number of ERC721 tokens that exist under this contract.
     * If supply is reduced below the number of tokens that have already been minted, tokens above the
     * threshold WILL be burned and lost forever. Not sure how much I love this function, so it's
     * behavior will likely be revisited in the future.
     * @param newSupply uint16: The new maximum number of tokens.
     * @param confirmation uint256: A combination of digits that must be sent with the contract for it to execute.
     */
    function setSupply(uint16 newSupply, uint256 confirmation) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        // Require a confirmation code to prevent accidental burn
        require(confirmation == 73435567465418567456694564986745984357984);
        for (uint16 i = maxSupply; i > newSupply; --i) {
            if (_exists(i)) {
                _burn(i);
            }

            // Not really important, since if this logic happens the mint is over. 
            // But does prevent the counter from getting in a bad state, so it felt wrong not to add this.
            if (i < _tokenIdCounter.current()) {
                _tokenIdCounter.decrement();
            }
        }
        maxSupply = newSupply;
    }

    /**
     * @dev Public function that sets the price for the mint. Only callable by contract admins.
     * @param newPrice uint256: The new price.
     */
    function setPrice(uint256 newPrice) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        priceInWei = newPrice;
    }

    /**
     * @dev Public function that sets the max number of mints per sent transaction. Only callable by contract admins.
     * @param newMaxMintPerTx uint256: The new max.
     */
    function setMaxMintPerTx(uint16 newMaxMintPerTx) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        maxMintPerTx = newMaxMintPerTx;
    }

    /**
     * @dev Public function that sets the time for the mint to begin at. Time is stored as an integer represent the
     * number of seconds since January 1st, 1970. This is referred to as epoch time. Only callable by contract admins.
     * @param newLaunchTime uint256: The new launch time.
     */
    function setLaunchTime(uint256 newLaunchTime) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        launchTime = newLaunchTime;
    }

    /**
     * @dev Public function that pulls a set amount of Ether from the contract. Only callable by contract admins.
     * @param amount uint256: The amount of wei to withdraw from the contract.
     */
    function withdraw(uint256 amount) public nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        require(amount <= address(this).balance); // dev: Insufficient contract balance
        (bool noErr, ) = payable(_msgSender()).call{value: amount}("");
        require(noErr); // dev: Failed to withdraw
    }

    /**
     * @dev Public function that pulls the entire balance of Ether from the contract. Only callable by contract admins.
     */
    function withdrawAll() public nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool noErr, ) = payable(_msgSender()).call{value: address(this).balance}("");
        require(noErr); // dev: Failed to withdraw
    }

    //=================================================================================================================
    /// Other Required Functions
    //=================================================================================================================

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, AccessControl)
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
    ) internal virtual override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    //=================================================================================================================
    /// Useful Checks & Modifiers
    //=================================================================================================================

    /**
     * @dev An function to make sure the contract is in a good state before intiating the minting process.
     * @return string memory: A human readible string contanting information about the state of the contract.
     */
    function preflightCheck() external view returns (string memory) {
        require(publicMintingEnabled);
        require(paused() == false, "Contract is Paused");
        require(totalSupply() == 0, "Supply is not Empty");
        require(bytes(_baseURI()).length == Constants.IPFS_URI_LENGTH(), "baseURI is of improper length");
        int256 countdown = int256(launchTime) - int256(block.timestamp);
        if (countdown <= 0) return string("All systems are go. We are Launched.");
        return
            string(
                abi.encodePacked("All systems are go. Launch in: t-", Strings.toString(uint256(countdown)), " seconds")
            );
    }

    /**
     * @dev A function to verify that the token supply will is in a valid state and will remain in a valid
     * state after the creation of a set number of tokens.
     * @param numMint uint16: The number of tokens requested to be created.
     */
    function _requireBasicSupplySafetyChecks(uint16 numMint) internal view {
        require(totalSupply() < maxSupply, "Sold Out");
        require(totalSupply().add(numMint) <= maxSupply, "Requested more Tokens than remaining");
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || (numMint > 0 && numMint <= maxMintPerTx), "Outside mint per tx range");
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
        require(publicMintingEnabled || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) , "Minting is disabled");
        _;
    }
}