// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

import "./interfaces/IEventLogger.sol";
import "./types/types.sol";
import "./RBAC.sol";

contract EventLogger is RBAC, IEventLogger {
	bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

	event SwapInfo(EventData data);

	constructor(address _admin) RBAC(_admin) {}

	function log(EventData calldata _data)
		external
		override
		onlyRole(MANAGER_ROLE)
	{
		require(_data.chains[0] != 0 && _data.chains[1] != 0, "Chain id 0?");
		require(
			_data.parties[0] != address(0) && _data.parties[1] != address(0),
			"EventLogger: incorrect parties"
		);

		emit SwapInfo(_data);
	}
}