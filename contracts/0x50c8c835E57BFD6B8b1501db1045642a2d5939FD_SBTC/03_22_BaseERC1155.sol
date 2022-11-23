// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @dev {BaseERC1155} including:
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
abstract contract BaseERC1155 is ERC1155URIStorage, AccessControlEnumerable, Pausable, ERC1155Supply {
    using Counters for Counters.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");

    string private _baseTokenURI;
    Counters.Counter private _tokenIds;

    /**
     * @dev See {ERC1155-_baseURI}.
     */
    function baseURI() public view returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Collection name.
     */
    function name() public pure returns (string memory) {
        return "SBT Collections";
    }

    /**
     * @dev Collection symbol.
     */
    function symbol() public pure returns (string memory) {
        return "SBTC";
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        override(ERC1155, AccessControlEnumerable)
        view
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155Metadata-tokenURI}.
     */
    function uri(uint256 tokenId) public override(ERC1155, ERC1155URIStorage) view returns (string memory) {
        return super.uri(tokenId);
    }

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
     * deploys the contract.
     */
    constructor(string memory baseTokenURI_) ERC1155(baseTokenURI_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);

        _baseTokenURI = baseTokenURI_;
    }

    /**
     * @dev Burn SBT token and payment fee.
     * @param account Account for burn SBT.
     * @param id SBT collection id.
     */
    function burn(address account, uint256 id) internal virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        super._burn(account, id, 1);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
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
     * See {ERC1155Pausable} and {Pausable-_unpause}.
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
     * @param account Recipients SBT token.
     * @param tokenURI URI metadata for SBT token.
     *
     * See {ERC1155-_mint}.
     */
    function mint(address account, string memory tokenURI) internal virtual returns (uint256 tokenId) {
        _tokenIds.increment();
        tokenId = _tokenIds.current();
        _mint(account, tokenId, 1, "0x0");
        _setURI(tokenId, tokenURI);
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
     * @dev See {ERC1155-_baseURI}.
     */
    function _baseURI() internal view returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev See {ERC1155Supply-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) whenNotPaused {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (from != address(0) && to != address(0)) {
            revert("Transfer is not supported");
        }
    }
}