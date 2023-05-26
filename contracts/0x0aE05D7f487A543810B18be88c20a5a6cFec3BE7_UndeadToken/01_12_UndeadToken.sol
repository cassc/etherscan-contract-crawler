// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

abstract contract AntiShark is OwnableUpgradeable, AccessControlUpgradeable {
  bytes32 internal constant _ANTISHARK_ROLE = keccak256("ANTISHARK_ROLE");

  uint256 private _startTime;
  uint256 private _endTime;
  uint256 private _dumpTime;
  uint256 private _limitShark;
  uint256 private _defaultLimitDuration;
  bool private _antiSharkActivated;
  bool private _initialList;
  mapping(address => bool) internal _isWhitelist;

  event EActivate();
  event EDeactivate();
  event EConfigLimitAmount(uint256 limitAmount);
  event EConfigDefaultLimitDuration(uint256 limitDuration);
  event EWhitelist(address account, bool status);

  function __AntiShark_init() internal initializer {
    _limitShark = 2499e18;
    _defaultLimitDuration = 5 minutes;
    _initialList = true;
  }

  function isWhitelist(address _account) external view onlyRole(_ANTISHARK_ROLE) returns (bool) {
    return _isWhitelist[_account];
  }

  function activateAntiShark(uint _pStartTime, uint256 _pEndTime) external onlyRole(_ANTISHARK_ROLE) {
    if (_pStartTime == 0) _startTime = block.timestamp;
    else _startTime = _pStartTime;
    if (_pEndTime == 0) _endTime = _startTime + _defaultLimitDuration;
    else _endTime = _pEndTime;
    _initialList = false;
    _antiSharkActivated = true;
    emit EActivate();
  }

  function deActivateAntiShark() external onlyRole(_ANTISHARK_ROLE) {
    _antiSharkActivated = false;
    emit EDeactivate();
  }

  function setAntiSharkAmount(uint256 _limitAmount) external onlyRole(_ANTISHARK_ROLE) {
    _limitShark = _limitAmount / 3;
    emit EConfigLimitAmount(_limitAmount);
  }

  function setDefaultLimitDuration(uint256 _limitDuration) external onlyRole(_ANTISHARK_ROLE) {
    _defaultLimitDuration = _limitDuration;
    emit EConfigDefaultLimitDuration(_limitDuration);
  }

  function setWhitelist(address _account, bool _status) external onlyRole(_ANTISHARK_ROLE) {
    _isWhitelist[_account] = _status;
    emit EWhitelist(_account, _status);
  }

  function _isShark(
    address _sender,
    address _recipient,
    uint256 _amount
  ) internal view returns (bool) {
    if (_isWhitelist[_sender] || _isWhitelist[_recipient]) return false;
    if (_initialList) return true;
    if (_antiSharkActivated && _amount > _limitShark && block.timestamp >= _startTime && block.timestamp <= _endTime)
      return true;
    return false;
  }
}

contract UndeadToken is ERC20Upgradeable, OwnableUpgradeable, AccessControlUpgradeable, AntiShark {
  bytes32 private constant _EDITOR_ROLE = keccak256("EDITOR_ROLE");
  bytes32 private constant _EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

  mapping(address => bool) public isBlacklist;
  bool public isWhitelistMode;

  event EBlacklist(address account, bool status);
  event EEmergencyTransfer(address token);

  function __UndeadToken_init() external initializer {
    __Ownable_init();
    __ERC20_init("Undead Blocks", "UNDEAD");
    __AntiShark_init();
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    _setupRole(_ANTISHARK_ROLE, _msgSender());
    _setupRole(_EDITOR_ROLE, _msgSender());

    _mint(_msgSender(), 500_000_000e18);
    _isWhitelist[_msgSender()] = true;
  }

  function setBlacklist(address _account, bool _status) external onlyRole(_EDITOR_ROLE) {
    isBlacklist[_account] = _status;
    emit EBlacklist(_account, _status);
  }

  function setWhitelistMode(bool _status) external onlyRole(_EDITOR_ROLE) {
    isWhitelistMode = _status;
  }

  function _transfer(
    address _sender,
    address _recipient,
    uint256 _amount
  ) internal override {
    if (_recipient == address(0)) {
      _burn(_sender, _amount);
    } else {
      //require(!_isShark(_sender, _recipient, _amount), "Reason:01");
      if (isWhitelistMode) {
        require(_isWhitelist[_sender] || _isWhitelist[_recipient], "Reason:01");
      }
      require(!isBlacklist[_sender] && !isBlacklist[_recipient], "Reason:02");
      super._transfer(_sender, _recipient, _amount);
    }
  }
}