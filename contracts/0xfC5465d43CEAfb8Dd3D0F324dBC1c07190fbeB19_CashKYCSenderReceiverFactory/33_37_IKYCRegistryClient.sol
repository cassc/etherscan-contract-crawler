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

import "contracts/interfaces/IKYCRegistry.sol";

/**
 * @title IKYCRegistryClient
 * @author Ondo Finance
 * @notice The client interface Ondo's KYC Registry contract.
 */
interface IKYCRegistryClient {
  /// @notice Returns what KYC group this client checks accounts for
  function kycRequirementGroup() external view returns (uint256);

  /// @notice Returns reference to the KYC registry that this client queries
  function kycRegistry() external view returns (IKYCRegistry);

  /// @notice Sets the KYC group
  function setKYCRequirementGroup(uint256 group) external;

  /// @notice Sets the KYC registry reference
  function setKYCRegistry(address registry) external;

  /// @notice Error for when caller attempts to set the KYC registry refernce
  ///         to the zero address.
  error RegistryZeroAddress();

  /**
   * @dev Event for when the KYC registry reference is set
   *
   * @param oldRegistry The old registry
   * @param newRegistry The new registry
   */
  event KYCRegistrySet(address oldRegistry, address newRegistry);

  /**
   * @dev Event for when the KYC group for this client is set
   *
   * @param oldRequirementGroup The old KYC group
   * @param newRequirementGroup The new KYC group
   */
  event KYCRequirementGroupSet(
    uint256 oldRequirementGroup,
    uint256 newRequirementGroup
  );
}