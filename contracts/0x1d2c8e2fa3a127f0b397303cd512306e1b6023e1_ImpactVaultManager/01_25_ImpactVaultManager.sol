// SPDX-License-Identifier: Apache-2.0
// https://docs.soliditylang.org/en/v0.8.10/style-guide.html
pragma solidity 0.8.11;

import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {ImpactVault} from "src/vaults/ImpactVault.sol";
import {ERC20PresetMinterPauserUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/presets/ERC20PresetMinterPauserUpgradeable.sol";

/**
 * @title ImpactVaultManager
 * @author douglasqian
 * @notice This contract implements a new token vault standard inspired by
 *   ERC-4626. Key difference is that ImpactVault ERC20 tokens do not
 *   entitle depositors to a portion of the yield earned on the vault.
 *   Instead, shares of yield is tracked to mint a proportional amount of
 *   governance tokens to determine how the vault's yield will be deployed.
 *
 *   Note: this vault should always be initialized with an ERC20 token
 *   (ex: CELO) and a non-rebasing yield token (ex: stCELO).
 */
contract ImpactVaultManager is
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    event Receive(address indexed sender, uint256 indexed amount);
    event ImpactVaultRegistered(address indexed vault);
    event ImpactVaultDeregistered(address indexed vault);
    event V0VaultRegistered(address indexed vault);
    event V0VaultDeregistered(address indexed vault);

    event DependenciesUpdated(
        address indexed manager,
        address indexed registry
    );

    // New vaults that implement the ImpactVault interface.
    address[] public impactVaults;

    ERC20PresetMinterPauserUpgradeable c_SPRL;

    // Original Spirals staking contracts. Not backward compatible with
    // ImpactVault interface so stored separately.
    address[] public v0Vaults;

    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }

    function initialize(address _sprlTokenAddress) external initializer {
        __Ownable_init();
        __Pausable_init();
        __ReentrancyGuard_init();
        // Ensures that `_owner` is set
        setDependencies(_sprlTokenAddress);
    }

    function setDependencies(address _sprlTokenAddress) public onlyOwner {
        c_SPRL = ERC20PresetMinterPauserUpgradeable(_sprlTokenAddress);
    }

    /**
     * @notice Add a new ImpactVault
     */
    function registerVault(address _vaultToAdd)
        external
        onlyOwner
        whenNotPaused
        onlyNotRegisteredVault(impactVaults, _vaultToAdd)
    {
        impactVaults.push(_vaultToAdd);
        emit ImpactVaultRegistered(_vaultToAdd);
    }

    /**
     * @notice Remove a registered ImpactVault
     */
    function deregisterVault(address _vaultToRemove)
        external
        onlyOwner
        whenNotPaused
        onlyRegisteredVault(impactVaults, _vaultToRemove)
    {
        for (uint256 i = 0; i < impactVaults.length; i++) {
            if (impactVaults[i] == _vaultToRemove) {
                impactVaults[i] = impactVaults[impactVaults.length - 1];
                // slither-disable-next-line costly-operations-inside-a-loop (break statement)
                impactVaults.pop();
                break;
            }
        }
        emit ImpactVaultDeregistered(_vaultToRemove);
    }

    modifier onlyRegisteredVault(address[] memory _vaults, address _vault) {
        require(isRegisteredVault(_vaults, _vault), "VAULT_NOT_REGISTERED");
        _;
    }

    modifier onlyNotRegisteredVault(address[] memory _vaults, address _vault) {
        require(
            !isRegisteredVault(_vaults, _vault),
            "VAULT_ALREADY_REGISTERED"
        );
        _;
    }

    function isImpactVault(address _vault) public view returns (bool) {
        return isRegisteredVault(impactVaults, _vault);
    }

    function isRegisteredVault(address[] memory _vaults, address _vault)
        internal
        pure
        returns (bool isRegistered)
    {
        for (uint256 i = 0; i < _vaults.length; i++) {
            if (_vaults[i] == _vault) {
                isRegistered = true;
                break;
            }
        }
        return isRegistered;
    }

    /**
     * @notice Claims SPRL governance tokens for a given address in proportion
     * to the yield associated with that address across all registered vaults.
     *
     * Withdraws underlying yield assets from vault into this contract.
     */
    function claimGovernanceTokens() external whenNotPaused nonReentrant {
        uint256 totalYieldUSD;
        for (uint256 i = 0; i < impactVaults.length; i++) {
            totalYieldUSD += ImpactVault(impactVaults[i])
                .transferYieldToManager(_msgSender());
        }
        c_SPRL.mint(_msgSender(), totalYieldUSD);
    }

    /**
     * @dev Returns the total yield in USD associated with a given address
     * across all impact vaults.
     */
    function getTotalYieldUSD(address _address)
        public
        view
        returns (uint256 totalYieldUSD)
    {
        for (uint256 i = 0; i < impactVaults.length; i++) {
            uint256 y = ImpactVault(impactVaults[i]).getYieldUSD(_address);
            totalYieldUSD += y;
        }
        return totalYieldUSD;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}