// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IBlacklist} from "./interfaces/IBlacklist.sol";
import {Counters} from "lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Errors} from "./libraries/Errors.sol";
import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {IKUMABondToken} from "./interfaces/IKUMABondToken.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import {Pausable} from "lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import {Roles} from "./libraries/Roles.sol";

contract KUMABondToken is ERC721, Pausable, IKUMABondToken {
    using Counters for Counters.Counter;

    IAccessControl public immutable override accessController;
    IBlacklist public immutable override blacklist;

    Counters.Counter private _tokenIdCounter;
    string private _uri;

    mapping(uint256 => Bond) private _bonds;

    modifier onlyRole(bytes32 role) {
        if (!accessController.hasRole(role, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, role);
        }
        _;
    }

    /**
     * @dev Throws if argument account is blacklisted
     * @param account The address to check
     */
    modifier notBlacklisted(address account) {
        if (blacklist.isBlacklisted(account)) {
            revert Errors.BLACKLIST_ACCOUNT_IS_BLACKLISTED(account);
        }
        _;
    }

    constructor(IAccessControl _accessController, IBlacklist _blacklist) ERC721("KUMA Bonds", "KUMA") {
        if (address(_accessController) == address(0) || address(_blacklist) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        accessController = _accessController;
        blacklist = _blacklist;
    }

    /**
     * @notice Mints a bond NFT to the specified address.
     * @dev Can only be called under specific conditions :
     *      - Caller must have MINT_ROLE
     *      - Receiver must not be blacklisted
     *      - Contract must not be paused
     * @param to Bond NFT receiver.
     * @param bond Bond struct storing metadata.
     */
    function issueBond(address to, Bond calldata bond)
        external
        override
        onlyRole(Roles.MCAG_MINT_ROLE)
        notBlacklisted(to)
        whenNotPaused
    {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _bonds[tokenId] = bond;
        _safeMint(to, tokenId);
        emit BondIssued(bond.currency, bond.country, bond.term, tokenId);
    }

    /**
     * @notice Burns a bond NFT.
     * @dev Can only be called under specific conditions :
     *      - Caller must have BURN_ROLE
     *      - Contract must not be paused
     * @param tokenId bond Id.
     */
    function redeem(uint256 tokenId) external override onlyRole(Roles.MCAG_BURN_ROLE) whenNotPaused {
        if (_ownerOf(tokenId) != _msgSender()) {
            revert Errors.ERC721_CALLER_IS_NOT_TOKEN_OWNER();
        }
        Bond memory bond = _bonds[tokenId];
        delete _bonds[tokenId];
        _burn(tokenId);
        emit BondRedeemed(bond.currency, bond.country, bond.term, tokenId);
    }

    /**
     * @notice Sets a new base uri.
     * @dev Can only be called by `MCAG_SET_URI_ROLE`.
     * @param newUri New base uri.
     */
    function setUri(string memory newUri) external override onlyRole(Roles.MCAG_SET_URI_ROLE) {
        emit UriSet(_uri, newUri);
        _uri = newUri;
    }

    /**
     * @dev See {Pausable-_pause}.
     */
    function pause() external override onlyRole(Roles.MCAG_PAUSE_ROLE) {
        _pause();
    }

    /**
     * @dev See {Pausable-_unpause}.
     */
    function unpause() external override onlyRole(Roles.MCAG_UNPAUSE_ROLE) {
        _unpause();
    }

    /**
     * @return Current token id counter.
     */
    function getTokenIdCounter() external view override returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @param tokenId Bond id.
     * @return Bond struct storing metadata of the selected bond id.
     */
    function getBond(uint256 tokenId) external view override returns (Bond memory) {
        if (_ownerOf(tokenId) == address(0)) {
            revert Errors.ERC721_INVALID_TOKEN_ID();
        }
        return _bonds[tokenId];
    }

    /**
     * @dev See {IERC721-approve}.
     * @dev Adds the following conditions to the call :
     *      - Caller and spender must not be blacklisted
     *      - Contract must not be paused
     */
    function approve(address to, uint256 tokenId)
        public
        override(ERC721, IERC721)
        whenNotPaused
        notBlacklisted(to)
        notBlacklisted(msg.sender)
    {
        address owner = ERC721.ownerOf(tokenId);

        if (to == owner) {
            revert Errors.ERC721_APPROVAL_TO_CURRENT_OWNER();
        }

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert Errors.ERC721_APPROVE_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED_FOR_ALL();
        }

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     * @dev Adds the following conditions to the call :
     *      - Caller and operator must not be blacklisted
     *      - Contract must not be paused
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(operator)
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     * @dev Adds the following conditions to the call :
     *      - Caller, from and to must not be blacklisted
     *      - Contract must not be paused
     */
    function transferFrom(address from, address to, uint256 tokenId)
        public
        override(ERC721, IERC721)
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(from)
        notBlacklisted(to)
    {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert Errors.ERC721_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED();
        }
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     * @dev Adds the following conditions to the call :
     *      - Caller, from and to must not be blacklisted
     *      - Contract must not be paused
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override(ERC721, IERC721)
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(from)
        notBlacklisted(to)
    {
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert Errors.ERC721_CALLER_IS_NOT_TOKEN_OWNER_OR_APPROVED();
        }
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev See {IERC721-_baseUri}.
     */
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }
}