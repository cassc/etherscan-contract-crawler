pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Dependencies/CheckContract.sol";
import "./Dependencies/Initializable.sol";
import "./Interfaces/IStabilityPoolManager.sol";

contract StabilityPoolManager is Ownable, CheckContract, Initializable, IStabilityPoolManager {
	mapping(address => address) stabilityPools;
	mapping(address => bool) validStabilityPools;

	string public constant NAME = "StabilityPoolManager";

	bool public isInitialized;
	address public adminContract;

	modifier isController() {
		require(msg.sender == owner() || msg.sender == adminContract, "Invalid permissions");
		_;
	}

	function setAddresses(address _adminContract) external initializer onlyOwner {
		require(!isInitialized, "Already initialized");
		checkContract(_adminContract);
		isInitialized = true;

		adminContract = _adminContract;
	}

	function setAdminContract(address _admin) external onlyOwner {
		require(_admin != address(0), "Admin cannot be empty address");
		checkContract(_admin);
		adminContract = _admin;
	}

	function isStabilityPool(address stabilityPool) external view override returns (bool) {
		return validStabilityPools[stabilityPool];
	}

	function addStabilityPool(address asset, address stabilityPool)
		external
		override
		isController
	{
		CheckContract(asset);
		CheckContract(stabilityPool);
		require(!validStabilityPools[stabilityPool], "StabilityPool already created.");
		require(
			IStabilityPool(stabilityPool).getAssetType() == asset,
			"Stability Pool doesn't have the same asset type. Is it initialized?"
		);

		stabilityPools[asset] = stabilityPool;
		validStabilityPools[stabilityPool] = true;

		emit StabilityPoolAdded(asset, stabilityPool);
	}

	function removeStabilityPool(address asset) external isController {
		address stabilityPool = stabilityPools[asset];
		delete validStabilityPools[stabilityPool];
		delete stabilityPools[asset];

		emit StabilityPoolRemoved(asset, stabilityPool);
	}

	function getAssetStabilityPool(address asset)
		external
		view
		override
		returns (IStabilityPool)
	{
		require(stabilityPools[asset] != address(0), "Invalid asset StabilityPool");
		return IStabilityPool(stabilityPools[asset]);
	}

	function unsafeGetAssetStabilityPool(address _asset)
		external
		view
		override
		returns (address)
	{
		return stabilityPools[_asset];
	}
}