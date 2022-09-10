// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

error EquityPool__TotalValueGreaterThan100M();
error EquityPool__StakeIsZero();
error EquityPool__TransactionFailed();
error EquityPool__InsufficientBalance();
error EquityPool__ContractUpdateWindowIsOpen();
error EquityPool__ContractUpdateWindowIsNotOpen();
error EquityPool__StakeHolderDoesNotExist();
error EquityPool__StakeHolderAlreadyExists();

/// @title A pool to distribute funds to beneficiaries.
/// @dev There are total of 100,000,000 Equity Tokens "EQT".
/// @custom:security-contact [email protected]
contract EquityPool is Pausable, AccessControl, ReentrancyGuard {
	using SafeMath for uint256;

	// FundsReceived event is triggered when funds are recieved to the contract
	event FundsReceived(address indexed addr, uint256 amount);

	// FundsDistributed is triggered when funds are distributed from the contract
	event FundsDistributed(
		address stakeholder,
		uint256 amount,
		uint256 time_distributed
	);

	// StakeHolderAdded is triggered when a new stakeholder is added to the contract
	event StakeHolderAdded(
		address holder,
		uint256 equityTokens,
		uint256 timeAdded
	);

	// StakeHolderStakeIncreased is triggered when an existing stakeholder equity is increased
	event StakeHolderStakeIncreased(
		address holder,
		uint256 equityTokens,
		uint256 timeAdded
	);

	// Roles
	bytes32 public constant PAUSER_ROLE = keccak256('PAUSER_ROLE');
	bytes32 public constant MANAGER_ROLE = keccak256('MANAGER_ROLE');

	// Equity Stake struct encapsulates an equity stake for a specific stakeholder
	struct Stake {
		uint256 equityTokens;
		uint256 fundsLastReceived;
		uint256 equityLastUpdated;
	}

	// list of addresses that are stakeholders
	address[] public stakeHolderAddresses;

	// stakeHolder is a mapping from address to Stake of current stake holders
	mapping(address => Stake) public stakeHolders;

	// the address of the impact3 treasury fund
	address payable public impact3FundAddress;

	// intervalSeconds is the number of seconds of the update windows ie 30 days
	uint256 public immutable intervalSeconds;
	// updateWindowSeconds is number of seconds the interval of each update ie 7 days
	uint256 public immutable updateWindowSeconds;

	// lastEndOfWindowTimestamp is the last time stamp of when the interval ended in seconds
	uint256 public lastEndOfIntervalTimestamp;

	constructor(
		address _i3Fund,
		uint256 _interval,
		uint256 _window
	) {
		// grant roles to deployer address
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_grantRole(PAUSER_ROLE, msg.sender);
		_grantRole(MANAGER_ROLE, msg.sender);

		// set the i3Fund address
		setImpact3FundAddress(_i3Fund);

		// set the interval and window and current end of interval timestamp
		intervalSeconds = _interval;
		updateWindowSeconds = _window;
		lastEndOfIntervalTimestamp = block.timestamp;
	}

	/// @notice Distrbute funds to stakeholders and remainder to Impact3 fund
	function distributeFunds() public whenNotPaused nonReentrant {
		if (withinUpdateWindow()) {
			revert EquityPool__ContractUpdateWindowIsOpen();
		}

		uint256 fundsToDistribute = address(this).balance;
		uint256 fundsDistributed = 0;

		address[] memory currentHolderAddresses = stakeHolderAddresses;
		for (uint256 i = 0; i < currentHolderAddresses.length; i++) {
			// calculate amount to distribute
			uint256 equityTokens = stakeHolders[currentHolderAddresses[i]]
				.equityTokens;
			uint256 amount = fundsToDistribute.mul(equityTokens).div((10**8));

			// update funds last received with timestamp
			stakeHolders[currentHolderAddresses[i]].fundsLastReceived = block
				.timestamp;
			fundsDistributed += amount;

			// send value to stake holder
			sendValue(payable(stakeHolderAddresses[i]), amount);
			emit FundsDistributed(
				stakeHolderAddresses[i],
				amount,
				block.timestamp
			);
		}

		// update last timestamp with previous timestamp plus interval
		(, uint256 _closetimestamp) = getUpdateWindow();
		if (block.timestamp >= _closetimestamp) {
			lastEndOfIntervalTimestamp += intervalSeconds;
		} else {
			lastEndOfIntervalTimestamp = lastEndOfIntervalTimestamp;
		}

		// send remaining funds to impact 3 fund address
		sendValue(impact3FundAddress, address(this).balance);
		emit FundsDistributed(
			impact3FundAddress,
			fundsDistributed,
			block.timestamp
		);
	}

	/// @notice Updates an existing stakeholder with a specific stake increase
	/// @param _holder The address of the existing stakeholder
	/// @param _stakeIncrease The amount to increase the equity tokens by
	function updateStakeHolder(address _holder, uint256 _stakeIncrease)
		public
		whenNotPaused
		onlyRole(MANAGER_ROLE)
	{
		// only continue if the update window is open
		if (!withinUpdateWindow()) {
			revert EquityPool__ContractUpdateWindowIsNotOpen();
		}

		// check if the stake is zero
		if (_stakeIncrease <= 0) {
			revert EquityPool__StakeIsZero();
		}

		// check if the new total stake is greater than 100m
		uint256 newTotalStake = totalStake(stakeHolderAddresses).add(
			_stakeIncrease
		);
		if (newTotalStake > (10**8)) {
			revert EquityPool__TotalValueGreaterThan100M();
		}

		// check if stake holder exists
		if (stakeHolders[_holder].equityTokens <= 0) {
			revert EquityPool__StakeHolderDoesNotExist();
		}

		// Updating equities of existing stakeholders
		uint256 newStake = stakeHolders[_holder].equityTokens.add(
			_stakeIncrease
		);
		stakeHolders[_holder].equityTokens = newStake;
		stakeHolders[_holder].equityLastUpdated = block.timestamp;

		// emit stake holder stake increased event
		emit StakeHolderStakeIncreased(
			_holder,
			_stakeIncrease,
			block.timestamp
		);
	}

	/// @notice Adds a new stakeholder with an initial stake
	/// @param _holder The address of the existing stakeholder
	/// @param _initialStake The amount to initialise the preportion of the stake
	function addStakeHolder(address _holder, uint256 _initialStake)
		public
		whenNotPaused
		onlyRole(MANAGER_ROLE)
	{
		// only continue if the update window is open
		if (!withinUpdateWindow()) {
			revert EquityPool__ContractUpdateWindowIsNotOpen();
		}

		// check if the stake is zero
		if (_initialStake <= 0) {
			revert EquityPool__StakeIsZero();
		}

		// check if the new total stake is greater than 100m
		uint256 newTotalStake = totalStake(stakeHolderAddresses).add(
			_initialStake
		);
		if (newTotalStake > (10**8)) {
			revert EquityPool__TotalValueGreaterThan100M();
		}

		// check if stake holder already exists
		if (stakeHolders[_holder].equityTokens != 0) {
			revert EquityPool__StakeHolderAlreadyExists();
		}

		// add stake holder to mapping
		stakeHolders[_holder] = Stake(
			_initialStake,
			block.timestamp,
			block.timestamp
		);
		stakeHolderAddresses.push(_holder);

		// emit stake holder added map
		emit StakeHolderAdded(_holder, _initialStake, block.timestamp);
	}

	/// @notice Updates the Impact 3 fund address
	/// @param fund The new address of the Impact 3 fund
	function setImpact3FundAddress(address fund) public onlyRole(MANAGER_ROLE) {
		impact3FundAddress = payable(fund);
	}

	/// @notice Calculates the total stake preportions of all stakeholders
	/// @param _currentHolders The addresses of the current stake holders
	function totalStake(address[] memory _currentHolders)
		internal
		view
		returns (uint256)
	{
		uint256 _totalStake = 0;
		for (uint256 i = 0; i < _currentHolders.length; i++) {
			_totalStake += stakeHolders[_currentHolders[i]].equityTokens;
		}
		return _totalStake;
	}

	/// @notice Returns whether we are within the update window
	/// @return isOpen Whether the window to update or add new stakeholders is open
	function withinUpdateWindow() public view returns (bool) {
		(uint256 _opentimestamp, uint256 _closetimestamp) = getUpdateWindow();

		if (
			block.timestamp >= _opentimestamp &&
			block.timestamp < _closetimestamp
		) {
			return true;
		}

		return false;
	}

	/// @notice Calculates the update window intervals
	/// @return openTimestamp The opening timestamp of the update window
	/// @return closeTimestamp The closing timestamp of the update window
	function getUpdateWindow() public view returns (uint256, uint256) {
		uint256 _opentimestamp = lastEndOfIntervalTimestamp + intervalSeconds;
		uint256 _closetimestamp = lastEndOfIntervalTimestamp +
			(intervalSeconds + updateWindowSeconds);
		return (_opentimestamp, _closetimestamp);
	}

	/// @notice Pauses the contract so no interactions can be made
	function pause() public onlyRole(PAUSER_ROLE) {
		_pause();
	}

	/// @notice Unpauses the contract so interactions can be made
	function unpause() public onlyRole(PAUSER_ROLE) {
		_unpause();
	}

	/// @notice When funds are received by the contract we emit an event
	receive() external payable {
		emit FundsReceived(msg.sender, msg.value);
	}

	/// @notice Sends an address funds from this contract
	/// @param recipient The address to send funds to
	/// @param amount The amount of funds to send
	function sendValue(address payable recipient, uint256 amount) internal {
		if (address(this).balance < amount) {
			revert EquityPool__InsufficientBalance();
		}

		(bool success, ) = recipient.call{ value: amount }('');
		if (!success) {
			revert EquityPool__TransactionFailed();
		}
	}

	/// @notice Gets all stakeholders of the contract as well as their stake
	/// @return _holders An array of addresses of the stakeholders
	/// @return _equityTokens An array of equity tokens
	function getStakeHolders()
		external
		view
		returns (address[] memory _holders, uint256[] memory _equityTokens)
	{
		_holders = new address[](stakeHolderAddresses.length);
		_holders = stakeHolderAddresses;

		_equityTokens = new uint256[](_holders.length);
		for (uint256 i = 0; i < _holders.length; i++) {
			_equityTokens[i] = stakeHolders[_holders[i]].equityTokens;
		}

		return (_holders, _equityTokens);
	}

	/// @notice Checks whether a specific address is a stakeholder of the contract
	/// @param _holder The address of the stakeholder ot check
	/// @return isStakeHolder whether or not the address is a stakeholder
	function isStakeHolder(address _holder) external view returns (bool) {
		if (stakeHolders[_holder].equityTokens <= 0) {
			return false;
		}
		return true;
	}
}