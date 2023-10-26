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

import "contracts/interfaces/IAllowlist.sol";
import "contracts/interfaces/IAllowlistClient.sol";
import "contracts/external/openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

/**
 * @title AllowlistClientInitializable
 * @author Ondo Finance
 * @notice This abstract contract manages state required for clients
 *         of the allowlist
 */
abstract contract AllowlistClientUpgradeable is
  Initializable,
  IAllowlistClient
{
  // allowlist address
  IAllowlist public override allowlist;

  /**
   * @notice Initialize the contract by setting allowlist variable
   *
   * @param _allowlist Address of the allowlist contract
   *
   * @dev Function should be called by the inheriting contract on
   *      initialization
   */
  function __AllowlistClientInitializable_init(
    address _allowlist
  ) internal onlyInitializing {
    __AllowlistClientInitializable_init_unchained(_allowlist);
  }

  /**
   * @dev Internal function to future-proof parent linearization. Matches OZ
   *      upgradeable suggestions
   */
  function __AllowlistClientInitializable_init_unchained(
    address _allowlist
  ) internal onlyInitializing {
    _setAllowlist(_allowlist);
  }

  /**
   * @notice Sets the allowlist address for this client
   *
   * @param _allowlist The new allowlist address
   */
  function _setAllowlist(address _allowlist) internal {
    if (_allowlist == address(0)) {
      revert AllowlistZeroAddress();
    }
    address oldAllowlist = address(allowlist);
    allowlist = IAllowlist(_allowlist);
    emit AllowlistSet(oldAllowlist, _allowlist);
  }

  /**
   * @notice Checks whether an address has been Blocked
   *
   * @param account The account to check
   */
  function _isAllowed(address account) internal view returns (bool) {
    return allowlist.isAllowed(account);
  }

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[50] private __gap;
}