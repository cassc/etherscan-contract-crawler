// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISporesToken.sol";

contract SporesTokenVesting is Ownable {
	// Contract libs
	using SafeMath for uint256;
	using SafeERC20 for ISporesToken;

	// Contract events
	event Released(address indexed beneficiary, uint256 amount);

	// Vesting information struct
	struct VestingBeneficiary {
		address beneficiary;
		uint256 lockDuration;
		uint256 duration;
		uint256 amount;
		uint256 leftOverVestingAmount;
		uint256 released;
		uint256 upfrontAmount;
		uint256 startedAt;
		uint256 interval;
		uint256 lastReleasedAt;
	}

	// Spores ERC20 token
	ISporesToken public token;
	// Vesting beneficiary list
	mapping(address => VestingBeneficiary) public beneficiaries;
	address[] public beneficiaryAddresses;
	// Token deployed date
	uint256 public tokenListingDate;
	uint256 public tokenVestingCap;

	constructor(address _token, uint256 _tokenListingDate) {
		token = ISporesToken(_token);
		if (_tokenListingDate > 0) {
			tokenListingDate = _tokenListingDate;
		}
	}

	// only owner or added beneficiaries can release the vesting amount
	modifier onlyBeneficiaries() {
		require(
			owner() == _msgSender() || beneficiaries[_msgSender()].amount > 0,
			"You cannot release tokens!"
		);
		_;
	}

	/**
	 * @dev Set first day token listing on exchange for vesting process
	 */
	function setTokenListingDate(uint256 _tokenListingDate) public onlyOwner {
		require(
			_tokenListingDate >= block.timestamp,
			"Token listing must be in future date"
		);

		tokenListingDate = _tokenListingDate;

		uint256 beneficiaryCount = beneficiaryAddresses.length;
		for (uint256 i = 0; i < beneficiaryCount; i++) {
			VestingBeneficiary storage info = beneficiaries[
				beneficiaryAddresses[i]
			];

			info.startedAt = _tokenListingDate.add(info.lockDuration);
		}
	}

	/**
	 * @dev Add new beneficiary to vesting contract with some conditions.
	 */
	function addBeneficiary(
		address _beneficiary,
		uint256 _amount,
		uint256 _lockDuration,
		uint256 _duration,
		uint256 _upfrontAmount,
		uint256 _interval
	) public onlyOwner {
		require(
			_beneficiary != address(0),
			"The beneficiary's address cannot be 0"
		);

		require(_amount > 0, "Shares amount has to be greater than 0");
		require(
			tokenVestingCap.add(_amount) <= token.cap(),
			"Full token vesting to other beneficiaries. Can not add new beneficiary"
		);
		require(
			beneficiaries[_beneficiary].amount == 0,
			"The beneficiary has added to the vesting pool already"
		);

		// Add new vesting beneficiary
		uint256 _leftOverVestingAmount = _amount.sub(_upfrontAmount);
		uint256 vestingStartedAt = tokenListingDate.add(_lockDuration);
		beneficiaries[_beneficiary] = VestingBeneficiary(
			_beneficiary,
			_lockDuration,
			_duration,
			_amount,
			_leftOverVestingAmount,
			_upfrontAmount,
			_upfrontAmount,
			vestingStartedAt,
			_interval,
			0
		);

		beneficiaryAddresses.push(_beneficiary);
		tokenVestingCap = tokenVestingCap.add(_amount);

		// Transfer immediately if any upfront amount
		if (_upfrontAmount > 0) {
			emit Released(_beneficiary, _amount);
			token.safeTransfer(_beneficiary, _upfrontAmount);
		}
	}

	/**
	 * @dev Add new beneficiary list to vesting contract with some conditions.
	 * See {SporesTokenVesting-addBeneficiary}.
	 */
	function addBeneficiaries(
		address[] calldata _beneficiaries,
		uint256[] calldata _amounts,
		uint256[] calldata _lockDurations,
		uint256[] calldata _durations,
		uint256[] calldata _upfrontAmounts,
		uint256[] calldata _intervals
	) external onlyOwner {
		require(
			_beneficiaries.length > 0,
			"Empty list of beneficiaries is not allowed"
		);

		require(
			_beneficiaries.length == _amounts.length &&
				_beneficiaries.length == _lockDurations.length &&
				_beneficiaries.length == _durations.length &&
				_beneficiaries.length == _upfrontAmounts.length &&
				_beneficiaries.length == _intervals.length,
			"Incorrect arrays length. Ensure all arrays has the same length"
		);

		for (uint256 i = 0; i < _beneficiaries.length; i++) {
			addBeneficiary(
				_beneficiaries[i],
				_amounts[i],
				_lockDurations[i],
				_durations[i],
				_upfrontAmounts[i],
				_intervals[i]
			);
		}
	}

	/**
	 * @dev Get new vested amount of beneficiary base on vesting schedule of this beneficiary.
	 */
	function releasableAmount(address _beneficiary)
		public
		view
		returns (
			uint256,
			uint256,
			uint256
		)
	{
		VestingBeneficiary memory info = beneficiaries[_beneficiary];
		if (info.amount == 0) {
			return (0, 0, block.timestamp);
		}

		(uint256 _vestedAmount, uint256 _lastIntervalDate) = vestedAmount(
			_beneficiary
		);

		return (
			_vestedAmount,
			_vestedAmount.sub(info.released),
			_lastIntervalDate
		);
	}

	/**
	 * @dev Get total vested amount of beneficiary base on vesting schedule of this beneficiary.
	 */
	function vestedAmount(address _beneficiary)
		public
		view
		returns (uint256, uint256)
	{
		VestingBeneficiary memory info = beneficiaries[_beneficiary];
		require(info.amount > 0, "The beneficiary's address cannot be found");
		// Listing date is not set
		if (info.startedAt == 0) {
			return (info.released, info.lastReleasedAt);
		}

		// No vesting (All amount unlock at the TGE)
		if (info.duration == 0) {
			return (
				info.amount,
				info.startedAt
			);
		}

		// Vesting has not started yet
		if (block.timestamp < info.startedAt) {
			return (info.released, info.lastReleasedAt);
		}

		// Vesting is done
		if (block.timestamp >= info.startedAt.add(info.duration)) {
			return (info.amount, info.startedAt.add(info.duration));
		}

		// It's too soon to next release
		if (
			info.lastReleasedAt > 0 &&
			block.timestamp - info.interval < info.lastReleasedAt
		) {
			return (info.released, info.lastReleasedAt);
		}

		// Vesting is interval counter
		uint256 totalVestedAmount = info.released;
		uint256 lastIntervalDate = info.lastReleasedAt > 0
			? info.lastReleasedAt
			: info.startedAt;

		uint256 multiplyIntervals;
		while (block.timestamp >= lastIntervalDate.add(info.interval)) {
			multiplyIntervals = multiplyIntervals.add(1);
			lastIntervalDate = lastIntervalDate.add(info.interval);
		}

		if (multiplyIntervals > 0) {
			uint256 newVestedAmount = info
				.leftOverVestingAmount
				.mul(multiplyIntervals.mul(info.interval))
				.div(info.duration);

			totalVestedAmount = totalVestedAmount.add(newVestedAmount);
		}

		return (totalVestedAmount, lastIntervalDate);
	}

	/**
	 * @dev Release vested tokens to a specified beneficiary.
	 */
	function releaseTo(
		address _beneficiary,
		uint256 _amount,
		uint256 _lastIntervalDate
	) internal returns (bool) {
		VestingBeneficiary storage info = beneficiaries[_beneficiary];
		if (block.timestamp < _lastIntervalDate) {
			return false;
		}
		// Update beneficiary information
		info.released = info.released.add(_amount);
		info.lastReleasedAt = _lastIntervalDate;

		// Emit event to of new release
		emit Released(_beneficiary, _amount);
		// Transfer new released amount to vesting beneficiary
		token.safeTransfer(_beneficiary, _amount);
		return true;
	}

	/**
	 * @dev Release vested tokens to a all beneficiaries.
	 */
	function releaseBeneficiaryTokens() public onlyOwner {
		// Get current vesting beneficiaries
		uint256 beneficiariesCount = beneficiaryAddresses.length;
		for (uint256 i = 0; i < beneficiariesCount; i++) {
			// Calculate the releasable amount
			(
				,
				uint256 _newReleaseAmount,
				uint256 _lastIntervalDate
			) = releasableAmount(beneficiaryAddresses[i]);

			// Release new vested token to the beneficiary
			if (_newReleaseAmount > 0) {
				releaseTo(
					beneficiaryAddresses[i],
					_newReleaseAmount,
					_lastIntervalDate
				);
			}
		}
	}

	/**
	 * @dev Release vested tokens to current beneficiary.
	 */
	function releaseMyTokens() public onlyBeneficiaries {
		// Calculate the releasable amount
		(
			,
			uint256 _newReleaseAmount,
			uint256 _lastIntervalDate
		) = releasableAmount(_msgSender());

		// Release new vested token to the beneficiary
		if (_newReleaseAmount > 0) {
			releaseTo(_msgSender(), _newReleaseAmount, _lastIntervalDate);
		}
	}
}