// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./SdtDistributorEvents.sol";

/// @title SdtDistributorV2
/// @notice Earn from Masterchef SDT and distribute it to gauges
contract SdtDistributorV2 is ReentrancyGuardUpgradeable, AccessControlUpgradeable, SdtDistributorEvents {
	using SafeERC20 for IERC20;

	////////////////////////////////////////////////////////////////
	/// --- CONSTANTS
	///////////////////////////////////////////////////////////////

	/// @notice Accounting
	uint256 public constant BASE_UNIT = 10_000;

	/// @notice Address of the SDT token given as a reward.
	IERC20 public constant rewardToken = IERC20(0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F);

	/// @notice Address of the masterchef.
	IMasterchef public constant masterchef = IMasterchef(0xfEA5E213bbD81A8a94D0E1eDB09dBD7CEab61e1c);

	/// @notice Role for governors only.
	bytes32 public constant GOVERNOR_ROLE = keccak256("GOVERNOR_ROLE");
	/// @notice Role for the guardian
	bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");

	////////////////////////////////////////////////////////////////
	/// --- STORAGE SLOTS
	///////////////////////////////////////////////////////////////

	/// @notice Time between SDT Harvest.
	uint256 public timePeriod;

	/// @notice Address of the token that will be deposited in masterchef.
	IERC20 public masterchefToken;

	/// @notice Address of the `GaugeController` contract.
	IGaugeController public controller;

	/// @notice Address responsible for pulling rewards of type >= 2 gauges and distributing it to the
	/// associated contracts if there is not already an address delegated for this specific contract.
	address public delegateGauge;

	/// @notice Whether SDT distribution through this contract is on or no.
	bool public distributionsOn;

	/// @notice Maps the address of a type >= 2 gauge to a delegate address responsible
	/// for giving rewards to the actual gauge.
	mapping(address => address) public delegateGauges;

	/// @notice Maps the address of a gauge to whether it was killed or not
	/// A gauge killed in this contract cannot receive any rewards.
	mapping(address => bool) public killedGauges;

	/// @notice Maps the address of a gauge delegate to whether this delegate supports the `notifyReward` interface
	/// and is therefore built for automation.
	mapping(address => bool) public isInterfaceKnown;

	/// @notice Masterchef PID
	uint256 public masterchefPID;

	/// @notice Timestamp of the last pull from masterchef.
	uint256 public lastMasterchefPull;

	/// @notice Maps the timestamp of pull action to the amount of SDT that pulled.
	mapping(uint256 => uint256) public pulls; // day => SDT amount

	/// @notice Maps the timestamp of last pull to the gauge addresses then keeps the data if particular gauge paid in the last pull.
	mapping(uint256 => mapping(address => bool)) public isGaugePaid;

	/// @notice Incentive for caller.
	uint256 public claimerFee;

	/// @notice Number of days to go through for past distributing.
	uint256 public lookPastDays;

	////////////////////////////////////////////////////////////////
	/// --- INITIALIZATION LOGIC
	///////////////////////////////////////////////////////////////

	/// @notice Initialize function
	/// @param _controller gauge controller to manage votes
	/// @param _governor governor address
	/// @param _guardian guardian address
	/// @param _delegateGauge delegate gauge address
	function initialize(
		address _controller,
		address _governor,
		address _guardian,
		address _delegateGauge
	) external initializer {
		require(_controller != address(0) && _guardian != address(0) && _governor != address(0), "0");

		controller = IGaugeController(_controller);
		delegateGauge = _delegateGauge;

		masterchefToken = IERC20(address(new MasterchefMasterToken()));
		distributionsOn = false;

		timePeriod = 3600 * 24; // One day in seconds
		lookPastDays = 45; // for past 45 days check

		_setRoleAdmin(GOVERNOR_ROLE, GOVERNOR_ROLE);
		_setRoleAdmin(GUARDIAN_ROLE, GOVERNOR_ROLE);

		_setupRole(GUARDIAN_ROLE, _guardian);
		_setupRole(GOVERNOR_ROLE, _governor);
		_setupRole(GUARDIAN_ROLE, _governor);
	}

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() initializer {}

	/// @notice Initialize the masterchef depositing the master token
	/// @param _pid pool id to deposit the token
	function initializeMasterchef(uint256 _pid) external onlyRole(GOVERNOR_ROLE) {
		masterchefPID = _pid;
		masterchefToken.approve(address(masterchef), 1e18);
		masterchef.deposit(_pid, 1e18);
	}

	////////////////////////////////////////////////////////////////
	/// --- DISTRIBUTION LOGIC
	///////////////////////////////////////////////////////////////

	/// @notice Distribute SDT to Gauges
	/// @param gaugeAddr Address of the gauge to distribute.
	function distribute(address gaugeAddr) external nonReentrant {
		_distribute(gaugeAddr);
	}

	/// @notice Distribute SDT to Multiple Gauges
	/// @param gaugeAddr Array of addresses of the gauge to distribute.
	function distributeMulti(address[] calldata gaugeAddr) public nonReentrant {
		uint256 length = gaugeAddr.length;
		for (uint256 i; i < length; i++) {
			_distribute(gaugeAddr[i]);
		}
	}

	/// @notice Internal implementation of distribute logic.
	/// @param gaugeAddr Address of the gauge to distribute rewards to
	function _distribute(address gaugeAddr) internal {
		require(distributionsOn, "not allowed");
		(bool success, bytes memory result) = address(controller).call(
			abi.encodeWithSignature("gauge_types(address)", gaugeAddr)
		);
		if (!success || killedGauges[gaugeAddr]) {
			return;
		}
		int128 gaugeType = abi.decode(result, (int128));

		// Rounded to beginning of the day -> 00:00 UTC
		uint256 roundedTimestamp = (block.timestamp / 1 days) * 1 days;

		uint256 totalDistribute;

		if (block.timestamp > lastMasterchefPull + timePeriod) {
			uint256 sdtBefore = rewardToken.balanceOf(address(this));
			_pullSDT();
			pulls[roundedTimestamp] = rewardToken.balanceOf(address(this)) - sdtBefore;
			lastMasterchefPull = roundedTimestamp;
		}
		// check past n days
		for (uint256 i; i < lookPastDays; i++) {
			uint256 currentTimestamp = roundedTimestamp - (i * 86_400);

			if (pulls[currentTimestamp] > 0) {
				bool isPaid = isGaugePaid[currentTimestamp][gaugeAddr];
				if (isPaid) {
					break;
				}

				// Retrieve the amount pulled from Masterchef at the given timestamp.
				uint256 sdtBalance = pulls[currentTimestamp];
				uint256 gaugeRelativeWeight;

				if (i == 0) {
					// Makes sure the weight is checkpointed. Also returns the weight.
					gaugeRelativeWeight = controller.gauge_relative_weight_write(gaugeAddr, currentTimestamp);
				} else {
					gaugeRelativeWeight = controller.gauge_relative_weight(gaugeAddr, currentTimestamp);
				}

				uint256 sdtDistributed = (sdtBalance * gaugeRelativeWeight) / 1e18;
				totalDistribute += sdtDistributed;
				isGaugePaid[currentTimestamp][gaugeAddr] = true;
			}
		}
		if (totalDistribute > 0) {
			if (gaugeType == 1) {
				rewardToken.safeTransfer(gaugeAddr, totalDistribute);
				IStakingRewards(gaugeAddr).notifyRewardAmount(totalDistribute);
			} else if (gaugeType >= 2) {
				// If it is defined, we use the specific delegate attached to the gauge
				address delegate = delegateGauges[gaugeAddr];
				if (delegate == address(0)) {
					// If not, we check if a delegate common to all gauges with type >= 2 can be used
					delegate = delegateGauge;
				}
				if (delegate != address(0)) {
					// In the case where the gauge has a delegate (specific or not), then rewards are transferred to this gauge
					rewardToken.safeTransfer(delegate, totalDistribute);
					// If this delegate supports a specific interface, then rewards sent are notified through this
					// interface
					if (isInterfaceKnown[delegate]) {
						ISdtMiddlemanGauge(delegate).notifyReward(gaugeAddr, totalDistribute);
					}
				} else {
					rewardToken.safeTransfer(gaugeAddr, totalDistribute);
				}
			} else {
				ILiquidityGauge(gaugeAddr).deposit_reward_token(address(rewardToken), totalDistribute);
			}

			emit RewardDistributed(gaugeAddr, totalDistribute, lastMasterchefPull);
		}
	}

	/// @notice Internal function to pull SDT from the MasterChef
	function _pullSDT() internal {
		masterchef.withdraw(masterchefPID, 0);
	}

	////////////////////////////////////////////////////////////////
	/// --- RESTRICTIVE FUNCTIONS
	///////////////////////////////////////////////////////////////

	/// @notice Sets the distribution state (on/off)
	/// @param _state new distribution state
	function setDistribution(bool _state) external onlyRole(GOVERNOR_ROLE) {
		distributionsOn = _state;
	}

	/// @notice Sets a new gauge controller
	/// @param _controller Address of the new gauge controller
	function setGaugeController(address _controller) external onlyRole(GOVERNOR_ROLE) {
		require(_controller != address(0), "0");
		controller = IGaugeController(_controller);
		emit GaugeControllerUpdated(_controller);
	}

	/// @notice Sets a new delegate gauge for pulling rewards of a type >= 2 gauges or of all type >= 2 gauges
	/// @param gaugeAddr Gauge to change the delegate of
	/// @param _delegateGauge Address of the new gauge delegate related to `gaugeAddr`
	/// @param toggleInterface Whether we should toggle the fact that the `_delegateGauge` is built for automation or not
	/// @dev This function can be used to remove delegating or introduce the pulling of rewards to a given address
	/// @dev If `gaugeAddr` is the zero address, this function updates the delegate gauge common to all gauges with type >= 2
	/// @dev The `toggleInterface` parameter has been added for convenience to save one transaction when adding a gauge delegate
	/// which supports the `notifyReward` interface
	function setDelegateGauge(
		address gaugeAddr,
		address _delegateGauge,
		bool toggleInterface
	) external onlyRole(GOVERNOR_ROLE) {
		if (gaugeAddr != address(0)) {
			delegateGauges[gaugeAddr] = _delegateGauge;
		} else {
			delegateGauge = _delegateGauge;
		}
		emit DelegateGaugeUpdated(gaugeAddr, _delegateGauge);

		if (toggleInterface) {
			_toggleInterfaceKnown(_delegateGauge);
		}
	}

	/// @notice Toggles the status of a gauge to either killed or unkilled
	/// @param gaugeAddr Gauge to toggle the status of
	/// @dev It is impossible to kill a gauge in the `GaugeController` contract, for this reason killing of gauges
	/// takes place in the `SdtDistributor` contract
	/// @dev This means that people could vote for a gauge in the gauge controller contract but that rewards are not going
	/// to be distributed to it in the end: people would need to remove their weights on the gauge killed to end the diminution
	/// in rewards
	/// @dev In the case of a gauge being killed, this function resets the timestamps at which this gauge has been approved and
	/// disapproves the gauge to spend the token
	/// @dev It should be cautiously called by governance as it could result in less SDT overall rewards than initially planned
	/// if people do not remove their voting weights to the killed gauge
	function toggleGauge(address gaugeAddr) external onlyRole(GOVERNOR_ROLE) {
		bool gaugeKilledMem = killedGauges[gaugeAddr];
		if (!gaugeKilledMem) {
			rewardToken.safeApprove(gaugeAddr, 0);
		}
		killedGauges[gaugeAddr] = !gaugeKilledMem;
		emit GaugeToggled(gaugeAddr, !gaugeKilledMem);
	}

	/// @notice Notifies that the interface of a gauge delegate is known or has changed
	/// @param _delegateGauge Address of the gauge to change
	/// @dev Gauge delegates that are built for automation should be toggled
	function toggleInterfaceKnown(address _delegateGauge) external onlyRole(GUARDIAN_ROLE) {
		_toggleInterfaceKnown(_delegateGauge);
	}

	/// @notice Toggles the fact that a gauge delegate can be used for automation or not and therefore supports
	/// the `notifyReward` interface
	/// @param _delegateGauge Address of the gauge to change
	function _toggleInterfaceKnown(address _delegateGauge) internal {
		bool isInterfaceKnownMem = isInterfaceKnown[_delegateGauge];
		isInterfaceKnown[_delegateGauge] = !isInterfaceKnownMem;
		emit InterfaceKnownToggled(_delegateGauge, !isInterfaceKnownMem);
	}

	/// @notice Gives max approvement to the gauge
	/// @param gaugeAddr Address of the gauge
	function approveGauge(address gaugeAddr) external onlyRole(GOVERNOR_ROLE) {
		rewardToken.safeApprove(gaugeAddr, type(uint256).max);
	}

	/// @notice Set the time period to pull SDT from Masterchef
	/// @param _timePeriod new timePeriod value in seconds
	function setTimePeriod(uint256 _timePeriod) external onlyRole(GOVERNOR_ROLE) {
		require(_timePeriod >= 1 days, "TOO_LOW");
		timePeriod = _timePeriod;
	}

	function setClaimerFee(uint256 _newFee) external onlyRole(GOVERNOR_ROLE) {
		require(_newFee <= BASE_UNIT, "TOO_HIGH");
		claimerFee = _newFee;
	}

	/// @notice Set the how many days we should look back for reward distribution
	/// @param _newLookPastDays new value for how many days we should look back
	function setLookPastDays(uint256 _newLookPastDays) external onlyRole(GOVERNOR_ROLE) {
		lookPastDays = _newLookPastDays;
	}

	/// @notice Withdraws ERC20 tokens that could accrue on this contract
	/// @param tokenAddress Address of the ERC20 token to withdraw
	/// @param to Address to transfer to
	/// @param amount Amount to transfer
	/// @dev Added to support recovering LP Rewards and other mistaken tokens
	/// from other systems to be distributed to holders
	/// @dev This function could also be used to recover SDT tokens in case the rate got smaller
	function recoverERC20(
		address tokenAddress,
		address to,
		uint256 amount
	) external onlyRole(GOVERNOR_ROLE) {
		IERC20(tokenAddress).safeTransfer(to, amount);
		emit Recovered(tokenAddress, to, amount);
	}
}