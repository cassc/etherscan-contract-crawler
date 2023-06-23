// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


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
 *  - counters removed
 *  - enumerable removed
 *  - token URIs may be set individually
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
    Ownable,
    AccessControlEnumerable,
    ERC721Burnable
{

    using Address for address;
    using Strings for uint256;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint128 internal _totalBurned;                      // Cumulative tokens burned.
    uint128 internal _totalMinted;                      // Cumulative number of tokens minted.
                                                        // Allows burning while correctly counting the next tokenId.
    uint256 public maxSupply;                           // Cap on how many may be minted.

    string internal _baseTokenURI;                      // Settable base uri for tokens.
                                                        // Creates tokenUri as: [_baseTokenURI]/[token number]
    mapping (uint256 => string) internal _tokenURIs;    // Can be manually set by DEFAULT_ADMIN_ROLE.


    /* -------------------------------- Modifiers ------------------------------- */

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "onlyAdmin: caller is not the admin");
        _;
    }

    /* ------------------------------- Constructor ------------------------------ */

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE` and `owner` to the
     * account that deploys the contract.
     */
    constructor(
        string memory name,
        string memory symbol
    ) ERC721(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /* ----------------------------- Public Getters ----------------------------- */

    function totalMinted() public view returns(uint256) {
        return uint256(_totalMinted);
    }

    function totalSupply() public view returns(uint256) {
        return uint256(_totalMinted - _totalBurned);
    }

    function totalBurned() public view returns(uint256) {
        return uint256(_totalBurned);
    }

    function baseURI() public view returns (string memory) {
        return _baseURI();
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
        override(AccessControlEnumerable, ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


   /* ------------------------------ Admin Methods ------------------------------ */


    function setMaxSupply(uint256 supply) public onlyAdmin {
        maxSupply = supply;
    }

    // Sets base URI for all tokens, only able to be called by contract owner
    function setBaseURI(string memory baseURI_) external onlyAdmin {
        _baseTokenURI = baseURI_;
    }

    // Sets Token URI for one tokenID, only able to be called by contract owner
    function setTokenURI(uint256 tokenId, string memory newTokenURI) external onlyAdmin {
        _tokenURIs[tokenId] = newTokenURI;
    }


    /* ----------------------------- Burn Extension ----------------------------- */

    function burn(uint256 tokenId) public override {
        // Increment tracking.
        _totalBurned = _totalBurned + 1;

        // Rely on inherited.
        super.burn(tokenId);
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
        require(hasRole(MINTER_ROLE, msg.sender), "BaseToken: must have minter role to mint");
        
        // Increment first so we start at 1.
        uint128 currentIdx = _totalMinted + 1;
        _totalMinted = currentIdx;

        // Less efficient than checking for batches but the check
        // cannot be missed if checked here.
        require(currentIdx <= maxSupply, "BaseToken: maxSupply exceeded");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, uint256(currentIdx));
    }


    /* -------------------------------- Internal -------------------------------- */

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

}