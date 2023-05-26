// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Pausable
 * @author naomsa <https://twitter.com/naomsa666>
 * @notice Freeze your contract with a secure paused mechanism.
 */
abstract contract Pausable {
  /*         _           _            */
  /*        ( )_        ( )_          */
  /*    ___ | ,_)   _ _ | ,_)   __    */
  /*  /',__)| |   /'_` )| |   /'__`\  */
  /*  \__, \| |_ ( (_| || |_ (  ___/  */
  /*  (____/`\__)`\__,_)`\__)`\____)  */

  /// @notice Emited when the contract is paused.
  event Paused(address indexed by);

  /// @notice Emited when the contract is unpaused.
  event Unpaused(address indexed by);

  /// @notice Read-only pause state.
  bool private _paused;

  /// @notice A modifier to be used when the contract must be paused.
  modifier onlyWhenPaused() {
    require(_paused, "Pausable: contract not paused");
    _;
  }

  /// @notice A modifier to be used when the contract must be unpaused.
  modifier onlyWhenUnpaused() {
    require(!_paused, "Pausable: contract paused");
    _;
  }

  /*   _                            */
  /*  (_ )                _         */
  /*   | |    _      __  (_)   ___  */
  /*   | |  /'_`\  /'_ `\| | /'___) */
  /*   | | ( (_) )( (_) || |( (___  */
  /*  (___)`\___/'`\__  |(_)`\____) */
  /*              ( )_) |           */
  /*               \___/'           */

  /// @notice Retrieve contracts pause state.
  function paused() public view returns (bool) {
    return _paused;
  }

  /// @notice Inverts pause state. Declared internal so it can be combined with the Auth contract.
  function _togglePaused() internal {
    _paused = !_paused;
    if (_paused) emit Unpaused(msg.sender);
    else emit Paused(msg.sender);
  }
}