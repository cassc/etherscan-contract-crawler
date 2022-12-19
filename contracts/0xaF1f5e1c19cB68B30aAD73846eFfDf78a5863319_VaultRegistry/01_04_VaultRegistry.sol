// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

import "Ownable.sol";
import "IVault.sol";

interface IReleaseRegistry {
    function numReleases() external view returns (uint256);

    function releases(uint256 _version) external view returns (address);

    function newVault(
        address _token,
        address _governance,
        address _guardian,
        address _rewards,
        string calldata _name,
        string calldata _symbol,
        uint256 _releaseDelta
    ) external returns (address);
}

contract VaultRegistry is Ownable {
    /* ========== STATE VARIABLES ========== */

    /// @notice Default vault type for this registry. Emitted on vault creation.
    uint256 public constant DEFAULT_VAULT_TYPE = 1;

    /// @notice Address of our pre-factory registry. Used to fetch older vaults.
    /// @dev Vaults read from the legacy registry are, by default, type 0.
    address public immutable LEGACY_REGISTRY;

    /// @notice Address of our release registry. Used to pull most recent vault release.
    address public releaseRegistry;

    /// @notice If one or more vault(s) exist for a token, they will be shown here.
    /// @dev Only vaults deployed from this registry will be shown.
    mapping(address => address[]) public vaults;

    /// @notice Tokens that this registry has deployed vaults for.
    address[] public tokens;

    /// @notice Check if an endorsed vault exists for a given underlying token.
    mapping(address => bool) public isRegistered;

    /// @notice Check the type of a given vault address.
    /// @dev Vault must have been endorsed by this registry.
    mapping(address => uint256) public vaultType;

    /// @notice Check if an address is allowed to own vaults from this registry.
    mapping(address => bool) public approvedVaultsOwner;

    /// @notice Check if a given vault was endorsed by this registry.
    mapping(address => bool) public isVaultEndorsed;

    /// @notice Check if an address can endorse vaults via this registry.
    mapping(address => bool) public vaultEndorsers;

    /* ========== EVENTS AND ERRORS ========== */

    event NewVault(
        address indexed token,
        uint256 indexed vaultId,
        uint256 vaultType,
        address vault,
        string apiVersion
    );

    event ApprovedVaultOwnerUpdated(address governance, bool approved);
    event ApprovedVaultEndorser(address account, bool canEndorse);
    event ReleaseRegistryUpdated(address newRegistry);

    error GovernanceMismatch(address vault);
    error NotAllowedToEndorse();
    error VersionMissmatch(string v1, string v2);
    error EndorseVaultWithSameVersion(address existingVault, address newVault);
    error VaultAlreadyEndorsed(address vault, uint256 vaultType);
    error InvalidVaultType();

    /* ========== CONSTRUCTOR ========== */

    constructor(address _releaseRegistry, address _legacyRegistry) {
        releaseRegistry = _releaseRegistry;
        LEGACY_REGISTRY = _legacyRegistry;
        emit ReleaseRegistryUpdated(_releaseRegistry);
    }

    /* ========== VIEWS ========== */

    /// @notice The number of tokens with vaults deployed by this registry.
    function numTokens() external view returns (uint256) {
        return tokens.length;
    }

    /// @notice The number of vaults deployed for a token by this registry.
    function numVaults(address _token) external view returns (uint256) {
        return _numVaults(_token);
    }

    function _numVaults(address _token) internal view returns (uint256) {
        return vaults[_token].length;
    }

    /**
     @notice Returns the latest deployed vault for the given token.
     @dev Return zero if no vault is associated with the token. Also
      checks our legacy registry as well.
     @param _token The token address to find the latest vault for.
     @return The address of the latest vault for the given token.
     */
    function latestVault(address _token) external view returns (address) {
        return _latestVault(_token);
    }

    /**
     @notice Returns the latest deployed vault for the given token and type.
     @dev Return zero if no vault exists for both token and type.
     @dev Currently defined types are 0: legacy, 1: default, 2: automated. More may be added later.
     @param _token The token address to find the latest vault for.
     @param _type The vault type to find the latest vault for.
     @return The address of the latest vault found matching both token and type.
     */
    function latestVaultOfType(
        address _token,
        uint256 _type
    ) external view returns (address) {
        return _latestVaultOfType(_token, _type);
    }

    // get the latest vault for a token, from this registry or our legacy registry.
    function _latestVault(address _token) internal view returns (address) {
        uint256 length = _numVaults(_token);
        if (length == 0) {
            return _fetchFromLegacy(_token);
        }
        return vaults[_token][length - 1];
    }

    // get the latest vault for a token and type. legacy is type 0.
    function _latestVaultOfType(
        address _token,
        uint256 _type
    ) internal view returns (address) {
        // type 0 are legacy, not from this registry
        if (_type == 0) {
            return _fetchFromLegacy(_token);
        }

        uint256 length = _numVaults(_token);
        if (length == 0) {
            return address(0);
        }

        uint256 i = length - 1;
        while (true) {
            address vault = vaults[_token][i];
            if (vaultType[vault] == _type) {
                return vault;
            }
            if (i == 0) {
                break;
            }
            unchecked {
                i--;
            }
        }
        return address(0);
    }

    // check our legacy registry for vaults for a given token
    function _fetchFromLegacy(address _token) internal view returns (address) {
        bytes memory data = abi.encodeWithSignature(
            "latestVault(address)",
            _token
        );
        (bool success, bytes memory returnBytes) = address(LEGACY_REGISTRY)
            .staticcall(data);
        if (success) {
            return abi.decode(returnBytes, (address));
        }
        return address(0);
    }

    /* ========== CORE FUNCTIONS ========== */

    /**
    @notice
        Create a new vault for the given token using the latest release in the registry,
        as a simple "forwarder-style" delegatecall proxy to the latest release.
    @dev
        governance is set in the new vault as governance, with no ability to override.
        Throws if caller isn't governance.
        Throws if no releases are registered yet.
        Throws if there already is a registered vault for the given token with the latest api version.
        Emits a NewVault event.
    @param _token The token that may be deposited into the new Vault.
    @param _guardian The address authorized for guardian interactions in the new Vault.
    @param _rewards The address to use for collecting rewards in the new Vault
    @param _name Specify a custom Vault name. Set to empty string for default choice.
    @param _symbol Specify a custom Vault symbol name. Set to empty string for default choice.
    @param _releaseDelta Specify the number of releases prior to the latest to use as a target. Default is latest.
    @param _type Vault type. Basic defined types are 1: default, 2: automated, but more can be added.
    @return The address of the newly-deployed vault
     */
    function newVault(
        address _token,
        address _governance,
        address _guardian,
        address _rewards,
        string calldata _name,
        string calldata _symbol,
        uint256 _releaseDelta,
        uint256 _type
    ) public returns (address) {
        require(vaultEndorsers[msg.sender], "unauthorized");
        require(approvedVaultsOwner[_governance], "not allowed vault owner");
        address vault = IReleaseRegistry(releaseRegistry).newVault(
            _token,
            _governance,
            _guardian,
            _rewards,
            _name,
            _symbol,
            _releaseDelta
        );
        _registerVault(_token, vault, _type);
        return vault;
    }

    /**
     @notice
         Adds an existing vault to the list of "endorsed" vaults for that token.
     @dev
         Throws if caller isn't an approved endorser.
         Throws if `_vault` governance isn't an approved vault owner.
         Throws if no releases are registered yet.
         Throws if `_vault` api version does not match latest release.
         Throws if there already is a deployment for the vault's token with the latest api version.
         Emits a NewVault event.
     @param _vault The vault that will be endorsed by this registry.
     @param _releaseDelta Specify the number of releases prior to the latest to use as a target. Default is latest.
     @param _type Vault type
    */
    function endorseVault(
        address _vault,
        uint256 _releaseDelta,
        uint256 _type
    ) public {
        if (vaultEndorsers[msg.sender] == false) {
            revert NotAllowedToEndorse();
        }

        if (approvedVaultsOwner[IVault(_vault).governance()] == false) {
            revert GovernanceMismatch(_vault);
        }

        // NOTE: Underflow if no releases created yet, or targeting prior to release history
        uint256 releaseTarget = IReleaseRegistry(releaseRegistry)
            .numReleases() -
            1 -
            _releaseDelta; // dev: no releases
        string memory apiVersion = IVault(
            IReleaseRegistry(releaseRegistry).releases(releaseTarget)
        ).apiVersion();
        if (
            keccak256(bytes((IVault(_vault).apiVersion()))) !=
            keccak256(bytes((apiVersion)))
        ) {
            revert VersionMissmatch(IVault(_vault).apiVersion(), apiVersion);
        }
        // Add to the end of the list of vaults for token
        _registerVault(IVault(_vault).token(), _vault, _type);
    }

    /**
    @notice Endorse a vault of the default vault type.
    @dev See main endorseVault() function for more details.
    @param _vault The vault that will be endorsed by this registry.
    @param _releaseDelta Specify the number of releases prior to the latest to use as a target. Default is latest.
     */
    function endorseVault(address _vault, uint256 _releaseDelta) external {
        endorseVault(_vault, _releaseDelta, DEFAULT_VAULT_TYPE);
    }

    /**
    @notice Endorse a vault of the default vault type and the current release.
    @dev See main endorseVault() function for more details.
    @param _vault The vault that will be endorsed by this registry.
     */
    function endorseVault(address _vault) external {
        endorseVault(_vault, 0, DEFAULT_VAULT_TYPE);
    }

    /**
    @notice Deploy a new vault with the default vault type.
    @dev See other newVault() function for more details.
     */
    function newVault(
        address _token,
        address _guardian,
        address _rewards,
        string calldata _name,
        string calldata _symbol,
        uint256 _releaseDelta
    ) external returns (address) {
        return
            newVault(
                _token,
                msg.sender,
                _guardian,
                _rewards,
                _name,
                _symbol,
                _releaseDelta,
                DEFAULT_VAULT_TYPE
            );
    }

    function _registerVault(
        address _token,
        address _vault,
        uint256 _type
    ) internal {
        // Check if there is an existing deployment for this token + type combination at the particular api version
        // NOTE: This doesn't check for strict semver-style linearly increasing release versions
        if (vaultType[_vault] != 0) {
            revert VaultAlreadyEndorsed(_vault, vaultType[_vault]);
        }

        if (_type == 0) {
            revert InvalidVaultType();
        }

        address latest = _latestVaultOfType(_token, _type);
        if (latest != address(0)) {
            if (
                keccak256(bytes(IVault(latest).apiVersion())) ==
                keccak256(bytes(IVault(_vault).apiVersion()))
            ) {
                revert EndorseVaultWithSameVersion(latest, _vault);
            }
        }
        uint256 id = _numVaults(_token);
        // Update the latest deployment
        vaults[_token].push(_vault);
        vaultType[_vault] = _type;

        // Register tokens for endorsed vaults
        if (isRegistered[_token] == false) {
            isRegistered[_token] = true;
            tokens.push(_token);
        }
        isVaultEndorsed[_vault] = true;
        emit NewVault(_token, id, _type, _vault, IVault(_vault).apiVersion());
    }

    /* ========== SETTERS ========== */

    /**
    @notice Set the ability of a particular tagger to tag current vaults.
    @dev Throws if caller is not owner.
    @param _addr The address to approve or deny access.
    @param _approved Allowed to endorse
     */
    function setVaultEndorsers(
        address _addr,
        bool _approved
    ) external onlyOwner {
        vaultEndorsers[_addr] = _approved;
        emit ApprovedVaultEndorser(_addr, _approved);
    }

    /**
    @notice Set the vaults owners
    @dev Throws if caller is not owner.
    @param _addr The address to approve or deny access.
    @param _approved Allowed to own vault
     */
    function setApprovedVaultsOwner(
        address _addr,
        bool _approved
    ) external onlyOwner {
        approvedVaultsOwner[_addr] = _approved;
        emit ApprovedVaultOwnerUpdated(_addr, _approved);
    }

    /**
    @notice Update the address of our release registry.
    @dev Contains information about latest and past vault releases. 
     Throws if caller is not owner.
    @param _newRegistry Address of our new release registry.
     */
    function updateReleaseRegistry(address _newRegistry) external onlyOwner {
        releaseRegistry = _newRegistry;
        emit ReleaseRegistryUpdated(_newRegistry);
    }
}