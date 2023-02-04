// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import {Address} from "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import {Counters} from "lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import {ERC721} from "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Errors} from "./libraries/Errors.sol";
import {IAccessControl} from "lib/openzeppelin-contracts/contracts/access/IAccessControl.sol";
import {IKYCToken, IERC721} from "./interfaces/IKYCToken.sol";
import {Roles} from "./libraries/Roles.sol";

contract KYCToken is ERC721, IKYCToken {
    using Address for address;
    using Counters for Counters.Counter;

    IAccessControl public immutable accessController;

    Counters.Counter private _tokenIdCounter;
    string private _uri;

    // Mapping token ID to KYCData
    mapping(uint256 => KYCData) private _kycData;

    modifier onlyRole(bytes32 role) {
        if (!accessController.hasRole(role, msg.sender)) {
            revert Errors.ACCESS_CONTROL_ACCOUNT_IS_MISSING_ROLE(msg.sender, role);
        }
        _;
    }

    /**
     * @param _accessController MCAGAccessController.
     */
    constructor(IAccessControl _accessController) ERC721("MCAG KYC Token", "MKYCT") {
        if (address(_accessController) == address(0)) {
            revert Errors.CANNOT_SET_TO_ADDRESS_ZERO();
        }
        accessController = _accessController;
    }

    /**
     * @notice Mints a KYC NFT to the specified address.
     * @dev Can only be called by MCAG_MINT_ROLE
     * @param to KYC NFT receiver.
     * @param kycData KYCData struct storing metadata.
     */
    function mint(address to, KYCData calldata kycData) external override onlyRole(Roles.MCAG_MINT_ROLE) {
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current();
        _kycData[tokenId] = kycData;
        _safeMint(to, tokenId);

        emit Mint(to, kycData);
    }

    /**
     * @notice Mints a KYC NFT to the specified address.
     * @dev Can only be called by MCAG_BURN_ROLE
     * @param tokenId Token Id to burn.
     */
    function burn(uint256 tokenId) external override onlyRole(Roles.MCAG_BURN_ROLE) {
        if (_ownerOf(tokenId) == address(0)) {
            revert Errors.ERC721_INVALID_TOKEN_ID();
        }
        KYCData memory kycData = _kycData[tokenId];
        delete _kycData[tokenId];
        _burn(tokenId);

        emit Burn(tokenId, kycData);
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
     * @return Current token id counter.
     */
    function getTokenIdCounter() external view override returns (uint256) {
        return _tokenIdCounter.current();
    }

    /**
     * @param tokenId KYC token id.
     * @return KYCData struct storing metadata of the selected token id.
     */
    function getKycData(uint256 tokenId) external view override returns (KYCData memory) {
        if (_ownerOf(tokenId) == address(0)) {
            revert Errors.ERC721_INVALID_TOKEN_ID();
        }
        return _kycData[tokenId];
    }

    /**
     * @dev Token is non transferable.
     */
    function approve(address to, uint256 tokenId) public pure override(ERC721, IERC721) {
        revert Errors.TOKEN_IS_NOT_TRANSFERABLE();
    }

    /**
     * @dev Token is non transferable.
     */
    function setApprovalForAll(address operator, bool approved) public pure override(ERC721, IERC721) {
        revert Errors.TOKEN_IS_NOT_TRANSFERABLE();
    }

    /**
     * @dev Token is non transferable.
     */
    function transferFrom(address from, address to, uint256 tokenId) public pure override(ERC721, IERC721) {
        revert Errors.TOKEN_IS_NOT_TRANSFERABLE();
    }

    /**
     * @dev Token is non transferable.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        pure
        override(ERC721, IERC721)
    {
        revert Errors.TOKEN_IS_NOT_TRANSFERABLE();
    }

    /**
     * @dev See {IERC721-_baseUri}.
     */
    function _baseURI() internal view override returns (string memory) {
        return _uri;
    }
}