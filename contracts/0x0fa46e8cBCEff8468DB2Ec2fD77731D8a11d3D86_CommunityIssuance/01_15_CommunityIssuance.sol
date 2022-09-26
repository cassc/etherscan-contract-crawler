// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../Interfaces/IStabilityPoolManager.sol";
import "../Interfaces/ICommunityIssuance.sol";
import "../Dependencies/BaseMath.sol";
import "../Dependencies/DfrancMath.sol";
import "../Dependencies/CheckContract.sol";
import "../Dependencies/Initializable.sol";

contract CommunityIssuance is
	ICommunityIssuance,
	Ownable,
	CheckContract,
	BaseMath,
	Initializable
{
	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	string public constant NAME = "CommunityIssuance";
	uint256 public constant DISTRIBUTION_DURATION = 7 days / 60;
	uint256 public constant SECONDS_IN_ONE_MINUTE = 60;

	IERC20 public monToken;
	IStabilityPoolManager public stabilityPoolManager;

	mapping(address => uint256) public totalMONIssued;
	mapping(address => uint256) public lastUpdateTime; // lastUpdateTime is in minutes
	mapping(address => uint256) public MONSupplyCaps;
	mapping(address => uint256) public monDistributionsByPool; // monDistributionsByPool is in minutes

	address public adminContract;

	bool public isInitialized;

	modifier activeStabilityPoolOnly(address _pool) {
		require(lastUpdateTime[_pool] != 0, "CommunityIssuance: Pool needs to be added first.");
		_;
	}

	modifier isController() {
		require(msg.sender == owner() || msg.sender == adminContract, "Invalid Permission");
		_;
	}

	modifier isStabilityPool(address _pool) {
		require(
			stabilityPoolManager.isStabilityPool(_pool),
			"CommunityIssuance: caller is not SP"
		);
		_;
	}

	modifier onlyStabilityPool() {
		require(
			stabilityPoolManager.isStabilityPool(msg.sender),
			"CommunityIssuance: caller is not SP"
		);
		_;
	}

	// --- Functions ---
	function setAddresses(
		address _monTokenAddress,
		address _stabilityPoolManagerAddress,
		address _adminContract
	) external override initializer {
		require(!isInitialized, "Already initialized");
		checkContract(_monTokenAddress);
		checkContract(_stabilityPoolManagerAddress);
		checkContract(_adminContract);
		isInitialized = true;

		adminContract = _adminContract;

		monToken = IERC20(_monTokenAddress);
		stabilityPoolManager = IStabilityPoolManager(_stabilityPoolManagerAddress);

		emit MONTokenAddressSet(_monTokenAddress);
		emit StabilityPoolAddressSet(_stabilityPoolManagerAddress);
	}

	function setAdminContract(address _admin) external onlyOwner {
		require(_admin != address(0), "Admin address is zero");
		checkContract(_admin);
		adminContract = _admin;
	}

	function addFundToStabilityPool(address _pool, uint256 _assignedSupply)
		external
		override
		isController
	{
		_addFundToStabilityPoolFrom(_pool, _assignedSupply, msg.sender);
	}

	function removeFundFromStabilityPool(address _pool, uint256 _fundToRemove)
		external
		onlyOwner
		activeStabilityPoolOnly(_pool)
	{
		uint256 newCap = MONSupplyCaps[_pool].sub(_fundToRemove);
		require(
			totalMONIssued[_pool] <= newCap,
			"CommunityIssuance: Stability Pool doesn't have enough supply."
		);

		MONSupplyCaps[_pool] -= _fundToRemove;

		if (totalMONIssued[_pool] == MONSupplyCaps[_pool]) {
			disableStabilityPool(_pool);
		}

		monToken.safeTransfer(msg.sender, _fundToRemove);
	}

	function addFundToStabilityPoolFrom(
		address _pool,
		uint256 _assignedSupply,
		address _spender
	) external override isController {
		_addFundToStabilityPoolFrom(_pool, _assignedSupply, _spender);
	}

	function _addFundToStabilityPoolFrom(
		address _pool,
		uint256 _assignedSupply,
		address _spender
	) internal {
		require(
			stabilityPoolManager.isStabilityPool(_pool),
			"CommunityIssuance: Invalid Stability Pool"
		);

		if (lastUpdateTime[_pool] == 0) {
			lastUpdateTime[_pool] = (block.timestamp / SECONDS_IN_ONE_MINUTE);
		}

		MONSupplyCaps[_pool] += _assignedSupply;
		monToken.safeTransferFrom(_spender, address(this), _assignedSupply);
	}

	function transferFundToAnotherStabilityPool(
		address _target,
		address _receiver,
		uint256 _quantity
	)
		external
		override
		onlyOwner
		activeStabilityPoolOnly(_target)
		activeStabilityPoolOnly(_receiver)
	{
		uint256 newCap = MONSupplyCaps[_target].sub(_quantity);
		require(
			totalMONIssued[_target] <= newCap,
			"CommunityIssuance: Stability Pool doesn't have enough supply."
		);

		MONSupplyCaps[_target] -= _quantity;
		MONSupplyCaps[_receiver] += _quantity;

		if (totalMONIssued[_target] == MONSupplyCaps[_target]) {
			disableStabilityPool(_target);
		}
	}

	function disableStabilityPool(address _pool) internal {
		lastUpdateTime[_pool] = 0;
		MONSupplyCaps[_pool] = 0;
		totalMONIssued[_pool] = 0;
	}

	function issueMON() external override onlyStabilityPool returns (uint256) {
		return _issueMON(msg.sender);
	}

	function _issueMON(address _pool) internal isStabilityPool(_pool) returns (uint256) {
		uint256 maxPoolSupply = MONSupplyCaps[_pool];

		if (totalMONIssued[_pool] >= maxPoolSupply) return 0;

		uint256 issuance = _getLastUpdateTokenDistribution(_pool);
		uint256 totalIssuance = issuance.add(totalMONIssued[_pool]);

		if (totalIssuance > maxPoolSupply) {
			issuance = maxPoolSupply.sub(totalMONIssued[_pool]);
			totalIssuance = maxPoolSupply;
		}

		lastUpdateTime[_pool] = (block.timestamp / SECONDS_IN_ONE_MINUTE);
		totalMONIssued[_pool] = totalIssuance;
		emit TotalMONIssuedUpdated(_pool, totalIssuance);

		return issuance;
	}

	function _getLastUpdateTokenDistribution(address stabilityPool)
		internal
		view
		returns (uint256)
	{
		require(lastUpdateTime[stabilityPool] != 0, "Stability pool hasn't been assigned");
		uint256 timePassed = block.timestamp.div(SECONDS_IN_ONE_MINUTE).sub(
			lastUpdateTime[stabilityPool]
		);
		uint256 totalDistributedSinceBeginning = monDistributionsByPool[stabilityPool].mul(
			timePassed
		);

		return totalDistributedSinceBeginning;
	}

	function sendMON(address _account, uint256 _MONamount) external override onlyStabilityPool {
		uint256 balanceMON = monToken.balanceOf(address(this));
		uint256 safeAmount = balanceMON >= _MONamount ? _MONamount : balanceMON;

		if (safeAmount == 0) {
			return;
		}

		monToken.safeTransfer(_account, safeAmount);
	}

	function setWeeklyDfrancDistribution(address _stabilityPool, uint256 _weeklyReward)
		external
		isController
		isStabilityPool(_stabilityPool)
	{
		monDistributionsByPool[_stabilityPool] = _weeklyReward.div(DISTRIBUTION_DURATION);
	}
}