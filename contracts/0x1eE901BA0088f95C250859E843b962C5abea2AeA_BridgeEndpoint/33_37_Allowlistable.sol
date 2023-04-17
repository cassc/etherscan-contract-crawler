// SPDX-License-Identifier: BUSL-1.1

import "./Errors.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

pragma solidity ^0.8.17;

contract Allowlistable is Initializable {
  bool public allowlist;
  mapping(address => bool) public allowlisted;

  event AddAllowlistEvent(address[] _allowed);
  event RemoveAllowlistEvent(address[] _removed);
  event AllowlistEvent(bool allowlist);

  function __Allowlistable_init() internal onlyInitializing {}

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  modifier onlyAllowlisted() {
    _require(!allowlist || allowlisted[msg.sender], Errors.APPROVED_ONLY);
    _;
  }

  function _onAllowlist() internal {
    allowlist = true;
    emit AllowlistEvent(allowlist);
  }

  function _offAllowlist() internal {
    allowlist = false;
    emit AllowlistEvent(allowlist);
  }

  function _addAllowlist(address[] memory _allowed) internal {
    uint256 _length = _allowed.length;
    for (uint256 i = 0; i < _length; ++i) {
      allowlisted[_allowed[i]] = true;
    }
    emit AddAllowlistEvent(_allowed);
  }

  function _removeAllowlist(address[] memory _removed) internal {
    uint256 _length = _removed.length;
    for (uint256 i = 0; i < _length; ++i) {
      allowlisted[_removed[i]] = false;
    }
    emit RemoveAllowlistEvent(_removed);
  }
}