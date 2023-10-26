// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./interfaces/IRegistry.sol";

/**
 * @dev {ERC721} Modified OZ Presets to get around private vs internal variables. includes:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - token ID and URI autogeneration
 *
 * Differs from OZ contract:
 *  - counter incrementing occurs prior to each mint; token IDs start with 1.
 *  - pausing removed
 *  - token URIs may be set individually
 *  - defers to registry for supply cap
 *  - uses admin role for setters (owner role for OpenSea related store setup)
 *
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and owner
 * roles, as well as the default admin role, which will let it grant both minter
 * and owner roles to other accounts.
 */
contract BaseToken is
    ContextUpgradeable,
    OwnableUpgradeable,
    AccessControlEnumerableUpgradeable,
    ERC721EnumerableUpgradeable,
    ERC721BurnableUpgradeable
{

    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    CountersUpgradeable.Counter internal _minted;       // Cumulative tokens minted.
                                                        // Allows burning while correctly counting the next tokenId.

    string internal _baseTokenURI;                      // Settable base url for tokens. Creates tokenUri as: [_baseTokenURI]/[token number]
    mapping (uint256 => string) internal _tokenURIs;    // Can be manually set by OWNER_ROLE.
    address public registry;


    /* -------------------------------- Modifiers ------------------------------- */

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "onlyAdmin: caller is not the admin");
        _;
    }

    /* ------------------------------- Constructor ------------------------------ */

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `OWNER_ROLE` to the
     * account that deploys the contract.
     */
    function initialize(
        string memory name_,
        string memory symbol_
    )
        public
        initializer
    {

        __Context_init_unchained();
        __ERC165_init_unchained();

        __Ownable_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();

        __ERC721_init_unchained(name_, symbol_);
        __ERC721Enumerable_init_unchained();
        __ERC721Burnable_init_unchained();


        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        registry = _msgSender();

    }


    /* ----------------------------- Public Getters ----------------------------- */

    function maxSupply() public view returns (uint256) {
        return IRegistry(registry).getProjectMaxSupply(address(this));
    }

    function license() public view returns (string memory) {
        return IRegistry(registry).getProjectLicense(address(this));
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    function totalMinted() public view returns (uint256) {
        return _minted.current();
    }

    function getUserBalance(address user) public view returns (uint256) {
        return balanceOf(user);
    }

    function getTokenOfUserByIndex(address user, uint256 index) public view returns (uint256) {
        return tokenOfOwnerByIndex(user, index);
    }



    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI OR if both are set, return the token URI.
        if (bytes(base).length == 0 || bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, (tokenId).toString()));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerableUpgradeable, ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


   /* ------------------------------ Admin Methods ------------------------------ */

    // Sets base URI for all tokens, only able to be called by contract owner
    function setBaseURI(string memory baseURI_) external onlyAdmin {
        _baseTokenURI = baseURI_;
    }

    // Sets Token URI for one tokenID, only able to be called by contract owner
    function setTokenURI(uint256 tokenId, string memory newTokenURI) external onlyAdmin {
        _tokenURIs[tokenId] = newTokenURI;
    }


    /* ----------------------------- Minter Methods ----------------------------- */

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "BaseToken: must have minter role to mint");

        // Increment first so we start at 1.
        _minted.increment();
        uint256 currentIdx = _minted.current();

        // Less efficient than checking for batches but the check
        // cannot be missed if checked here.
        require(currentIdx <= maxSupply(), "BaseToken: maxSupply exceeded");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, currentIdx);
    }


    /* -------------------------------- Internal -------------------------------- */

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

}