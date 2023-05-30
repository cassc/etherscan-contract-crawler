pragma solidity 0.5.17;

// prettier-ignore
import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ISTokensManager} from "@devprotocol/i-s-tokens/contracts/interface/ISTokensManager.sol";
import "../common/libs/Decimals.sol";
import "../common/config/UsingConfig.sol";
import "../lockup/LockupStorage.sol";
import "../../interface/IDev.sol";
import "../../interface/IDevMinter.sol";
import "../../interface/IProperty.sol";
import "../../interface/IPolicy.sol";
import "../../interface/IAllocator.sol";
import "../../interface/ILockup.sol";
import "../../interface/IMetricsGroup.sol";

/**
 * A contract that manages the staking of DEV tokens and calculates rewards.
 * Staking and the following mechanism determines that reward calculation.
 *
 * Variables:
 * -`M`: Maximum mint amount per block determined by Allocator contract
 * -`B`: Number of blocks during staking
 * -`P`: Total number of staking locked up in a Property contract
 * -`S`: Total number of staking locked up in all Property contracts
 * -`U`: Number of staking per account locked up in a Property contract
 *
 * Formula:
 * Staking Rewards = M * B * (P / S) * (U / P)
 *
 * Note:
 * -`M`, `P` and `S` vary from block to block, and the variation cannot be predicted.
 * -`B` is added every time the Ethereum block is created.
 * - Only `U` and `B` are predictable variables.
 * - As `M`, `P` and `S` cannot be observed from a staker, the "cumulative sum" is often used to calculate ratio variation with history.
 * - Reward withdrawal always withdraws the total withdrawable amount.
 *
 * Scenario:
 * - Assume `M` is fixed at 500
 * - Alice stakes 100 DEV on Property-A (Alice's staking state on Property-A: `M`=500, `B`=0, `P`=100, `S`=100, `U`=100)
 * - After 10 blocks, Bob stakes 60 DEV on Property-B (Alice's staking state on Property-A: `M`=500, `B`=10, `P`=100, `S`=160, `U`=100)
 * - After 10 blocks, Carol stakes 40 DEV on Property-A (Alice's staking state on Property-A: `M`=500, `B`=20, `P`=140, `S`=200, `U`=100)
 * - After 10 blocks, Alice withdraws Property-A staking reward. The reward at this time is 5000 DEV (10 blocks * 500 DEV) + 3125 DEV (10 blocks * 62.5% * 500 DEV) + 2500 DEV (10 blocks * 50% * 500 DEV).
 */
