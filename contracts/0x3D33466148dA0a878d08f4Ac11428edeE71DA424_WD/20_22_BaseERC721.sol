// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @dev {BaseERC721} including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - a uri setter role that allows to update uri
 *
 * This contract uses {AccessControlEnumerable} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract BaseERC721 is ERC721URIStorage, Pausable, AccessControlEnumerable {
    using Counters for Counters.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");

    string private _baseTokenURI;
    Counters.Counter private _tokenIds;

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function baseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        override(ERC721, AccessControlEnumerable)
        view
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public override(ERC721URIStorage) view returns (string memory) {
        return super.tokenURI(tokenId);
    }

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    constructor(string memory baseTokenURI_) ERC721("WatchDog", "WD") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);

        _baseTokenURI = baseTokenURI_;
    }

    /**
     * @dev Burn WD token and payment fee.
     * @param account Account for burn WD.
     * @param id WD collection id.
     */
    function burn(address account, uint256 id) internal virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC721: caller is not token owner nor approved"
        );
        super._burn(id);
    }

    /**
     * @dev See {ERC721-_exists}.
     */
    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, string memory uri) internal onlyRole(MINTER_ROLE) returns (uint256 tokenId) {
        _tokenIds.increment();
        tokenId = _tokenIds.current();
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev Sets new `_baseTokenURI`.
     *
     * Requirements:
     *
     * - the caller must have the `URI_SETTER_ROLE`.
     */
    function setBaseURI(string memory baseTokenURI_) public onlyRole(URI_SETTER_ROLE) {
        _baseTokenURI = baseTokenURI_;
    }

    /**
     * @dev See {ERC721-_baseURI}.
     */
    function _baseURI() internal override view returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {ERC721Supply-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, 1);
        if (from != address(0) && to != address(0)) {
            revert("Transfer is not supported");
        }
    }
}