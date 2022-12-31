// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import {
	IERC20,
	SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IVault.sol";
import "./RBAC.sol";

/**
 * @title Vault - Ethereum and ERC20 tokens storage.
 */
contract Vault is RBAC, IVault {
	using SafeERC20 for IERC20;

	bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

	event EtherReceived(address indexed, uint256 indexed);

	constructor(address _admin) RBAC(_admin) {}

	receive() external payable {
		emit EtherReceived(msg.sender, msg.value);
	}

	function withdrawEther(address payable _to, uint256 _amount) external override onlyRole(OPERATOR_ROLE) {
		Address.sendValue(_to, _amount);
	}

	function withdrawToken(address _token, address _to, uint256 _amount) external override onlyRole(OPERATOR_ROLE) {
		IERC20(_token).safeTransfer(_to, _amount);
	}
}