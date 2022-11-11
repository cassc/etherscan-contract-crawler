// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract Governance
{


struct Decree
{
	uint8 actionId;
	address[] approvers;
	uint createdAt;
}

struct DecreeData
{
	uint actionId;
	string actionDescription;
	uint createdAt;
	bool accepted;
	address[] approvers;
	uint approvesNeed;
	uint uintParam;
	uint[] uintParams;
	bool boolParam;
	bool[] boolParams;
	address addressParam;
	address[] addressParams;
}


mapping(address => uint8) private _workers;
uint private _highWorkersCount;

mapping(address => bool) private _validators;
uint private _validatorsCount;

uint public decreesCounter;
mapping(uint => Decree) private _decrees;

mapping(uint => uint) private _uintParams;
mapping(uint => uint[]) private _uintArrayParams;
mapping(uint => bool) private _boolParams;
mapping(uint => bool[]) private _boolArrayParams;
mapping(uint => address) private _addressParams;
mapping(uint => address[]) private _addressArrayParams;


event ValidatorUpdated(address indexed account, bool itIs);
event WorkerUpdated(address indexed account, uint8 newLevel);
event DecreeCreated(uint decreeId, address indexed creator);
event DecreeApproved(uint decreeId, address indexed approver);
event DecreeAccepted(uint decreeId);


constructor(address[] memory validators_, address[] memory workers_, uint[] memory levels_)
{
	require(validators_.length > 4 && workers_.length > 2 && levels_.length == workers_.length,
		'Governance: invalid arrays');

	for (uint i; i < validators_.length; i++)
	{
		require(validators_[i] != address(0), 'Governance: invalid validator');
		require(!_validators[validators_[i]], 'Governance: duplicated validator');

		_validators[validators_[i]] = true;
	}

	for (uint i; i < workers_.length; i++)
	{
		require(workers_[i] != address(0), 'Governance: invalid worker');
		require(levels_[i] > 0 && levels_[i] < 10, 'Governance: invalid worker level');
		require(_workers[workers_[i]] == uint8(0), 'Governance: duplicated worker');

		_workers[workers_[i]] = uint8(levels_[i]);

		if (levels_[i] > 2) _highWorkersCount++;
	}

	require(_highWorkersCount > 1, 'Governance: need at least 2 high workers');
	_validatorsCount = validators_.length;
}

function isValidator(address account) public view returns(bool)
{ return _validators[account]; }

function getWorkerLevel(address account) public view returns(uint)
{ return uint(_workers[account]); }

function _getActionDescription(uint actionId) internal pure virtual returns(string memory)
{
	if (actionId == 1) return 'SetValidator (account, itIs)';
	if (actionId == 2) return 'SetWorker (account, level)';
	return 'INVALID';
}

function _getActionLevel(uint actionId) internal pure virtual returns(uint)
{
	if (actionId == 1) return 3; // setValidator
	if (actionId == 2) return 3; // setWorker
	return 100;
}

function _getActionApproveCount(uint actionId) internal pure virtual returns(uint)
{
	if (actionId == 1) return 4; // setValidator
	if (actionId == 2) return 4; // setWorker
	return 100;
}

function _acceptDecree(uint decreeId, uint actionId) internal virtual
{
	if (actionId == 1) _setValidator(_addressParams[decreeId], _boolParams[decreeId]);
	else if (actionId == 2) _setWorker(_addressParams[decreeId], uint8(_uintParams[decreeId]));
	else require(false, 'Governance: invalid action');
}

function _setValidator(address account, bool itIs) private
{
	require(account != address(0), 'Governance: invalid address');
	require(_validators[account] != itIs, 'Governance: already');

	if (itIs) _validatorsCount++;
	else
	{
		require(_validatorsCount > 5, 'Governance: need at least 5 validators');
		_validatorsCount--;
	}

	_validators[account] = itIs;
	emit ValidatorUpdated(account, itIs);
}

function _setWorker(address account, uint8 level) private
{
	require(account != address(0), 'Governance: invalid address');
	require(level < uint8(10), 'Governance: invalid level');

	uint8 prev = _workers[account];
	require(prev != level, 'Governance: already');

	uint8 high = uint8(3);
	if (prev >= high && level < high || prev < high && level >= high)
	{
		if (level < high)
		{
			require(_highWorkersCount > 2, 'Governance: need at least 2 high workers');
			_highWorkersCount--;
		}
		else _highWorkersCount++;
	}

	_workers[account] = level;
	emit WorkerUpdated(account, level);
}

function createDecree(
	uint8 actionId,
	uint[] memory uints,
	bool[] memory bools,
	address[] memory addresses
) external
{
	require(_getActionLevel(uint(actionId)) <= uint(_workers[msg.sender]), 'Governance: not allowed');

	Decree storage decree = _decrees[++decreesCounter];
	decree.actionId = actionId;
	decree.createdAt = block.timestamp;

	if (uints.length > 0)
	{
		if (uints.length > 1)
		{
			uint[] storage arr = _uintArrayParams[decreesCounter];
			for (uint i; i < uints.length; i++) arr.push(uints[i]);
		}
		else _uintParams[decreesCounter] = uints[0];
	}

	if (bools.length > 0)
	{
		if (bools.length > 1)
		{
			bool[] storage arr = _boolArrayParams[decreesCounter];
			for (uint i; i < bools.length; i++) arr.push(bools[i]);
		}
		else _boolParams[decreesCounter] = bools[0];
	}

	if (addresses.length > 0)
	{
		if (addresses.length > 1)
		{
			address[] storage arr = _addressArrayParams[decreesCounter];
			for (uint i; i < addresses.length; i++) arr.push(addresses[i]);
		}
		else _addressParams[decreesCounter] = addresses[0];
	}

	emit DecreeCreated(decreesCounter, msg.sender);
}

function approveDecree(uint decreeId) external
{
	require(_validators[msg.sender], 'Governance: not allowed');

	Decree storage decree = _decrees[decreeId];
	require(decree.createdAt + 3600 > block.timestamp, 'Governance: deprecated');

	uint countNeed = _getActionApproveCount(uint(decree.actionId));
	require(decree.approvers.length < countNeed, 'Governance: accepted');

	for (uint i; i < decree.approvers.length; i++)
		require(decree.approvers[i] != msg.sender, 'Governance: approved');

	decree.approvers.push(msg.sender);
	emit DecreeApproved(decreeId, msg.sender);

	if (decree.approvers.length >= countNeed)
	{
		_acceptDecree(decreeId, uint(decree.actionId));
		emit DecreeAccepted(decreeId);
	}
}

function _getUintParam(uint decreeId) internal view returns(uint)
{ return _uintParams[decreeId]; }

function _getUintArrayParam(uint decreeId) internal view returns(uint[] memory)
{ return _uintArrayParams[decreeId]; }

function _getBoolParam(uint decreeId) internal view returns(bool)
{ return _boolParams[decreeId]; }

function _getBoolArrayParam(uint decreeId) internal view returns(bool[] memory)
{ return _boolArrayParams[decreeId]; }

function _getAddressParam(uint decreeId) internal view returns(address)
{ return _addressParams[decreeId]; }

function _getAddressArrayParam(uint decreeId) internal view returns(address[] memory)
{ return _addressArrayParams[decreeId]; }


function getDecreeData(uint decreeId) external view returns(DecreeData memory)
{
	Decree memory decree = _decrees[decreeId];
	return DecreeData(
		uint(decree.actionId),
		_getActionDescription(decree.actionId),
		decree.createdAt,
		decree.approvers.length >= _getActionApproveCount(decree.actionId),
		decree.approvers,
		_getActionApproveCount(decree.actionId),
		_uintParams[decreeId],
		_uintArrayParams[decreeId],
		_boolParams[decreeId],
		_boolArrayParams[decreeId],
		_addressParams[decreeId],
		_addressArrayParams[decreeId]
	);
}


}