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

import "contracts/external/openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "contracts/external/chainalysis/ISanctionsList.sol";
import "contracts/sanctions/ISanctionsListClient.sol";

/**
 * @title SanctionsListClient
 * @author Ondo Finance
 * @notice This abstract contract enables inheritors to query whether accounts
 *         are sanctioned or not
 */
abstract contract SanctionsListClientUpgradeable is
  Initializable,
  ISanctionsListClient
{
  // Sanctions list address
  ISanctionsList public override sanctionsList;

  /**
   * @notice Initialize the contract by setting blocklist variable
   *
   * @param _sanctionsList Address of the sanctionsList contract
   *
   * @dev Function should be called by the inheriting contract on
   *      initialization
   */
  function __SanctionsListClientInitializable_init(
    address _sanctionsList
  ) internal onlyInitializing {
    __SanctionsListClientInitializable_init_unchained(_sanctionsList);
  }

  /**
   * @dev Internal function to future-proof parent linearization. Matches OZ
   *      upgradeable suggestions
   */
  function __SanctionsListClientInitializable_init_unchained(
    address _sanctionsList
  ) internal onlyInitializing {
    _setSanctionsList(_sanctionsList);
  }

  /**
   * @notice Sets the sanctions list address for this client
   *
   * @param _sanctionsList The new sanctions list address
   */
  function _setSanctionsList(address _sanctionsList) internal {
    if (_sanctionsList == address(0)) {
      revert SanctionsListZeroAddress();
    }
    address oldSanctionsList = address(sanctionsList);
    sanctionsList = ISanctionsList(_sanctionsList);
    emit SanctionsListSet(oldSanctionsList, _sanctionsList);
  }

  /**
   * @notice Checks whether an address has been sanctioned
   *
   * @param account The account to check
   */
  function _isSanctioned(address account) internal view returns (bool) {
    return sanctionsList.isSanctioned(account);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}