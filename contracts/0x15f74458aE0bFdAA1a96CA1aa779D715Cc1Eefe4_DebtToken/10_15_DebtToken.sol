// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";

import "./Dependencies/ERC20Permit.sol";
import "./Interfaces/IDebtToken.sol";

contract DebtToken is IDebtToken, ERC20Permit, Ownable {
	string public constant NAME = "GRAI";

	address public constant borrowerOperationsAddress = 0x2bCA0300c2aa65de6F19c2d241B54a445C9990E2;
	address public constant stabilityPoolAddress = 0x4F39F12064D83F6Dd7A2BDb0D53aF8be560356A6;
	address public constant vesselManagerAddress = 0xdB5DAcB1DFbe16326C3656a88017f0cB4ece0977;

	mapping(address => bool) public emergencyStopMintingCollateral;

	// stores SC addresses that are allowed to mint/burn the token (AMO strategies, L2 suppliers)
	mapping(address => bool) public whitelistedContracts;

	constructor() ERC20("Gravita Debt Token", "GRAI") {}

	function emergencyStopMinting(address _asset, bool status) external override onlyOwner {
		emergencyStopMintingCollateral[_asset] = status;
		emit EmergencyStopMintingCollateral(_asset, status);
	}

	function mintFromWhitelistedContract(uint256 _amount) external override {
		_requireCallerIsWhitelistedContract();
		_mint(msg.sender, _amount);
	}

	function burnFromWhitelistedContract(uint256 _amount) external override {
		_requireCallerIsWhitelistedContract();
		_burn(msg.sender, _amount);
	}

	function mint(address _asset, address _account, uint256 _amount) external override {
		_requireCallerIsBorrowerOperations();
		require(!emergencyStopMintingCollateral[_asset], "Mint is blocked on this collateral");

		_mint(_account, _amount);
	}

	function burn(address _account, uint256 _amount) external override {
		_requireCallerIsBOorVesselMorSP();
		_burn(_account, _amount);
	}

	function addWhitelist(address _address) external override onlyOwner {
		whitelistedContracts[_address] = true;

		emit WhitelistChanged(_address, true);
	}

	function removeWhitelist(address _address) external override onlyOwner {
		whitelistedContracts[_address] = false;

		emit WhitelistChanged(_address, false);
	}

	function sendToPool(address _sender, address _poolAddress, uint256 _amount) external override {
		_requireCallerIsStabilityPool();
		_transfer(_sender, _poolAddress, _amount);
	}

	function returnFromPool(address _poolAddress, address _receiver, uint256 _amount) external override {
		_requireCallerIsVesselMorSP();
		_transfer(_poolAddress, _receiver, _amount);
	}

	// --- External functions ---

	function transfer(address recipient, uint256 amount) public override(IERC20, ERC20) returns (bool) {
		_requireValidRecipient(recipient);
		return super.transfer(recipient, amount);
	}

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) public override(IERC20, ERC20) returns (bool) {
		_requireValidRecipient(recipient);
		return super.transferFrom(sender, recipient, amount);
	}

	// --- 'require' functions ---

	function _requireValidRecipient(address _recipient) internal view {
		require(
			_recipient != address(0) && _recipient != address(this),
			"DebtToken: Cannot transfer tokens directly to the token contract or the zero address"
		);
	}

	function _requireCallerIsWhitelistedContract() internal view {
		require(whitelistedContracts[msg.sender], "DebtToken: Caller is not a whitelisted SC");
	}

	function _requireCallerIsBorrowerOperations() internal view {
		require(msg.sender == borrowerOperationsAddress, "DebtToken: Caller is not BorrowerOperations");
	}

	function _requireCallerIsBOorVesselMorSP() internal view {
		require(
			msg.sender == borrowerOperationsAddress ||
				msg.sender == vesselManagerAddress ||
				msg.sender == stabilityPoolAddress,
			"DebtToken: Caller is neither BorrowerOperations nor VesselManager nor StabilityPool"
		);
	}

	function _requireCallerIsStabilityPool() internal view {
		require(msg.sender == stabilityPoolAddress, "DebtToken: Caller is not the StabilityPool");
	}

	function _requireCallerIsVesselMorSP() internal view {
		require(
			msg.sender == vesselManagerAddress || msg.sender == stabilityPoolAddress,
			"DebtToken: Caller is neither VesselManager nor StabilityPool"
		);
	}
}