// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "./interfaces/IAliumMulitichain.sol";
import "./interfaces/IVault.sol";
import "./RBAC.sol";

contract AliumMultichain is IAliumMulitichain, RBAC {
	// TODO: add protocol fee
	//	uint256 public protocolFee;

	bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
	bytes32 public constant ADAPTER_ROLE = keccak256("ADAPTER_ROLE");

	address public vault;
	address internal _eventLogger;
	uint256 internal _nonce;

	mapping(uint256 => Swap) internal _trades;
	mapping(address => bool) public adapters;

	constructor(address _admin) RBAC(_admin) {}

	function applyNonce() external onlyRole(ADAPTER_ROLE) returns (uint256) {
		require(adapters[msg.sender], "Only adapter");
		_nonce++;
		return _nonce;
	}

	function applyTrade(uint256 _id, Swap calldata _data) external onlyRole(ADAPTER_ROLE) {
		_trades[_id] = _data;
	}

	// @dev Emergency method to withdraw balance from
	function handle(uint256 _id) external onlyRole(OPERATOR_ROLE) {
		Swap memory details = _trades[_id];
		if (details.token == address(0)) {
			IVault(vault).withdrawEther(payable(msg.sender), details.amount);
		} else {
			IVault(vault).withdrawToken(details.token, msg.sender, details.amount);
		}
	}

	function addAdapter(address _adapter) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(!adapters[_adapter], "Already set");
		adapters[_adapter] = true;
	}

	function setAdapter(address _oldOne, address _newOne) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(adapters[_oldOne] && _oldOne != _newOne && _newOne != address(0), "Invalid configs");
		adapters[_oldOne] = false;
		adapters[_newOne] = true;
	}

	function removeAdapter(address _adapter) external onlyRole(DEFAULT_ADMIN_ROLE) {
		require(adapters[_adapter], "Already unset");
		adapters[_adapter] = false;
	}

	function setEventLogger(address _el) external onlyRole(DEFAULT_ADMIN_ROLE) {
		_eventLogger = _el;
	}

	function setVault(address _vault) external onlyRole(DEFAULT_ADMIN_ROLE) {
		vault = _vault;
	}

	function eventLogger() external view returns (address) {
		return _eventLogger;
	}

	function nonce() external view returns (uint256) {
		return _nonce;
	}

	function trades(uint256 _id) external view returns (Swap memory result) {
		result = _trades[_id];
	}
}