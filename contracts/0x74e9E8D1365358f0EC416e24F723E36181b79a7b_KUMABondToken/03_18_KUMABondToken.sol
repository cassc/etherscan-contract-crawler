// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {IBlacklist} from "./interfaces/IBlacklist.sol";
import {Counters} from "lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {IERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {Errors} from "./libraries/Errors.sol";
import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {IKUMABondToken} from "./interfaces/IKUMABondToken.sol";
import {Pausable} from "lib/openzeppelin-contracts/contracts/security/Pausable.sol";
import {Roles} from "./libraries/Roles.sol";

/**
 * @title KUMA Bonds NFT
 * @author Mimo Labs
 * @notice KUMA Bond NFTs are NFTs who's yield is backed by real-world assets
 */
contract KUMABondToken is ERC721, Pausable, IKUMABondToken {
    using Counters for Counters.Counter;

    uint256 public constant MIN_COUPON = 1e27;

    IAccessControl public immutable accessController;
    IBlacklist public immutable blacklist;

    uint256 private _maxCoupon;

    Counters.Counter private _tncCounter;
    Counters.Counter private _tokenIdCounter;

    string private _uri;

    mapping(uint256 => Bond) private _bonds;
    mapping(uint256 => string) private _tncUrls;

    /**
     * @dev Modifier to make a function callable only when the caller has a specific role
     * @param role The role required to call the function
     */
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

    constructor(IAccessControl _accessController, IBlacklist _blacklist, uint256 maxCoupon)
        ERC721("KUMA Bonds", "KUMA")
    {
        if (address(_accessController) == address(0) || address(_blacklist) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        if (maxCoupon < MIN_COUPON) {
            revert Errors.INVALID_MAX_COUPON();
        }

        accessController = _accessController;
        blacklist = _blacklist;
        _maxCoupon = maxCoupon;

        emit AccessControllerSet(address(_accessController));
        emit BlacklistSet(address(_blacklist));
        emit MaxCouponSet(0, maxCoupon);
    }

    /**
     * @notice Mints a bond NFT to the specified address.
     * @dev Can only be called under specific conditions :
     *      - Caller must have MCAG_MINT_ROLE
     *      - Receiver must not be blacklisted
     *      - This contract must not be paused
     *      - Bond metadata must be valid
     * @param to Bond NFT receiver
     * @param bond Bond struct storing metadata
     */
    function issueBond(address to, Bond calldata bond)
        external
        onlyRole(Roles.MCAG_MINT_ROLE)
        notBlacklisted(to)
        whenNotPaused
    {
        if (bond.cusip == bytes16(0) && bond.isin == bytes16(0)) {
            revert Errors.EMPTY_CUSIP_AND_ISIN();
        }
        if (bond.currency == bytes4(0) || bond.issuer == bytes32(0) || bond.term == 0) {
            revert Errors.INVALID_RISK_CATEGORY();
        }
        if (bond.maturity < bond.issuance) {
            revert Errors.MATURITY_LESS_THAN_ISSUANCE(bond.maturity, bond.issuance);
        }
        if (keccak256(abi.encode(bond.currency, bond.issuer, bond.term)) != bond.riskCategory) {
            revert Errors.RISK_CATEGORY_MISMATCH(bond.currency, bond.issuer, bond.term, bond.riskCategory);
        }
        if (bytes(_tncUrls[bond.tncId]).length == 0) {
            revert Errors.TERMS_AND_CONDITIONS_URL_DOES_NOT_EXIST(bond.tncId);
        }
        if (bond.coupon < MIN_COUPON || bond.coupon > _maxCoupon) {
            revert Errors.INVALID_COUPON(bond.coupon, MIN_COUPON, _maxCoupon);
        }

        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _bonds[tokenId] = bond;
        _safeMint(to, tokenId);

        emit BondIssued(tokenId, bond);
    }

    /**
     * @notice Burns a bond NFT
     * @dev Can only be called under specific conditions :
     *      - Caller must have MCAG_BURN_ROLE and must be the owner of the bond.
     *      - This contract must not be paused
     * @param tokenId Id of the token to redeem
     */
    function redeem(uint256 tokenId) external onlyRole(Roles.MCAG_BURN_ROLE) whenNotPaused {
        if (_ownerOf(tokenId) != msg.sender) {
            revert Errors.ERC721_CALLER_IS_NOT_TOKEN_OWNER();
        }
        delete _bonds[tokenId];
        _burn(tokenId);
        emit BondRedeemed(tokenId);
    }

    /**
     * @notice Sets a new base uri for all KUMA Bonds NFTs of this contract
     * @dev Can only be called by `MCAG_SET_URI_ROLE`
     * @param newUri New base uri
     */
    function setUri(string memory newUri) external onlyRole(Roles.MCAG_SET_URI_ROLE) {
        emit UriSet(_uri, newUri);
        _uri = newUri;
    }

    /**
     * @notice Adds a new terms and conditions version
     * @dev Can only be called by `MCAG_SET_TERM_ROLE`
     * @param url URL link to the new terms and conditions
     */
    function addTnc(string memory url) external onlyRole(Roles.MCAG_SET_TNC_ROLE) {
        _tncCounter.increment();
        uint256 tncId = _tncCounter.current();
        _tncUrls[tncId] = url;
        emit TncAdded(tncId, url);
    }

    /**
     * @notice Updates a terms and conditions version
     * @dev Can only be called by `MCAG_SET_TERM_ROLE`
     * @param tncId Id of the terms and conditions to update
     * @param newUrl New URL link to the terms and conditions
     */
    function updateTncUrl(uint32 tncId, string memory newUrl) external onlyRole(Roles.MCAG_SET_TNC_ROLE) {
        if (bytes(_tncUrls[tncId]).length == 0) {
            revert Errors.TERMS_AND_CONDITIONS_URL_DOES_NOT_EXIST(tncId);
        }
        emit TncUrlUpdated(tncId, _tncUrls[tncId], newUrl);
        _tncUrls[tncId] = newUrl;
    }

    /**
     * @notice Updates the terms and conditions of a bond
     * @dev Can only be called by `MCAG_SET_TERM_ROLE`
     * @param tokenId Id of the bond to update
     * @param tncId Id of the new terms and conditions to link to the token
     */
    function updateTncForToken(uint256 tokenId, uint32 tncId) external onlyRole(Roles.MCAG_SET_TNC_ROLE) {
        if (_ownerOf(tokenId) == address(0)) {
            revert Errors.ERC721_INVALID_TOKEN_ID();
        }
        if (bytes(_tncUrls[tncId]).length == 0) {
            revert Errors.TERMS_AND_CONDITIONS_URL_DOES_NOT_EXIST(tncId);
        }
        emit TokenTncUpdated(tokenId, _bonds[tokenId].tncId, tncId);
        _bonds[tokenId].tncId = tncId;
    }

    /**
     * @notice Sets the max allowable coupon for newly issued bonds
     * @dev Can only be called by `MCAG_SET_MAX_COUPON_ROLE`
     * @param newMaxCoupon New max coupon, formatted as a per-second cumulative yield in RAY
     */
    function setMaxCoupon(uint256 newMaxCoupon) external onlyRole(Roles.MCAG_SET_MAX_COUPON_ROLE) {
        if (newMaxCoupon < MIN_COUPON) {
            revert Errors.INVALID_MAX_COUPON();
        }
        emit MaxCouponSet(_maxCoupon, newMaxCoupon);
        _maxCoupon = newMaxCoupon;
    }

    /**
     * @dev See {Pausable-_pause}.
     * @dev can only be called by `MCAG_PAUSE_ROLE`
     */
    function pause() external onlyRole(Roles.MCAG_PAUSE_ROLE) {
        _pause();
    }

    /**
     * @dev See {Pausable-_unpause}.
     * @dev can only be called by `MCAG_UNPAUSE_ROLE`
     */
    function unpause() external onlyRole(Roles.MCAG_UNPAUSE_ROLE) {
        _unpause();
    }

    /**
     * @return Current max allowable coupon of newly issued bonds, formatted as per-second cumulative yield in RAY
     */
    function getMaxCoupon() external view returns (uint256) {
        return _maxCoupon;
    }

    /**
     * @return Counter for terms and conditions
     */
    function getTncCounter() external view returns (uint256) {
        return _tncCounter.current();
    }

    /**
     * @return Number of KUMA Bonds NFTs issued
     */
    function getTokenIdCounter() external view returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @return Current base uri
     */
    function getBaseURI() external view returns (string memory) {
        return _uri;
    }

    /**
     * @param tokenId Bond id
     * @return Bond struct storing metadata of the given bond id
     */
    function getBond(uint256 tokenId) external view returns (Bond memory) {
        if (_ownerOf(tokenId) == address(0)) {
            revert Errors.ERC721_INVALID_TOKEN_ID();
        }
        return _bonds[tokenId];
    }

    /**
     * @param id Terms and conditions id
     * @return URL link to the terms and conditions of the given TNC id
     */
    function getTncUrl(uint256 id) external view returns (string memory) {
        return _tncUrls[id];
    }

    /**
     * @dev See {IERC721-approve}.
     * @dev Adds the following conditions to the call :
     *      - Caller, spender, and token owner must not be blacklisted
     *      - Contract must not be paused
     */
    function approve(address to, uint256 tokenId)
        public
        override(ERC721, IERC721)
        whenNotPaused
        notBlacklisted(to)
        notBlacklisted(msg.sender)
        notBlacklisted(ownerOf(tokenId))
    {
        address owner = ERC721.ownerOf(tokenId);

        if (to == owner) {
            revert Errors.ERC721_APPROVAL_TO_CURRENT_OWNER();
        }

        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
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
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-_beforeTokenTransfer}.
     * @dev Adds the following conditions to the call :
     *      - Caller, from and to must not be blacklisted
     *      - Contract must not be paused
     */
    function _beforeTokenTransfer(address from, address to, uint256, uint256)
        internal
        override
        whenNotPaused
        notBlacklisted(msg.sender)
        notBlacklisted(from)
        notBlacklisted(to)
    {}

    /**
     * @dev See {IERC721-_baseUri}.
     */
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }
}