// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "../utils/ContractKeys.sol";
import "../interfaces/INftfiHub.sol";

/**
 * @title SmartNft
 * @author NFTfi
 * @dev An ERC721 token which represents a very basic implementation of the NFTfi V2 SmartNFT.
 */
contract SmartNft is ERC721, AccessControl {
    using Address for address;
    using Strings for uint256;

    /**
     * @dev This struct contains data needed to find the loan linked to a SmartNft.
     */
    struct Loan {
        address loanCoordinator;
        uint256 loanId;
    }

    /* ******* */
    /* STORAGE */
    /* ******* */

    bytes32 public constant LOAN_COORDINATOR_ROLE = keccak256("LOAN_COORDINATOR_ROLE");
    bytes32 public constant BASE_URI_ROLE = keccak256("BASE_URI_ROLE");

    INftfiHub public immutable hub;

    // smartNftId => Loan
    mapping(uint256 => Loan) public loans;

    string public baseURI;

    /**
     * @dev Grants the contract the default admin role to `_admin`.
     * Grants LOAN_COORDINATOR_ROLE to `_loanCoordinator`.
     *
     * @param _admin - Account to set as the admin of roles
     * @param _nftfiHub - Address of the NftfiHub contract
     * @param _loanCoordinator - Initial loan coordinator
     * @param _name - Name for the SmarNFT
     * @param _symbol - Symbol for the SmarNFT
     * @param _customBaseURI - Base URI for the SmarNFT
     */
    constructor(
        address _admin,
        address _nftfiHub,
        address _loanCoordinator,
        string memory _name,
        string memory _symbol,
        string memory _customBaseURI
    ) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(BASE_URI_ROLE, _admin);
        _setupRole(LOAN_COORDINATOR_ROLE, _loanCoordinator);
        _setBaseURI(_customBaseURI);
        hub = INftfiHub(_nftfiHub);
    }

    /**
     * @dev Grants LOAN_COORDINATOR_ROLE to `_account`.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function setLoanCoordinator(address _account) external {
        grantRole(LOAN_COORDINATOR_ROLE, _account);
    }

    /**
     * @dev Mints a new token with `_tokenId` and assigne to `_to`.
     *
     * Requirements:
     *
     * - the caller must have `LOAN_COORDINATOR_ROLE` role.
     *
     * @param _to The address reciving the SmartNft
     * @param _tokenId The id of the new SmartNft
     * @param _data Up to the first 32 bytes contains an integer which represents the loanId linked to the SmartNft
     */
    function mint(
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external onlyRole(LOAN_COORDINATOR_ROLE) {
        require(_data.length > 0, "data must contain loanId");
        uint256 loanId = abi.decode(_data, (uint256));
        loans[_tokenId] = Loan({loanCoordinator: msg.sender, loanId: loanId});
        _safeMint(_to, _tokenId, _data);
    }

    /**
     * @dev Burns `_tokenId` token.
     *
     * Requirements:
     *
     * - the caller must have `LOAN_COORDINATOR_ROLE` role.
     */
    function burn(uint256 _tokenId) external onlyRole(LOAN_COORDINATOR_ROLE) {
        delete loans[_tokenId];
        _burn(_tokenId);
    }

    /**
     * @dev Sets baseURI.
     * @param _customBaseURI - Base URI for the SmarNFT
     */
    function setBaseURI(string memory _customBaseURI) external onlyRole(BASE_URI_ROLE) {
        _setBaseURI(_customBaseURI);
    }

    function exists(uint256 _tokenId) external view returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    /**
     * @dev Sets baseURI.
     */
    function _setBaseURI(string memory _customBaseURI) internal virtual {
        baseURI = bytes(_customBaseURI).length > 0
            ? string(abi.encodePacked(_customBaseURI, _getChainID().toString(), "/"))
            : "";
    }

    /** @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev This function gets the current chain ID.
     */
    function _getChainID() internal view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }
}