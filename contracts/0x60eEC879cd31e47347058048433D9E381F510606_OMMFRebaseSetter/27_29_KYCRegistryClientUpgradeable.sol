/**SPDX-License-Identifier: BUSL-1.1

      ▄▄█████████▄
   ╓██▀└ ,╓▄▄▄, '▀██▄
  ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,
 ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,
██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌
██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██
╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀
 ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`
  ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬
   ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀
      ╙▀▀██████R⌐

 */
pragma solidity 0.8.16;

import "contracts/kyc/IKYCRegistry.sol";
import "contracts/kyc/IKYCRegistryClient.sol";
import "contracts/external/openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * @title KYCRegistryClientInitializable
 * @author Ondo Finance
 * @notice This abstract contract manages state required for clients
 *         of the KYC registry.
 */
abstract contract KYCRegistryClientUpgradeable is
  Initializable,
  IKYCRegistryClient
{
  // KYC Registry address
  IKYCRegistry public override kycRegistry;
  // KYC requirement group
  uint256 public override kycRequirementGroup;

  /**
   * @notice Initialize the contract by setting registry variable
   *
   * @param _kycRegistry         Address of the registry contract
   * @param _kycRequirementGroup KYC requirement group associated with this
   *                             client
   *
   * @dev Function should be called by the inheriting contract on
   *      initialization
   */
  function __KYCRegistryClientInitializable_init(
    address _kycRegistry,
    uint256 _kycRequirementGroup
  ) internal onlyInitializing {
    __KYCRegistryClientInitializable_init_unchained(
      _kycRegistry,
      _kycRequirementGroup
    );
  }

  /**
   * @dev Internal function to future-proof parent linearization. Matches OZ
   *      upgradeable suggestions
   */
  function __KYCRegistryClientInitializable_init_unchained(
    address _kycRegistry,
    uint256 _kycRequirementGroup
  ) internal onlyInitializing {
    _setKYCRegistry(_kycRegistry);
    _setKYCRequirementGroup(_kycRequirementGroup);
  }

  /**
   * @notice Sets the KYC registry address for this client
   *
   * @param _kycRegistry The new KYC registry address
   */
  function _setKYCRegistry(address _kycRegistry) internal {
    if (_kycRegistry == address(0)) {
      revert RegistryZeroAddress();
    }
    address oldKYCRegistry = address(kycRegistry);
    kycRegistry = IKYCRegistry(_kycRegistry);
    emit KYCRegistrySet(oldKYCRegistry, _kycRegistry);
  }

  /**
   * @notice Sets the KYC registry requirement group for this
   *         client to check kyc status for
   *
   * @param _kycRequirementGroup The new KYC group
   */
  function _setKYCRequirementGroup(uint256 _kycRequirementGroup) internal {
    uint256 oldKYCLevel = kycRequirementGroup;
    kycRequirementGroup = _kycRequirementGroup;
    emit KYCRequirementGroupSet(oldKYCLevel, _kycRequirementGroup);
  }

  /**
   * @notice Checks whether an address has been KYC'd
   *
   * @param account The address to check
   */
  function _getKYCStatus(address account) internal view returns (bool) {
    return kycRegistry.getKYCStatus(kycRequirementGroup, account);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}