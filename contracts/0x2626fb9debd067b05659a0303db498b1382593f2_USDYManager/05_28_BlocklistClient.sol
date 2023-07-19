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

/**
 * @title BlocklistClient
 * @author Ondo Finance
 * @notice This abstract contract manages state for blocklist clients
 */
abstract contract BlocklistClient is IBlocklistClient {
  // blocklist address
  IBlocklist public override blocklist;

  /**
   * @notice Constructor
   *
   * @param _blocklist Address of the blocklist contract
   */
  constructor(address _blocklist) {
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
}