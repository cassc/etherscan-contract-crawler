// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./interfaces/IOKGManagement.sol";
import "./interfaces/IERC20MintableBurnable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

contract OKGSwap is ContextUpgradeable {
	bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

	IOKGManagement public gov;
	address public okg;
  address public depository;

	mapping(bytes32 => DepositData) deposits;

	modifier onlyManager() {
		require(gov.hasRole(MANAGER_ROLE, msg.sender), "Caller is not Manager");
		_;
	}

	event Deposit(address owner, uint256 amount, string uuid);

	struct DepositData {
		uint256 amount;
		address user;
	}

	function init(IOKGManagement _gov, address _okg, address _dep)
		external
		initializer
	{
		__Context_init();
		gov = _gov;
		okg = _okg;
    depository = _dep;
	}

	function setGov(IOKGManagement _gov) external onlyManager {
		gov = _gov;
	}

	function setOkg(address _kab) external onlyManager {
		okg = _kab;
	}

  function setDepository(address _dep) external onlyManager {
    depository = _dep;
  }

	function emergencyWithdraw(address _receivers, uint256 _amounts)
		external
		onlyManager
	{
		IERC20MintableBurnable(okg).transferFrom(address(this), _receivers, _amounts);
	}

	function getDepositHash(string calldata _uuid)
		internal
		pure
		returns (bytes32)
	{
		return
			ECDSAUpgradeable.toEthSignedMessageHash(
				keccak256(abi.encodePacked(_uuid))
			);
	}

	function deposit(
		uint256 _amount,
		string calldata _uuid,
		bytes calldata _signature
	) external {
		address recAddr = ECDSAUpgradeable.recover(
			getDepositHash(_uuid),
			_signature
		);
		require(gov.hasRole(MANAGER_ROLE, recAddr), "Invalid params or signature");

		bytes32 depId = keccak256(abi.encodePacked(_uuid));
		require(deposits[depId].amount == 0, "Deposit ID already used");
		deposits[depId] = DepositData(_amount, _msgSender());

		IERC20MintableBurnable(okg).transferFrom(_msgSender(), depository, _amount);

		emit Deposit(_msgSender(), _amount, _uuid);
	}

	function getDeposit(string calldata _uuid) external view returns (DepositData memory) {
		bytes32 depId = keccak256(abi.encodePacked(_uuid));

		return deposits[depId];
	}
}