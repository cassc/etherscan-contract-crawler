// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./libraries/Errors.sol";
import "./interfaces/ISoulboundIdentity.sol";
import "./interfaces/ISoulName.sol";
import "./tokens/MasaSBTAuthority.sol";

/// @title Soulbound Identity
/// @author Masa Finance
/// @notice Soulbound token that represents an identity.
/// @dev Soulbound identity, that inherits from the SBT contract.
contract SoulboundIdentity is
    MasaSBTAuthority,
    ISoulboundIdentity,
    ReentrancyGuard
{
    /* ========== STATE VARIABLES =========================================== */

    ISoulName public soulName;

    /* ========== INITIALIZE ================================================ */

    /// @notice Creates a new soulbound identity
    /// @dev Creates a new soulbound identity, inheriting from the SBT contract.
    /// @param admin Administrator of the smart contract
    /// @param baseTokenURI Base URI of the token
    constructor(address admin, string memory baseTokenURI)
        MasaSBTAuthority(admin, "Masa Identity", "MID", baseTokenURI)
    {}

    /* ========== RESTRICTED FUNCTIONS ====================================== */

    /// @notice Sets the SoulName contract address linked to this identity
    /// @dev The caller must have the admin role to call this function
    /// @param _soulName Address of the SoulName contract
    function setSoulName(ISoulName _soulName)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (address(_soulName) == address(0)) revert ZeroAddress();
        if (soulName == _soulName) revert SameValue();
        soulName = _soulName;
    }

    /* ========== MUTATIVE FUNCTIONS ======================================== */

    /// @notice Mints a new soulbound identity
    /// @dev The caller can only mint one identity per address
    /// @param to Address of the admin of the new identity
    function mint(address to) public override returns (uint256) {
        // Soulbound identity already created!
        if (balanceOf(to) > 0) revert IdentityAlreadyCreated(to);

        return _mintWithCounter(to);
    }

    /// @notice Mints a new soulbound identity with a SoulName associated to it
    /// @dev The caller can only mint one identity per address, and the name must be unique
    /// @param to Address of the admin of the new identity
    /// @param name Name of the new identity
    /// @param yearsPeriod Years of validity of the name
    /// @param _tokenURI URI of the NFT
    function mintIdentityWithName(
        address to,
        string memory name,
        uint256 yearsPeriod,
        string memory _tokenURI
    ) external override soulNameAlreadySet nonReentrant returns (uint256) {
        uint256 identityId = mint(to);
        soulName.mint(to, name, yearsPeriod, _tokenURI);

        return identityId;
    }

    /* ========== VIEWS ===================================================== */

    /// @notice Returns the address of the SoulName contract linked to this identity
    /// @dev This function returns the address of the SoulName contract linked to this identity
    /// @return Address of the SoulName contract
    function getSoulName() external view override returns (ISoulName) {
        return soulName;
    }

    /// @notice Returns the extension of the soul name
    /// @dev This function returns the extension of the soul name
    /// @return Extension of the soul name
    function getExtension() external view returns (string memory) {
        return soulName.getExtension();
    }

    /// @notice Returns the owner address of an identity
    /// @dev This function returns the owner address of the identity specified by the tokenId
    /// @param tokenId TokenId of the identity
    /// @return Address of the owner of the identity
    function ownerOf(uint256 tokenId)
        public
        view
        override(SBT, ISBT)
        returns (address)
    {
        return super.ownerOf(tokenId);
    }

    /// @notice Returns the owner address of a soul name
    /// @dev This function returns the owner address of the soul name identity specified by the name
    /// @param name Name of the soul name
    /// @return Address of the owner of the identity
    function ownerOf(string memory name)
        external
        view
        soulNameAlreadySet
        returns (address)
    {
        (, , uint256 identityId, , , ) = soulName.getTokenData(name);
        return super.ownerOf(identityId);
    }

    /// @notice Returns the URI of a soul name
    /// @dev This function returns the token URI of the soul name identity specified by the name
    /// @param name Name of the soul name
    /// @return URI of the identity associated to a soul name
    function tokenURI(string memory name)
        external
        view
        soulNameAlreadySet
        returns (string memory)
    {
        (, , uint256 identityId, , , ) = soulName.getTokenData(name);
        return super.tokenURI(identityId);
    }

    /// @notice Returns the URI of the owner of an identity
    /// @dev This function returns the token URI of the identity owned by an account
    /// @param owner Address of the owner of the identity
    /// @return URI of the identity owned by the account
    function tokenURI(address owner) external view returns (string memory) {
        uint256 tokenId = tokenOfOwner(owner);
        return super.tokenURI(tokenId);
    }

    /// @notice Returns the identity id of an account
    /// @dev This function returns the tokenId of the identity owned by an account
    /// @param owner Address of the owner of the identity
    /// @return TokenId of the identity owned by the account
    function tokenOfOwner(address owner)
        public
        view
        override
        returns (uint256)
    {
        return super.tokenOfOwnerByIndex(owner, 0);
    }

    /// @notice Checks if a soul name is available
    /// @dev This function queries if a soul name already exists and is in the available state
    /// @param name Name of the soul name
    /// @return available `true` if the soul name is available, `false` otherwise
    function isAvailable(string memory name)
        external
        view
        soulNameAlreadySet
        returns (bool available)
    {
        return soulName.isAvailable(name);
    }

    /// @notice Returns the information of a soul name
    /// @dev This function queries the information of a soul name
    /// @param name Name of the soul name
    /// @return sbtName Soul name, in upper/lower case and extension
    /// @return linked `true` if the soul name is linked, `false` otherwise
    /// @return identityId Identity id of the soul name
    /// @return tokenId SoulName id of the soul name
    /// @return expirationDate Expiration date of the soul name
    /// @return active `true` if the soul name is active, `false` otherwise
    function getTokenData(string memory name)
        external
        view
        soulNameAlreadySet
        returns (
            string memory sbtName,
            bool linked,
            uint256 identityId,
            uint256 tokenId,
            uint256 expirationDate,
            bool active
        )
    {
        return soulName.getTokenData(name);
    }

    /// @notice Returns all the active soul names of an account
    /// @dev This function queries all the identity names of the specified account
    /// @param owner Address of the owner of the identities
    /// @return sbtNames Array of soul names associated to the account
    function getSoulNames(address owner)
        external
        view
        soulNameAlreadySet
        returns (string[] memory sbtNames)
    {
        return soulName.getSoulNames(owner);
    }

    // SoulName -> SoulboundIdentity.tokenId
    // SoulName -> account -> SoulboundIdentity.tokenId

    /// @notice Returns all the active soul names of an account
    /// @dev This function queries all the identity names of the specified identity Id
    /// @param tokenId TokenId of the identity
    /// @return sbtNames Array of soul names associated to the identity Id
    function getSoulNames(uint256 tokenId)
        external
        view
        soulNameAlreadySet
        returns (string[] memory sbtNames)
    {
        return soulName.getSoulNames(tokenId);
    }

    /* ========== PRIVATE FUNCTIONS ========================================= */

    /* ========== MODIFIERS ================================================= */

    modifier soulNameAlreadySet() {
        if (address(soulName) == address(0)) revert SoulNameContractNotSet();
        _;
    }

    /* ========== EVENTS ==================================================== */
}