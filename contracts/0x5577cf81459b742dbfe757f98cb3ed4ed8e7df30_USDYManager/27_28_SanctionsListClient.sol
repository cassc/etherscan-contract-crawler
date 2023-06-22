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

import "contracts/external/chainalysis/ISanctionsList.sol";
import "contracts/sanctions/ISanctionsListClient.sol";

/**
 * @title SanctionsListClient
 * @author Ondo Finance
 * @notice This abstract contract manages state required for clients
 *         of the sanctions list
 */
abstract contract SanctionsListClient is ISanctionsListClient {
  // Sanctions list address
  ISanctionsList public override sanctionsList;

  /**
   * @notice Constructor
   *
   * @param _sanctionsList Address of the sanctions list contract
   */
  constructor(address _sanctionsList) {
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