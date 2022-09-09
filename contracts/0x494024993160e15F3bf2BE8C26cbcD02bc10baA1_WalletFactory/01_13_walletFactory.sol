// SPDX-License-Identifier:GPL-3.0-only
pragma solidity 0.8.4;

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { WalletProxy } from "./external/walletproxy.sol";
import { Create2 } from "./external/create2.sol";

contract WalletFactory is AccessControlEnumerable {
	using Address for address;

	event CreateWallet(address indexed wallet, string indexed name);
	event NewWalletImplementation(address indexed newWalletImplementation);
	event FreeCreationChanged(bool indexed enabled);

	address public walletImplementation;
	bool public freeCreationEnabled;
	string public constant WALLET_CREATION = "WALLET_CREATION";
	bytes32 public constant ROLE_WALLET_CREATOR =
		keccak256("ROLE_WALLET_CREATOR");

	struct CreateRecord {
		address wallet;
		string name;
	}

	CreateRecord[] public created;

	constructor() {
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
	}

	function createWallet(string calldata walletName, bytes calldata data)
		external
		returns (address wallet)
	{
		if (!freeCreationEnabled) {
			_checkRole(ROLE_WALLET_CREATOR, msg.sender);
		}
		require(
			walletImplementation != address(0),
			"WalletFactory: missing wallet implementation"
		);

		wallet = _deploy(walletName);
		wallet.functionCall(data);

		created.push(CreateRecord(wallet, walletName));
		emit CreateWallet(wallet, walletName);
	}

	function setWalletImplementation(address newWalletImplementation)
		external
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(
			newWalletImplementation != address(0),
			"WalletFactory: Invalid wallet implementation"
		);
		walletImplementation = newWalletImplementation;
		emit NewWalletImplementation(newWalletImplementation);
	}

	function setFreeCreation(bool enabled) public onlyRole(DEFAULT_ADMIN_ROLE) {
		freeCreationEnabled = enabled;
		emit FreeCreationChanged(enabled);
	}

	function computeWalletAddress(string memory walletName)
		public
		view
		returns (address)
	{
		return
			Create2.computeAddress(
				keccak256(abi.encodePacked(WALLET_CREATION, walletName)),
				_getWalletCode()
			);
	}

	function getCreated() public view returns (CreateRecord[] memory) {
		return created;
	}

	function getCreatedLength() public view returns (uint256) {
		return created.length;
	}

	// --- Internal functions ---

	function _deploy(string calldata walletName)
		internal
		returns (address payable wallet)
	{
		// Deploy the wallet proxy
		wallet = Create2.deploy(
			keccak256(abi.encodePacked(WALLET_CREATION, walletName)),
			_getWalletCode()
		);
		WalletProxy(wallet).initializeFromWalletFactory(walletImplementation);
	}

	function _getWalletCode() internal pure returns (bytes memory) {
		return type(WalletProxy).creationCode;
	}
}