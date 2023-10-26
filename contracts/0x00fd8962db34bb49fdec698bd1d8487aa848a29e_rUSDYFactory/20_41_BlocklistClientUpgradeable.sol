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

import "contracts/interfaces/IBlocklist.sol";
import "contracts/interfaces/IBlocklistClient.sol";
import "contracts/external/openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * @title BlocklistClient
 * @author Ondo Finance
 * @notice This abstract contract manages state for upgradeable blocklist
 *         clients
 */
abstract contract BlocklistClientUpgradeable is
  Initializable,
  IBlocklistClient
{
  // Blocklist contract
  IBlocklist public override blocklist;

  /**
   * @notice Initialize the contract by setting blocklist variable
   *
   * @param _blocklist Address of the blocklist contract
   *
   * @dev Function should be called by the inheriting contract on
   *      initialization
   */
  function __BlocklistClientInitializable_init(
    address _blocklist
  ) internal onlyInitializing {
    __BlocklistClientInitializable_init_unchained(_blocklist);
  }

  /**
   * @dev Internal function to future-proof parent linearization. Matches OZ
   *      upgradeable suggestions
   */
  function __BlocklistClientInitializable_init_unchained(
    address _blocklist
  ) internal onlyInitializing {
    _setBlocklist(_blocklist);
  }

  /**
   * @notice Sets the blocklist address for this client
   *
   * @param _blocklist The new blocklist address
   */
  function _setBlocklist(address _blocklist) internal {
    if (_blocklist == address(0)) {
      revert BlocklistZeroAddress();
    }
    address oldBlocklist = address(blocklist);
    blocklist = IBlocklist(_blocklist);
    emit BlocklistSet(oldBlocklist, _blocklist);
  }

  /**
   * @notice Checks whether an address has been blocked
   *
   * @param account The account to check
   */
  function _isBlocked(address account) internal view returns (bool) {
    return blocklist.isBlocked(account);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}