// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

interface IVault {
	// Permission: {RBAC.OPERATOR_ROLE||RBAC.DEFAULT_ADMIN_ROLE}
	function withdrawEther(address payable _to, uint256 _amount) external;

	// Permission: {RBAC.OPERATOR_ROLE||RBAC.DEFAULT_ADMIN_ROLE}
	function withdrawToken(address _token, address _to, uint256 _amount) external;
}