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

import "contracts/cash/kyc/KYCRegistryClient.sol";
import "contracts/cash/external/openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * @title KYCRegistryClientInitializable
 * @author Ondo Finance
 * @notice This abstract contract allows Inheritors to access the KYC list
 *         maintained by the registry.
 *
 * @dev The contract is designed to be inherited by upgradeable contracts.
 */
abstract contract KYCRegistryClientInitializable is
  KYCRegistryClient,
  Initializable
{
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
}