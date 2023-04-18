// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

//solhint-disable
import { IPancakeV3Pool } from "@pancakeswap/v3-core/contracts/interfaces/IPancakeV3Pool.sol";
import { IGrizzlyVault } from "../interfaces/IGrizzlyVault.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./gelato/AutomateTaskCreator.sol";

contract StableKeeper is Ownable, AutomateTaskCreator {
	address public immutable pool;
	address public immutable vault;

	bytes32 public taskId;
	uint32 public lastUpdated;
	uint32 public lastExecuted;
	int256 public twat;
	int16 public constant PRECISION = 1e4;

	uint16 public minLiquidityProp;
	uint16 public constant LIQ_PRECISION = 1e4;

	uint24 public twatDelay;
	uint24 public rebalanceDelay;
	int24 public minimalTick;
	int24 public maximalTick;

	event StableKeeperTaskCreated(bytes32 id);
	event StableKeeperTaskCancelled(bytes32 id);
	event StableKeeperPositionRebalanced(
		uint256 time,
		int24 currentTick,
		int24 newLowerTick,
		int24 newUpperTick
	);
	event StableKeeperAutoCompound(
		uint256 time,
		int24 currentTick,
		int24 lowerTick,
		int24 upperTick
	);
	event StableKeeperUpdatedTwat(uint256 time, int256 newTwat);
	event StableKeeperParamsChanged(
		uint256 twatDelay,
		uint256 rebalanceDelay,
		int24 minimalTick,
		int24 maximalTick
	);
	event StableKeeperSetMinLiq(uint16 minLiquidityProp);
	event StableKeeperRecalibratedTime(uint32 lastExecuted, uint32 lastUpdated);

	/// @param _automate address of the Gelato Bot that will automate the execution
	/// BSC Automate: 0x527a819db1eb0e34426297b03bae11F2f8B3A19E
	/// @param _fundsOwner address that can withdraw the funds of this keeper
	/// @param _vault address of the Grizzly vault that we will automate
	/// @param _pool address of the pool associated to the vault above
	constructor(
		address payable _automate,
		address _fundsOwner,
		address _vault,
		address _pool
	) AutomateTaskCreator(_automate, _fundsOwner) {
		require(address(IGrizzlyVault(_vault).pool()) == _pool, "Vault and Pool do not match");
		pool = _pool;
		vault = _vault;

		// Initialize tick
		(, int24 currentTick, , , , , ) = IPancakeV3Pool(pool).slot0();
		twat = currentTick * 1000;

		// Initialize parameters
		minLiquidityProp = 9000;
		twatDelay = 4 hours;
		rebalanceDelay = 1 days;
		minimalTick = -200; // 0.99
		maximalTick = 200; // 1.01
	}

	receive() external payable {}

	/// @notice unique function to execute different logics
	/// @param _functionId id that determines the function to execute
	function execute(uint8 _functionId) external onlyDedicatedMsgSender {
		if (_functionId == 0) {
			_updateTwat();
		} else if (_functionId == 1) {
			_autoCompound();
		} else if (_functionId == 2) {
			_positionRebalance();
		} else {
			revert("Function id not found");
		}

		_payBot();
	}

	// EXTERNAL OWNER FUNCTIONS

	/// @notice create a task for this contract
	/// @dev we only need to call it once. You can send some native token when calling.
	function createTask() external payable onlyOwner {
		require(taskId == bytes32(""), "Already started task");

		// We give empty execData since we use a resolver
		bytes memory execData = abi.encode(this.execute.selector); //abi.encode(new bytes(0));

		// We set the resolver data
		ModuleData memory moduleData = ModuleData({
			modules: new Module[](2),
			args: new bytes[](2)
		});
		moduleData.modules[0] = Module.RESOLVER;
		moduleData.modules[1] = Module.PROXY;

		moduleData.args[0] = _resolverModuleArg(address(this), abi.encodeCall(this.checker, ()));
		moduleData.args[1] = _proxyModuleArg();

		// We create the task with the data and we choose to pay in native token
		taskId = _createTask(address(this), execData, moduleData, ETH);

		emit StableKeeperTaskCreated(taskId);
	}

	/// @notice cancels the task for this contract
	function cancelTask() external onlyOwner {
		require(taskId != bytes32(""), "Task does not exist");
		_cancelTask(taskId);

		emit StableKeeperTaskCancelled(taskId);

		taskId = bytes32("");
	}

	/// @notice sets the delay parameters
	function setParameters(
		uint24 _twatDelay,
		uint24 _rebalanceDelay,
		int24 _minimalTick,
		int24 _maximalTick
	) external onlyOwner {
		require(_twatDelay >= 1 hours && _rebalanceDelay >= 4 hours, "Delays too short");
		require(_minimalTick < _maximalTick, "Ticks in wrong order");
		twatDelay = _twatDelay;
		rebalanceDelay = _rebalanceDelay;
		minimalTick = _minimalTick;
		maximalTick = _maximalTick;

		emit StableKeeperParamsChanged(twatDelay, rebalanceDelay, minimalTick, maximalTick);
	}

	/// @notice sets the minimum liquidity proportion in oorder to rebalance
	/// @param _minLiquidityProp minimum liquidity propoortion. Values between 0 and 10000.
	function setMinLiquidity(uint16 _minLiquidityProp) external onlyOwner {
		require(_minLiquidityProp <= LIQ_PRECISION, "Min Liquidity too high");
		minLiquidityProp = _minLiquidityProp;

		emit StableKeeperSetMinLiq(minLiquidityProp);
	}

	/// @notice recalibrates times for execution
	function recalibrateTime(int256 _deltaExecuted, int256 _deltaUpdated) external onlyOwner {
		require(
			_deltaExecuted < 1 days &&
				(-1) * _deltaExecuted < 1 days &&
				_deltaUpdated < 1 days &&
				(-1) * _deltaUpdated < 1 days,
			"Deltas too high"
		);
		lastExecuted = SafeCast.toUint32(
			uint256(SafeCast.toInt256(lastExecuted) + _deltaExecuted)
		);
		lastUpdated = SafeCast.toUint32(uint256(SafeCast.toInt256(lastUpdated) + _deltaUpdated));

		emit StableKeeperRecalibratedTime(lastExecuted, lastUpdated);
	}

	/// @notice allows to withdraw native tokens to fundsOwner
	function withdraw(uint256 _amount) external onlyOwner {
		uint256 amount = _amount > address(this).balance ? address(this).balance : _amount;

		(bool sent, ) = fundsOwner.call{ value: amount }("");
		require(sent, "Failed to send Ether");
	}

	// EXTERNAL VIEW FUNCTIONS

	/// @notice checker used by bot to determine which action to take
	function checker() external view returns (bool canExec, bytes memory execPayload) {
		(, int24 currentTick, , , , , ) = IPancakeV3Pool(pool).slot0();
		IGrizzlyVault.Ticks memory ticks = IGrizzlyVault(vault).baseTicks();

		if ((block.timestamp - lastUpdated) >= twatDelay) {
			if ((block.timestamp - lastExecuted) >= rebalanceDelay) {
				if (ticks.lowerTick <= currentTick && currentTick <= ticks.upperTick) {
					return (true, abi.encodeCall(this.execute, (1)));
				}

				int256 twatRounded = _round((currentTick * 1000 + 2 * twat) / 3);

				if (ticks.lowerTick <= twatRounded && twatRounded <= ticks.upperTick) {
					return (true, abi.encodeCall(this.execute, (1)));
				} else if (minimalTick <= twatRounded && twatRounded <= maximalTick) {
					return (true, abi.encodeCall(this.execute, (2)));
				}
			}

			canExec = true;
			execPayload = abi.encodeCall(this.execute, (0));
		}
	}

	// INTERNAL FUNCTIONS

	/// @notice Updates the time-weighted-average-tick of the pool
	function _updateTwat() internal {
		require(((block.timestamp - lastUpdated) >= twatDelay), "Already up to date");

		(, int24 currentTick, , , , , ) = IPancakeV3Pool(pool).slot0();

		twat = (currentTick * 1000 + 2 * twat) / 3;

		lastUpdated = SafeCast.toUint32(block.timestamp);

		emit StableKeeperUpdatedTwat(lastUpdated, twat);
	}

	/// @notice autoCompound calls that function on the Grizzly Vault when conditions are met
	function _autoCompound() internal {
		require(
			(block.timestamp - lastUpdated) >= twatDelay &&
				(block.timestamp - lastExecuted) >= rebalanceDelay,
			"autoCompound: Time not elapsed"
		);

		(, int24 currentTick, , , , , ) = IPancakeV3Pool(pool).slot0();
		IGrizzlyVault.Ticks memory ticks = IGrizzlyVault(vault).baseTicks();

		_updateTwat();

		if (ticks.lowerTick <= currentTick && currentTick <= ticks.upperTick) {
			IGrizzlyVault(vault).autoCompound();
			lastExecuted = SafeCast.toUint32(block.timestamp);

			emit StableKeeperAutoCompound(
				lastExecuted,
				currentTick,
				ticks.lowerTick,
				ticks.upperTick
			);
			return;
		}

		int256 twatRounded = _round(twat);

		if (ticks.lowerTick <= twatRounded && twatRounded <= ticks.upperTick) {
			IGrizzlyVault(vault).autoCompound();
			lastExecuted = SafeCast.toUint32(block.timestamp);

			emit StableKeeperAutoCompound(
				lastExecuted,
				currentTick,
				ticks.lowerTick,
				ticks.upperTick
			);
			return;
		}

		revert("Conditions not met to call autoCompound");
	}

	/// @notice positionRebalance calls that function on the Grizzly Vault when conditions are met
	function _positionRebalance() internal {
		require(
			(block.timestamp - lastUpdated) >= twatDelay &&
				(block.timestamp - lastExecuted) >= rebalanceDelay,
			"positionRebalance: Time not elapsed"
		);

		(, int24 currentTick, , , , , ) = IPancakeV3Pool(pool).slot0();
		IGrizzlyVault.Ticks memory ticks = IGrizzlyVault(vault).baseTicks();

		_updateTwat();

		int256 twatRounded = _round(twat);

		require(
			(ticks.lowerTick > currentTick || currentTick > ticks.upperTick) &&
				(ticks.lowerTick > twatRounded || twatRounded > ticks.upperTick) &&
				minimalTick <= twatRounded &&
				twatRounded <= maximalTick,
			"Conditions not met to call positionRebalance"
		);

		uint256 tokenId = IGrizzlyVault(vault).tokenId();
		uint128 liquidity = IGrizzlyVault(vault).liquidityOfPool(tokenId);
		int24 delta = (ticks.upperTick - ticks.lowerTick) / 2; // tickSpacing will be always 1

		IGrizzlyVault(vault).positionRebalance(
			currentTick - delta,
			currentTick + delta,
			(minLiquidityProp * liquidity) / LIQ_PRECISION
		); // or twatRounded TOCHECK
		lastExecuted = SafeCast.toUint32(block.timestamp);

		emit StableKeeperPositionRebalanced(
			lastExecuted,
			currentTick,
			currentTick - delta,
			currentTick + delta
		);
	}

	/// @notice Pays the bot for executing
	function _payBot() internal {
		(uint256 fee, address feeToken) = _getFeeDetails();
		_transfer(fee, feeToken);
	}

	/// @notice it rounds to the closest integer when divided by precision
	function _round(int256 _number) internal view returns (int24 rounded) {
		int256 intermediate = _number > 0
			? (_number + PRECISION / 2) / PRECISION
			: (_number - PRECISION / 2) / PRECISION;
		rounded = SafeCast.toInt24(intermediate);
	}
}