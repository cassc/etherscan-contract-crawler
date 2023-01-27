// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

abstract contract LockCycle
{
	struct LockInfo {
		uint256 day;
		uint256 cycle;
		uint256 factor;
	}

	// lock up to 365 days proportionally up to 100%
	uint256 public constant MAX_CYCLE = 365;
	uint256 public constant LOCK_SCALE = 1e18;

	mapping(address => LockInfo) public lockInfo;

	function _adjustLock(address _account, uint256 _newCycle) internal returns (uint256 _oldFactor, uint256 _newFactor)
	{
		uint256 _today = block.timestamp / 1 days;
		LockInfo storage _lockInfo = lockInfo[_account];
		uint256 _oldCycle = _lockInfo.cycle;
		if (_newCycle < _oldCycle) {
			uint256 _day = _lockInfo.day;
			uint256 _base1 = _day % _oldCycle;
			uint256 _base2 = _today % _oldCycle;
			uint256 _days = _base2 > _base1 ? _base2 - _base1 : _base2 < _base1 ? _base2 + _oldCycle - _base1 : _day < _today ? _oldCycle : 0;
			uint256 _minCycle = _oldCycle - _days;
			require(_newCycle >= _minCycle, "below minimum");
		}
		require(_newCycle <= MAX_CYCLE, "above maximum");
		_oldFactor = _lockInfo.factor;
		_newFactor = LOCK_SCALE * _newCycle / MAX_CYCLE;
		_lockInfo.day = _today;
		_lockInfo.cycle = _newCycle;
		_lockInfo.factor = _newFactor;
		return (_oldFactor, _newFactor);
	}

	function _checkLock(address _account) internal view returns (uint256 _factor)
	{
		uint256 _today = block.timestamp / 1 days;
		LockInfo storage _lockInfo = lockInfo[_account];
		uint256 _cycle = _lockInfo.cycle;
		if (_cycle > 0) {
			uint256 _day = _lockInfo.day;
			require(_today > _day && _today % _cycle == _day % _cycle, "not available");
		}
		return _lockInfo.factor;
	}

	function _pushLock(address _account) internal returns (uint256 _factor)
	{
		uint256 _today = block.timestamp / 1 days;
		LockInfo storage _lockInfo = lockInfo[_account];
		_lockInfo.day = _today;
		return _lockInfo.factor;
	}
}