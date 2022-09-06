// SPDX-FileCopyrightText: © Courtyard Inc. (https://courtyard.io)
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ITokenRegistryUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

/**
 * @author The Courtyard Team
 * @title {CourtyardRegistry} is a registry that holds ERC721 tokens and implements special actions around these tokens.
 * 
 *  1. Only contracts and accounts that were granted the {MINTER_ROLE} role can mint and drop new tokens.
 *     An arbitrary user/account typically needs to interact with a minter contract that can mint a token on their
 *     behalf.
 * 
 *  2. Only accounts and contracts that were granted the {BURNER_ROLE} role and own a token can burn that token.
 *     In the context of Connected Collectibles (a.k.a. Physically backed NFTs), a token can be burned as part of 
 *     a token redemption process.
 */
contract CourtyardRegistry is
Initializable,
UUPSUpgradeable,
ITokenRegistryUpgradeable,
AccessControlEnumerableUpgradeable,
ERC721EnumerableUpgradeable
{

    using StringsUpgradeable for uint256;

    string public tokenBaseUri;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev initializer for deployment when using the upgradeability pattern.
     */
    function initialize(address admin, string memory uri, string memory tokenName, string memory tokenSymbol) public initializer {
        ERC721Upgradeable.__ERC721_init(tokenName, tokenSymbol);
        AccessControlEnumerableUpgradeable._grantRole(DEFAULT_ADMIN_ROLE, admin);
        tokenBaseUri = uri;
    }

    /**
     * @dev See {UUPSUpgradeable-_authorizeUpgrade}.
     */
    function _authorizeUpgrade(address) internal virtual override onlyAdmin() {}

    /**
     * @dev Returns the implementation of this contract.
     */
    function implementation() external view returns (address) {
        return _getImplementation();
    }

    /**
     * @dev See {IERC165Upgradeable-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControlEnumerableUpgradeable, ERC721EnumerableUpgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(ITokenRegistryUpgradeable).interfaceId  || super.supportsInterface(interfaceId);
    }


    /* ================================================ VERSIONING ================================================ */

    function version() public pure returns (string memory) {
        return "2.0";
    }

    /* ================================================ ADMIN ROLE ================================================ */


    /**
     * @dev Modifier that checks that the sender has the {DEFAULT_ADMIN_ROLE} role. 
     */
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "CourtyardRegistry: Caller is missing role ADMIN.");
        _;
    }

    /**
     * @dev transfer the {DEFAULT_ADMIN_ROLE} role to another wallet.
     */
    function transferAdmin(address _to) public onlyAdmin() {
        super.grantRole(DEFAULT_ADMIN_ROLE, _to);
        super.revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }


    /* ================================================ MINTER ROLE ================================================ */

    /**
     * @dev the minter role. 
     */
    function MINTER_ROLE() private pure returns(bytes32) {
        return keccak256("MINTER_ROLE");
    } 

    /**
     * @dev Modifier that checks that the sender has the {MINTER_ROLE} role. 
     */
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE(), _msgSender()), "CourtyardRegistry: Caller is missing role MINTER_ROLE.");
        _;
    }

    /**
     * @dev grant the MINTER_ROLE role that allows to minting new tokens.
     */
    function grantMinterRole(address account) public onlyAdmin() {
        super.grantRole(MINTER_ROLE(), account);
    }

    /**
     * @dev revoke the MINTER_ROLE role.
     */
    function revokeMinterRole(address account) public onlyAdmin() {
        super.revokeRole(MINTER_ROLE(), account);
    }


    /* ================================================ BURNER ROLE ================================================ */

    /**
     * @dev the burner role. 
     */
    function BURNER_ROLE() private pure returns(bytes32) {
        return keccak256("BURNER_ROLE");
    } 

    /**
     * @dev Modifier that checks that the sender has the {BURNER_ROLE} role. 
     */
    modifier onlyBurner() {
        require(hasRole(BURNER_ROLE(), _msgSender()), "CourtyardRegistry: Caller is missing role BURNER_ROLE.");
        _;
    }

    /**
     * @dev grant the BURNER_ROLE role that allows to minting new tokens.
     */
    function grantBurnerRole(address account) public onlyAdmin() {
        super.grantRole(BURNER_ROLE(), account);
    }

    /**
     * @dev revoke the BURNER_ROLE role.
     */
    function revokeBurnerRole(address account) public onlyAdmin() {
        super.revokeRole(BURNER_ROLE(), account);
    }


    /**
     * ======================================== TOKEN ID & PROOF OF INTEGRITY ========================================
     * 
     * A token's Proof of Integrity is a 32 bytes hex value, which translates to a uint256 in a deterministic way.
     * This method saves about 27% in gas fees by using a direct translation {tokenId} <> {proofOfIntegrity}, rather
     * than storing the two attributes separately on chain.
     */

    /**
     * @dev Generates a Proof Of Integrity as the keccak256 hash of a human readable {fingerprint} and a {salt} value.
     */
    function generateProofOfIntegrity(string memory fingerprint, uint256 salt) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(fingerprint, salt));
    }

    /**
     * @dev {proofOfIntegrity} => {tokenId}.
     */
    function _proofOfIntegrityToTokenId(bytes32 proofOfIntegrity) private pure returns (uint256) {
        return uint256(proofOfIntegrity);
    }

    /**
     * @dev {tokenId} => {proofOfIntegrity}.
     */
    function _tokenIdToProofOfIntegrity(uint256 tokenId) private pure returns (bytes32) {
        return bytes32(tokenId);
    }

    /**
     * @dev {tokenId} => {proofOfIntegrity} as a hex string.
     */
    function _tokenIdToProofOfIntegrityAsHexString(uint256 tokenId) private pure returns (string memory) {
        return tokenId.toHexString(32);
    }

    /**
     * @dev get the Proof of Integrity of a particular token.
     * Requirement:
     *      - the token must exist.
     */
    function getTokenProofOfIntegrity(uint256 tokenId) public view returns (bytes32)  {
        require(_exists(tokenId), "CourtyardRegistry: Nonexistent token.");
        return _tokenIdToProofOfIntegrity(tokenId);
    }

    /**
     * @dev get the Proof of Integrity of a particular token as a string.
     * Requirement:
     *      - the token must exist.
     */
    function getTokenProofOfIntegrityAsHexString(uint256 tokenId) public view returns (string memory)  {
        require(_exists(tokenId), "CourtyardRegistry: Nonexistent token.");
        return _tokenIdToProofOfIntegrityAsHexString(tokenId);
    }


    /* ================================================ URI HELPERS ================================================ */

    /**
     * @dev Update {tokenBaseUri}
     */
    function updateTokenBaseUri(string memory newURI) public onlyAdmin() {
        tokenBaseUri = newURI;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "CourtyardRegistry: Nonexistent token.");
        return string(abi.encodePacked(tokenBaseUri, "/", _tokenIdToProofOfIntegrityAsHexString(tokenId), "/metadata.json"));
    }


    /* ================================ {ITokenRegistryUpgradeable} IMPLEMENTATION ================================ */

    /**
     *  @dev See {ITokenRegistryUpgradeable-mintToken}.
     */
    function mintToken(address to, bytes32 proofOfIntegrity) external override onlyMinter() returns (uint256) {
        uint256 tokenId = _proofOfIntegrityToTokenId(proofOfIntegrity);
        require(!_exists(tokenId), "CourtyardRegistry: Token already exists.");
        _safeMint(to, tokenId);
        return tokenId;
    }

    /**
     *  @dev See {ITokenRegistryUpgradeable-burnToken}.
     */
    function burnToken(bytes32 proofOfIntegrity) external override onlyBurner() returns (bool) {
        uint256 tokenId = _proofOfIntegrityToTokenId(proofOfIntegrity);
        require(ERC721Upgradeable.ownerOf(tokenId) == _msgSender(), "CourtyardRegistry: Caller does not own the token.");
        _burn(tokenId);
        return true;
    }

}