contract Lockup is ILockup, UsingConfig, LockupStorage {
	using SafeMath for uint256;
	using Decimals for uint256;
	address public devMinter;
	address public sTokensManager;
	struct RewardPrices {
		uint256 reward;
		uint256 holders;
		uint256 interest;
		uint256 holdersCap;
	}
	event Lockedup(address _from, address _property, uint256 _value);
	event UpdateCap(uint256 _cap);

	/**
	 * Initialize the passed address as AddressConfig address and Devminter.
	 */
	constructor(
		address _config,
		address _devMinter,
		address _sTokensManager
	) public UsingConfig(_config) {
		devMinter = _devMinter;
		sTokensManager = _sTokensManager;
	}

	/**
	 * @dev Validates the passed Property has greater than 1 asset.
	 * @param _property property address
	 */
	modifier onlyAuthenticatedProperty(address _property) {
		require(
			IMetricsGroup(config().metricsGroup()).hasAssets(_property),
			"unable to stake to unauthenticated property"
		);
		_;
	}

	/**
	 * @dev Check if the owner of the token is a sender.
	 * @param _tokenId The ID of the staking position
	 */
	modifier onlyPositionOwner(uint256 _tokenId) {
		require(
			IERC721(sTokensManager).ownerOf(_tokenId) == msg.sender,
			"illegal sender"
		);
		_;
	}

	/**
	 * @dev deposit dev token to dev protocol and generate s-token
	 * @param _property target property address
	 * @param _amount staking value
	 * @return tokenId The ID of the created new staking position
	 */
	function depositToProperty(address _property, uint256 _amount)
		external
		returns (uint256)
	{
		return _implDepositToProperty(_property, _amount, "");
	}

	/**
	 * @dev deposit dev token to dev protocol and generate s-token
	 * @param _property target property address
	 * @param _amount staking value
	 * @param _payload additional bytes for s-token
	 * @return tokenId The ID of the created new staking position
	 */
	function depositToProperty(
		address _property,
		uint256 _amount,
		bytes32 _payload
	) external returns (uint256) {
		return _implDepositToProperty(_property, _amount, _payload);
	}

	function _implDepositToProperty(
		address _property,
		uint256 _amount,
		bytes32 _payload
	) private onlyAuthenticatedProperty(_property) returns (uint256) {
		/**
		 * Gets the latest cumulative sum of the interest price.
		 */
		(
			uint256 reward,
			uint256 holders,
			uint256 interest,
			uint256 holdersCap
		) = calculateCumulativeRewardPrices();
		/**
		 * Saves variables that should change due to the addition of staking.
		 */
		updateValues(
			true,
			_property,
			_amount,
			RewardPrices(reward, holders, interest, holdersCap)
		);
		/**
		 * transfer dev tokens
		 */
		require(
			IERC20(config().token()).transferFrom(
				msg.sender,
				_property,
				_amount
			),
			"dev transfer failed"
		);
		/**
		 * mint s tokens
		 */
		uint256 tokenId = ISTokensManager(sTokensManager).mint(
			msg.sender,
			_property,
			_amount,
			interest,
			_payload
		);
		emit Lockedup(msg.sender, _property, _amount);
		return tokenId;
	}

	/**
	 * @dev deposit dev token to dev protocol and update s-token status
	 * @param _tokenId s-token id
	 * @param _amount staking value
	 * @return bool On success, true will be returned
	 */
	function depositToPosition(uint256 _tokenId, uint256 _amount)
		external
		onlyPositionOwner(_tokenId)
		returns (bool)
	{
		/**
		 * Validates _amount is not 0.
		 */
		require(_amount != 0, "illegal deposit amount");
		ISTokensManager sTokenManagerInstance = ISTokensManager(sTokensManager);
		/**
		 * get position information
		 */
		(
			address property,
			uint256 amount,
			uint256 price,
			uint256 cumulativeReward,
			uint256 pendingReward
		) = sTokenManagerInstance.positions(_tokenId);
		/**
		 * Gets the withdrawable amount.
		 */
		(
			uint256 withdrawable,
			RewardPrices memory prices
		) = _calculateWithdrawableInterestAmount(
				property,
				amount,
				price,
				pendingReward
			);
		/**
		 * Saves variables that should change due to the addition of staking.
		 */
		updateValues(true, property, _amount, prices);
		/**
		 * transfer dev tokens
		 */
		require(
			IERC20(config().token()).transferFrom(
				msg.sender,
				property,
				_amount
			),
			"dev transfer failed"
		);
		/**
		 * update position information
		 */
		bool result = sTokenManagerInstance.update(
			_tokenId,
			amount.add(_amount),
			prices.interest,
			cumulativeReward.add(withdrawable),
			pendingReward.add(withdrawable)
		);
		require(result, "failed to update");
		/**
		 * generate events
		 */
		emit Lockedup(msg.sender, property, _amount);
		return true;
	}

	/**
	 * Adds staking.
	 * Only the Dev contract can execute this function.
	 */
	function lockup(
		address _from,
		address _property,
		uint256 _value
	) external onlyAuthenticatedProperty(_property) {
		/**
		 * Validates the sender is Dev contract.
		 */
		require(msg.sender == config().token(), "this is illegal address");

		/**
		 * Validates _value is not 0.
		 */
		require(_value != 0, "illegal lockup value");

		/**
		 * Since the reward per block that can be withdrawn will change with the addition of staking,
		 * saves the undrawn withdrawable reward before addition it.
		 */
		RewardPrices memory prices = updatePendingInterestWithdrawal(
			_property,
			_from
		);

		/**
		 * Saves variables that should change due to the addition of staking.
		 */
		updateValues4Legacy(true, _from, _property, _value, prices);

		emit Lockedup(_from, _property, _value);
	}

	/**
	 * Withdraw staking.(NFT)
	 * Releases staking, withdraw rewards, and transfer the staked and withdraw rewards amount to the sender.
	 */
	function withdrawByPosition(uint256 _tokenId, uint256 _amount)
		external
		onlyPositionOwner(_tokenId)
		returns (bool)
	{
		ISTokensManager sTokenManagerInstance = ISTokensManager(sTokensManager);
		/**
		 * get position information
		 */
		(
			address property,
			uint256 amount,
			uint256 price,
			uint256 cumulativeReward,
			uint256 pendingReward
		) = sTokenManagerInstance.positions(_tokenId);
		/**
		 * If the balance of the withdrawal request is bigger than the balance you are staking
		 */
		require(amount >= _amount, "insufficient tokens staked");
		/**
		 * Withdraws the staking reward
		 */
		(uint256 value, RewardPrices memory prices) = _withdrawInterest(
			property,
			amount,
			price,
			pendingReward
		);
		/**
		 * Transfer the staked amount to the sender.
		 */
		if (_amount != 0) {
			IProperty(property).withdraw(msg.sender, _amount);
		}
		/**
		 * Saves variables that should change due to the canceling staking..
		 */
		updateValues(false, property, _amount, prices);
		uint256 cumulative = cumulativeReward.add(value);
		/**
		 * update position information
		 */
		return
			sTokenManagerInstance.update(
				_tokenId,
				amount.sub(_amount),
				prices.interest,
				cumulative,
				0
			);
	}

	/**
	 * Withdraw staking.
	 * Releases staking, withdraw rewards, and transfer the staked and withdraw rewards amount to the sender.
	 */
	function withdraw(address _property, uint256 _amount) external {
		/**
		 * Validates the sender is staking to the target Property.
		 */
		require(
			hasValue(_property, msg.sender, _amount),
			"insufficient tokens staked"
		);

		/**
		 * Withdraws the staking reward
		 */
		RewardPrices memory prices = _withdrawInterest4Legacy(_property);

		/**
		 * Transfer the staked amount to the sender.
		 */
		if (_amount != 0) {
			IProperty(_property).withdraw(msg.sender, _amount);
		}

		/**
		 * Saves variables that should change due to the canceling staking..
		 */
		updateValues4Legacy(false, msg.sender, _property, _amount, prices);
	}

	/**
	 * get cap
	 */
	function cap() external view returns (uint256) {
		return getStorageCap();
	}

	/**
	 * set cap
	 */
	function updateCap(uint256 _cap) external {
		address setter = IPolicy(config().policy()).capSetter();
		require(setter == msg.sender, "illegal access");

		/**
		 * Updates cumulative amount of the holders reward cap
		 */
		(
			,
			uint256 holdersPrice,
			,
			uint256 cCap
		) = calculateCumulativeRewardPrices();

		// TODO: When this function is improved to be called on-chain, the source of `getStorageLastCumulativeHoldersPriceCap` can be rewritten to `getStorageLastCumulativeHoldersRewardPrice`.
		setStorageCumulativeHoldersRewardCap(cCap);
		setStorageLastCumulativeHoldersPriceCap(holdersPrice);
		setStorageCap(_cap);
		emit UpdateCap(_cap);
	}

	/**
	 * Returns the latest cap
	 */
	function _calculateLatestCap(uint256 _holdersPrice)
		private
		view
		returns (uint256)
	{
		uint256 cCap = getStorageCumulativeHoldersRewardCap();
		uint256 lastHoldersPrice = getStorageLastCumulativeHoldersPriceCap();
		uint256 additionalCap = _holdersPrice.sub(lastHoldersPrice).mul(
			getStorageCap()
		);
		return cCap.add(additionalCap);
	}

	/**
	 * Store staking states as a snapshot.
	 */
	function beforeStakesChanged(address _property, RewardPrices memory _prices)
		private
	{
		/**
		 * Gets latest cumulative holders reward for the passed Property.
		 */
		uint256 cHoldersReward = _calculateCumulativeHoldersRewardAmount(
			_prices.holders,
			_property
		);

		/**
		 * Sets `InitialCumulativeHoldersRewardCap`.
		 * Records this value only when the "first staking to the passed Property" is transacted.
		 */
		if (
			getStorageLastCumulativeHoldersRewardPricePerProperty(_property) ==
			0 &&
			getStorageInitialCumulativeHoldersRewardCap(_property) == 0 &&
			getStoragePropertyValue(_property) == 0
		) {
			setStorageInitialCumulativeHoldersRewardCap(
				_property,
				_prices.holdersCap
			);
		}

		/**
		 * Store each value.
		 */
		setStorageLastStakesChangedCumulativeReward(_prices.reward);
		setStorageLastCumulativeHoldersRewardPrice(_prices.holders);
		setStorageLastCumulativeInterestPrice(_prices.interest);
		setStorageLastCumulativeHoldersRewardAmountPerProperty(
			_property,
			cHoldersReward
		);
		setStorageLastCumulativeHoldersRewardPricePerProperty(
			_property,
			_prices.holders
		);
		setStorageCumulativeHoldersRewardCap(_prices.holdersCap);
		setStorageLastCumulativeHoldersPriceCap(_prices.holders);
	}

	/**
	 * Gets latest value of cumulative sum of the reward amount, cumulative sum of the holders reward per stake, and cumulative sum of the stakers reward per stake.
	 */
	function calculateCumulativeRewardPrices()
		public
		view
		returns (
			uint256 _reward,
			uint256 _holders,
			uint256 _interest,
			uint256 _holdersCap
		)
	{
		uint256 lastReward = getStorageLastStakesChangedCumulativeReward();
		uint256 lastHoldersPrice = getStorageLastCumulativeHoldersRewardPrice();
		uint256 lastInterestPrice = getStorageLastCumulativeInterestPrice();
		uint256 allStakes = getStorageAllValue();

		/**
		 * Gets latest cumulative sum of the reward amount.
		 */
		(uint256 reward, ) = dry();
		uint256 mReward = reward.mulBasis();

		/**
		 * Calculates reward unit price per staking.
		 * Later, the last cumulative sum of the reward amount is subtracted because to add the last recorded holder/staking reward.
		 */
		uint256 price = allStakes > 0
			? mReward.sub(lastReward).div(allStakes)
			: 0;

		/**
		 * Calculates the holders reward out of the total reward amount.
		 */
		uint256 holdersShare = IPolicy(config().policy()).holdersShare(
			price,
			allStakes
		);

		/**
		 * Calculates and returns each reward.
		 */
		uint256 holdersPrice = holdersShare.add(lastHoldersPrice);
		uint256 interestPrice = price.sub(holdersShare).add(lastInterestPrice);
		uint256 cCap = _calculateLatestCap(holdersPrice);
		return (mReward, holdersPrice, interestPrice, cCap);
	}

	/**
	 * Calculates cumulative sum of the holders reward per Property.
	 * To save computing resources, it receives the latest holder rewards from a caller.
	 */
	function _calculateCumulativeHoldersRewardAmount(
		uint256 _holdersPrice,
		address _property
	) private view returns (uint256) {
		(uint256 cHoldersReward, uint256 lastReward) = (
			getStorageLastCumulativeHoldersRewardAmountPerProperty(_property),
			getStorageLastCumulativeHoldersRewardPricePerProperty(_property)
		);

		/**
		 * `cHoldersReward` contains the calculation of `lastReward`, so subtract it here.
		 */
		uint256 additionalHoldersReward = _holdersPrice.sub(lastReward).mul(
			getStoragePropertyValue(_property)
		);

		/**
		 * Calculates and returns the cumulative sum of the holder reward by adds the last recorded holder reward and the latest holder reward.
		 */
		return cHoldersReward.add(additionalHoldersReward);
	}

	/**
	 * Calculates cumulative sum of the holders reward per Property.
	 * caution!!!this function is deprecated!!!
	 * use calculateRewardAmount
	 */
	function calculateCumulativeHoldersRewardAmount(address _property)
		external
		view
		returns (uint256)
	{
		(, uint256 holders, , ) = calculateCumulativeRewardPrices();
		return _calculateCumulativeHoldersRewardAmount(holders, _property);
	}

	/**
	 * Calculates holders reward and cap per Property.
	 */
	function calculateRewardAmount(address _property)
		external
		view
		returns (uint256, uint256)
	{
		(
			,
			uint256 holders,
			,
			uint256 holdersCap
		) = calculateCumulativeRewardPrices();
		uint256 initialCap = _getInitialCap(_property);

		/**
		 * Calculates the cap
		 */
		uint256 capValue = holdersCap.sub(initialCap);
		return (
			_calculateCumulativeHoldersRewardAmount(holders, _property),
			capValue
		);
	}

	function _getInitialCap(address _property) private view returns (uint256) {
		uint256 initialCap = getStorageInitialCumulativeHoldersRewardCap(
			_property
		);
		if (initialCap > 0) {
			return initialCap;
		}

		// Fallback when there is a data past staked.
		if (
			getStorageLastCumulativeHoldersRewardPricePerProperty(_property) >
			0 ||
			getStoragePropertyValue(_property) > 0
		) {
			return getStorageFallbackInitialCumulativeHoldersRewardCap();
		}
		return 0;
	}

	/**
	 * Updates cumulative sum of the maximum mint amount calculated by Allocator contract, the latest maximum mint amount per block,
	 * and the last recorded block number.
	 * The cumulative sum of the maximum mint amount is always added.
	 * By recording that value when the staker last stakes, the difference from the when the staker stakes can be calculated.
	 */
	function update() public {
		/**
		 * Gets the cumulative sum of the maximum mint amount and the maximum mint number per block.
		 */
		(uint256 _nextRewards, uint256 _amount) = dry();

		/**
		 * Records each value and the latest block number.
		 */
		setStorageCumulativeGlobalRewards(_nextRewards);
		setStorageLastSameRewardsAmountAndBlock(_amount, block.number);
	}

	/**
	 * Referring to the values recorded in each storage to returns the latest cumulative sum of the maximum mint amount and the latest maximum mint amount per block.
	 */
	function dry()
		private
		view
		returns (uint256 _nextRewards, uint256 _amount)
	{
		/**
		 * Gets the latest mint amount per block from Allocator contract.
		 */
		uint256 rewardsAmount = IAllocator(config().allocator())
			.calculateMaxRewardsPerBlock();

		/**
		 * Gets the maximum mint amount per block, and the last recorded block number from `LastSameRewardsAmountAndBlock` storage.
		 */
		(
			uint256 lastAmount,
			uint256 lastBlock
		) = getStorageLastSameRewardsAmountAndBlock();

		/**
		 * If the recorded maximum mint amount per block and the result of the Allocator contract are different,
		 * the result of the Allocator contract takes precedence as a maximum mint amount per block.
		 */
		uint256 lastMaxRewards = lastAmount == rewardsAmount
			? rewardsAmount
			: lastAmount;

		/**
		 * Calculates the difference between the latest block number and the last recorded block number.
		 */
		uint256 blocks = lastBlock > 0 ? block.number.sub(lastBlock) : 0;

		/**
		 * Adds the calculated new cumulative maximum mint amount to the recorded cumulative maximum mint amount.
		 */
		uint256 additionalRewards = lastMaxRewards.mul(blocks);
		uint256 nextRewards = getStorageCumulativeGlobalRewards().add(
			additionalRewards
		);

		/**
		 * Returns the latest theoretical cumulative sum of maximum mint amount and maximum mint amount per block.
		 */
		return (nextRewards, rewardsAmount);
	}

	/**
	 * Returns the staker reward as interest.
	 */
	function _calculateInterestAmount(uint256 _amount, uint256 _price)
		private
		view
		returns (
			uint256 amount_,
			uint256 interestPrice_,
			RewardPrices memory prices_
		)
	{
		/**
		 * Gets the latest cumulative sum of the interest price.
		 */
		(
			uint256 reward,
			uint256 holders,
			uint256 interest,
			uint256 holdersCap
		) = calculateCumulativeRewardPrices();

		/**
		 * Calculates and returns the latest withdrawable reward amount from the difference.
		 */
		uint256 result = interest >= _price
			? interest.sub(_price).mul(_amount).divBasis()
			: 0;
		return (
			result,
			interest,
			RewardPrices(reward, holders, interest, holdersCap)
		);
	}

	/**
	 * Returns the staker reward as interest.
	 */
	function _calculateInterestAmount4Legacy(address _property, address _user)
		private
		view
		returns (
			uint256 _amount,
			uint256 _interestPrice,
			RewardPrices memory _prices
		)
	{
		/**
		 * Get the amount the user is staking for the Property.
		 */
		uint256 lockedUpPerAccount = getStorageValue(_property, _user);

		/**
		 * Gets the cumulative sum of the interest price recorded the last time you withdrew.
		 */
		uint256 lastInterest = getStorageLastStakedInterestPrice(
			_property,
			_user
		);

		/**
		 * Gets the latest cumulative sum of the interest price.
		 */
		(
			uint256 reward,
			uint256 holders,
			uint256 interest,
			uint256 holdersCap
		) = calculateCumulativeRewardPrices();

		/**
		 * Calculates and returns the latest withdrawable reward amount from the difference.
		 */
		uint256 result = interest >= lastInterest
			? interest.sub(lastInterest).mul(lockedUpPerAccount).divBasis()
			: 0;
		return (
			result,
			interest,
			RewardPrices(reward, holders, interest, holdersCap)
		);
	}

	/**
	 * Returns the total rewards currently available for withdrawal. (For calling from inside the contract)
	 */
	function _calculateWithdrawableInterestAmount(
		address _property,
		uint256 _amount,
		uint256 _price,
		uint256 _pendingReward
	) private view returns (uint256 amount_, RewardPrices memory prices_) {
		/**
		 * If the passed Property has not authenticated, returns always 0.
		 */
		if (
			IMetricsGroup(config().metricsGroup()).hasAssets(_property) == false
		) {
			(
				uint256 reward,
				uint256 holders,
				uint256 interest,
				uint256 holdersCap
			) = calculateCumulativeRewardPrices();
			return (0, RewardPrices(reward, holders, interest, holdersCap));
		}

		/**
		 * Gets the latest withdrawal reward amount.
		 */
		(
			uint256 amount,
			,
			RewardPrices memory prices
		) = _calculateInterestAmount(_amount, _price);

		/**
		 * Returns the sum of all values.
		 */
		uint256 withdrawableAmount = amount.add(_pendingReward);
		return (withdrawableAmount, prices);
	}

	/**
	 * Returns the total rewards currently available for withdrawal. (For calling from inside the contract)
	 */
	function _calculateWithdrawableInterestAmount4Legacy(
		address _property,
		address _user
	) private view returns (uint256 _amount, RewardPrices memory _prices) {
		/**
		 * If the passed Property has not authenticated, returns always 0.
		 */
		if (
			IMetricsGroup(config().metricsGroup()).hasAssets(_property) == false
		) {
			(
				uint256 reward,
				uint256 holders,
				uint256 interest,
				uint256 holdersCap
			) = calculateCumulativeRewardPrices();
			return (0, RewardPrices(reward, holders, interest, holdersCap));
		}

		/**
		 * Gets the reward amount in saved without withdrawal.
		 */
		uint256 pending = getStoragePendingInterestWithdrawal(_property, _user);

		/**
		 * Gets the reward amount of before DIP4.
		 */
		uint256 legacy = __legacyWithdrawableInterestAmount(_property, _user);

		/**
		 * Gets the latest withdrawal reward amount.
		 */
		(
			uint256 amount,
			,
			RewardPrices memory prices
		) = _calculateInterestAmount4Legacy(_property, _user);

		/**
		 * Returns the sum of all values.
		 */
		uint256 withdrawableAmount = amount.add(pending).add(legacy);
		return (withdrawableAmount, prices);
	}

	/**
	 * Returns the total rewards currently available for withdrawal. (For calling from external of the contract)
	 */
	function calculateWithdrawableInterestAmount(
		address _property,
		address _user
	) external view returns (uint256) {
		(uint256 amount, ) = _calculateWithdrawableInterestAmount4Legacy(
			_property,
			_user
		);
		return amount;
	}

	/**
	 * Returns the total rewards currently available for withdrawal. (For calling from external of the contract)
	 */
	function calculateWithdrawableInterestAmountByPosition(uint256 _tokenId)
		external
		view
		returns (uint256)
	{
		ISTokensManager sTokenManagerInstance = ISTokensManager(sTokensManager);
		(
			address property,
			uint256 amount,
			uint256 price,
			,
			uint256 pendingReward
		) = sTokenManagerInstance.positions(_tokenId);
		(uint256 result, ) = _calculateWithdrawableInterestAmount(
			property,
			amount,
			price,
			pendingReward
		);
		return result;
	}

	/**
	 * Withdraws staking reward as an interest.
	 */
	function _withdrawInterest(
		address _property,
		uint256 _amount,
		uint256 _price,
		uint256 _pendingReward
	) private returns (uint256 value_, RewardPrices memory prices_) {
		/**
		 * Gets the withdrawable amount.
		 */
		(
			uint256 value,
			RewardPrices memory prices
		) = _calculateWithdrawableInterestAmount(
				_property,
				_amount,
				_price,
				_pendingReward
			);

		/**
		 * Mints the reward.
		 */
		require(
			IDevMinter(devMinter).mint(msg.sender, value),
			"dev mint failed"
		);

		/**
		 * Since the total supply of tokens has changed, updates the latest maximum mint amount.
		 */
		update();

		return (value, prices);
	}

	/**
	 * Withdraws staking reward as an interest.
	 */
	function _withdrawInterest4Legacy(address _property)
		private
		returns (RewardPrices memory _prices)
	{
		/**
		 * Gets the withdrawable amount.
		 */
		(
			uint256 value,
			RewardPrices memory prices
		) = _calculateWithdrawableInterestAmount4Legacy(_property, msg.sender);

		/**
		 * Sets the unwithdrawn reward amount to 0.
		 */
		setStoragePendingInterestWithdrawal(_property, msg.sender, 0);

		/**
		 * Updates the staking status to avoid double rewards.
		 */
		setStorageLastStakedInterestPrice(
			_property,
			msg.sender,
			prices.interest
		);
		__updateLegacyWithdrawableInterestAmount(_property, msg.sender);

		/**
		 * Mints the reward.
		 */
		require(
			IDevMinter(devMinter).mint(msg.sender, value),
			"dev mint failed"
		);

		/**
		 * Since the total supply of tokens has changed, updates the latest maximum mint amount.
		 */
		update();

		return prices;
	}

	/**
	 * Status updates with the addition or release of staking.
	 */
	function updateValues4Legacy(
		bool _addition,
		address _account,
		address _property,
		uint256 _value,
		RewardPrices memory _prices
	) private {
		/**
		 * Updates the staking status to avoid double rewards.
		 */
		setStorageLastStakedInterestPrice(
			_property,
			_account,
			_prices.interest
		);
		updateValues(_addition, _property, _value, _prices);
		/**
		 * Updates the staking value of property by user
		 */
		if (_addition) {
			addValue(_property, _account, _value);
		} else {
			subValue(_property, _account, _value);
		}
	}

	/**
	 * Status updates with the addition or release of staking.
	 */
	function updateValues(
		bool _addition,
		address _property,
		uint256 _value,
		RewardPrices memory _prices
	) private {
		beforeStakesChanged(_property, _prices);
		/**
		 * If added staking:
		 */
		if (_addition) {
			/**
			 * Updates the current staking amount of the protocol total.
			 */
			addAllValue(_value);

			/**
			 * Updates the current staking amount of the Property.
			 */
			addPropertyValue(_property, _value);
			/**
			 * If released staking:
			 */
		} else {
			/**
			 * Updates the current staking amount of the protocol total.
			 */
			subAllValue(_value);

			/**
			 * Updates the current staking amount of the Property.
			 */
			subPropertyValue(_property, _value);
		}

		/**
		 * Since each staking amount has changed, updates the latest maximum mint amount.
		 */
		update();
	}

	/**
	 * Returns the staking amount of the protocol total.
	 */
	function getAllValue() external view returns (uint256) {
		return getStorageAllValue();
	}

	/**
	 * Adds the staking amount of the protocol total.
	 */
	function addAllValue(uint256 _value) private {
		uint256 value = getStorageAllValue();
		value = value.add(_value);
		setStorageAllValue(value);
	}

	/**
	 * Subtracts the staking amount of the protocol total.
	 */
	function subAllValue(uint256 _value) private {
		uint256 value = getStorageAllValue();
		value = value.sub(_value);
		setStorageAllValue(value);
	}

	/**
	 * Returns the user's staking amount in the Property.
	 */
	function getValue(address _property, address _sender)
		external
		view
		returns (uint256)
	{
		return getStorageValue(_property, _sender);
	}

	/**
	 * Adds the user's staking amount in the Property.
	 */
	function addValue(
		address _property,
		address _sender,
		uint256 _value
	) private {
		uint256 value = getStorageValue(_property, _sender);
		value = value.add(_value);
		setStorageValue(_property, _sender, value);
	}

	/**
	 * Subtracts the user's staking amount in the Property.
	 */
	function subValue(
		address _property,
		address _sender,
		uint256 _value
	) private {
		uint256 value = getStorageValue(_property, _sender);
		value = value.sub(_value);
		setStorageValue(_property, _sender, value);
	}

	/**
	 * Returns whether the user is staking in the Property.
	 */
	function hasValue(
		address _property,
		address _sender,
		uint256 _amount
	) private view returns (bool) {
		uint256 value = getStorageValue(_property, _sender);
		return value >= _amount;
	}

	/**
	 * Returns the staking amount of the Property.
	 */
	function getPropertyValue(address _property)
		external
		view
		returns (uint256)
	{
		return getStoragePropertyValue(_property);
	}

	/**
	 * Adds the staking amount of the Property.
	 */
	function addPropertyValue(address _property, uint256 _value) private {
		uint256 value = getStoragePropertyValue(_property);
		value = value.add(_value);
		setStoragePropertyValue(_property, value);
	}

	/**
	 * Subtracts the staking amount of the Property.
	 */
	function subPropertyValue(address _property, uint256 _value) private {
		uint256 value = getStoragePropertyValue(_property);
		uint256 nextValue = value.sub(_value);
		setStoragePropertyValue(_property, nextValue);
	}

	/**
	 * Saves the latest reward amount as an undrawn amount.
	 */
	function updatePendingInterestWithdrawal(address _property, address _user)
		private
		returns (RewardPrices memory _prices)
	{
		/**
		 * Gets the latest reward amount.
		 */
		(
			uint256 withdrawableAmount,
			RewardPrices memory prices
		) = _calculateWithdrawableInterestAmount4Legacy(_property, _user);

		/**
		 * Saves the amount to `PendingInterestWithdrawal` storage.
		 */
		setStoragePendingInterestWithdrawal(
			_property,
			_user,
			withdrawableAmount
		);

		/**
		 * Updates the reward amount of before DIP4 to prevent further addition it.
		 */
		__updateLegacyWithdrawableInterestAmount(_property, _user);

		return prices;
	}

	/**
	 * Returns the reward amount of the calculation model before DIP4.
	 * It can be calculated by subtracting "the last cumulative sum of reward unit price" from
	 * "the current cumulative sum of reward unit price," and multiplying by the staking amount.
	 */
	function __legacyWithdrawableInterestAmount(
		address _property,
		address _user
	) private view returns (uint256) {
		uint256 _last = getStorageLastInterestPrice(_property, _user);
		uint256 price = getStorageInterestPrice(_property);
		uint256 priceGap = price.sub(_last);
		uint256 lockedUpValue = getStorageValue(_property, _user);
		uint256 value = priceGap.mul(lockedUpValue);
		return value.divBasis();
	}

	/**
	 * Updates and treats the reward of before DIP4 as already received.
	 */
	function __updateLegacyWithdrawableInterestAmount(
		address _property,
		address _user
	) private {
		uint256 interestPrice = getStorageInterestPrice(_property);
		if (getStorageLastInterestPrice(_property, _user) != interestPrice) {
			setStorageLastInterestPrice(_property, _user, interestPrice);
		}
	}

	function ___setFallbackInitialCumulativeHoldersRewardCap(uint256 _value)
		external
		onlyOwner
	{
		setStorageFallbackInitialCumulativeHoldersRewardCap(_value);
	}

	/**
	 * migration to nft
	 */
	function migrateToSTokens(address _property)
		external
		returns (uint256 tokenId_)
	{
		/**
		 * Get the amount the user is staking for the Property.
		 */
		uint256 amount = getStorageValue(_property, msg.sender);
		require(amount > 0, "not staked");
		/**
		 * Gets the cumulative sum of the interest price recorded the last time you withdrew.
		 */
		uint256 price = getStorageLastStakedInterestPrice(
			_property,
			msg.sender
		);
		/**
		 * Gets the reward amount in saved without withdrawal.
		 */
		uint256 pending = getStoragePendingInterestWithdrawal(
			_property,
			msg.sender
		);
		/**
		 * Sets the unwithdrawn reward amount to 0.
		 */
		setStoragePendingInterestWithdrawal(_property, msg.sender, 0);
		/**
		 * The amount of the user's investment in the property is set to zero.
		 */
		setStorageValue(_property, msg.sender, 0);
		ISTokensManager sTokenManagerInstance = ISTokensManager(sTokensManager);
		/**
		 * mint nft
		 */
		uint256 tokenId = sTokenManagerInstance.mint(
			msg.sender,
			_property,
			amount,
			price,
			""
		);
		/**
		 * update position information
		 */
		bool result = sTokenManagerInstance.update(
			tokenId,
			amount,
			price,
			0,
			pending
		);
		require(result, "failed to update");
		return tokenId;
	}
}