// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import "./openzeppelin/utils/ReentrancyGuard.sol";
import "./openzeppelin/math/Math.sol";
import "./openzeppelin/token/ERC20/IERC20.sol";
import "./openzeppelin/math/SafeMath.sol";
import "./openzeppelin/utils/Address.sol";
import "./openzeppelin/token/ERC20/SafeERC20.sol";

import "./RollRewardsDistributionRecipient.sol";
import "./TokenWrapper.sol";

contract RollStakingRewards is
	RollRewardsDistributionRecipient,
	TokenWrapper,
	ReentrancyGuard
{
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	/* ========== STATE VARIABLES ========== */

	struct TokenRewardData {
		uint256 rewardRate;
		uint256 rewardPerTokenStored;
	}

	address[] public rewardTokensAddresses;
	mapping(address => TokenRewardData) public rewardTokens;
	mapping(address => mapping(address => uint256))
		public userRewardPerTokenPaid;
	mapping(address => mapping(address => uint256)) public rewards;
	mapping(address => uint256) public freeTokens;

	/* ========== GLOBAL STATE VARIABLES ==========  */

	uint256 public periodStart;
	uint256 public periodFinish;
	uint256 public rewardsDuration;

	uint256 public lastUpdateTime;
	uint256 public immutable tokenDecimals;

	uint256 public lastUnstake;

	/* ========== CONSTRUCTOR ========== */

	constructor(
		address _owner,
		address _rewardsDistribution,
		address[] memory _rewardTokens,
		address _stakingToken,
		address _registry
	) RollOwned(_owner, _registry) {
		for (uint256 i = 0; i < _rewardTokens.length; i++) {
			rewardTokensAddresses.push(_rewardTokens[i]);
			rewardTokens[_rewardTokens[i]] = TokenRewardData(0, 0);
		}
		token = IERC20(_stakingToken);
		tokenDecimals = token.decimals();
		rewardsDistribution = _rewardsDistribution;
	}

	/* ========== VIEWS ========== */

	function lastTimeRewardApplicable() public view returns (uint256) {
		uint256 n = Math.min(block.timestamp, periodFinish);
		return Math.max(n, periodStart);
	}

	function isValidRewardToken(address _token) public view returns (bool) {
		for (uint256 i = 0; i < rewardTokensAddresses.length; i++)
			if (_token == address(rewardTokensAddresses[i])) return true;
		return false;
	}

	function rewardPerToken(address _token) public view returns (uint256) {
		TokenRewardData storage data = rewardTokens[_token];
		if (_totalSupply == 0 || block.timestamp < periodStart) {
			return data.rewardPerTokenStored;
		}

		return
			data.rewardPerTokenStored.add(
				lastTimeRewardApplicable()
					.sub(lastUpdateTime)
					.mul(data.rewardRate)
					.mul(10**tokenDecimals)
					.div(totalSupply())
			);
	}

	function earned(address _account, address _token)
		public
		view
		returns (uint256)
	{
		return
			balanceOf(_account)
				.mul(
					rewardPerToken(_token).sub(
						userRewardPerTokenPaid[_token][_account]
					)
				)
				.div(10**tokenDecimals)
				.add(rewards[_token][_account]);
	}

	function getRewardForDuration(address _token)
		public
		view
		returns (uint256)
	{
		TokenRewardData storage data = rewardTokens[_token];
		return data.rewardRate.mul(rewardsDuration);
	}

	function getFreeTokenAmount(address token) public view returns (uint256) {
		if (block.timestamp <= periodStart) return 0;
		if (lastUnstake > Math.min(periodFinish, block.timestamp))
			return freeTokens[token];

		uint256 leftover = 0;
		if (super.totalSupply() == 0) {
			uint256 remaining = Math.min(periodFinish, block.timestamp).sub(
				lastUnstake
			);
			TokenRewardData storage data = rewardTokens[token];
			leftover = remaining.mul(data.rewardRate);
		}
		return freeTokens[token].add(leftover);
	}

	/* ========== MUTATIVE FUNCTIONS ========== */
	function moveFreeTokenToCreator() internal {
		uint256 from = Math.max(lastUnstake, periodStart);
		uint256 to = Math.min(block.timestamp, periodFinish);
		if (from >= to) return;
		if (super.totalSupply() == 0) {
			uint256 remaining = to.sub(from);
			for (uint256 i = 0; i < rewardTokensAddresses.length; i++) {
				TokenRewardData storage data = rewardTokens[
					rewardTokensAddresses[i]
				];
				uint256 leftover = remaining.mul(data.rewardRate);
				freeTokens[rewardTokensAddresses[i]] = freeTokens[
					rewardTokensAddresses[i]
				].add(leftover);
			}
		}
		lastUnstake = Math.max(block.timestamp, lastUnstake);
	}

	function stake(uint256 amount)
		public
		override
		nonReentrant
		notPaused
		updateReward(msg.sender)
	{
		require(amount > 0, "Cannot stake 0");
		moveFreeTokenToCreator();
		super.stake(amount);
		emit Staked(msg.sender, amount);
	}

	function withdraw(uint256 amount)
		public
		override
		nonReentrant
		updateReward(msg.sender)
	{
		require(amount > 0, "Cannot withdraw 0");
		moveFreeTokenToCreator();
		super.withdraw(amount);
		emit Withdrawn(msg.sender, amount);
	}

	function getReward() public nonReentrant updateReward(msg.sender) {
		for (uint256 i = 0; i < rewardTokensAddresses.length; i++) {
			uint256 reward = rewards[address(rewardTokensAddresses[i])][
				msg.sender
			];
			if (reward > 0) {
				rewards[address(rewardTokensAddresses[i])][msg.sender] = 0;
				IERC20(rewardTokensAddresses[i]).safeTransfer(
					msg.sender,
					reward
				);
				emit RewardPaid(
					msg.sender,
					address(rewardTokensAddresses[i]),
					reward
				);
			}
		}
	}

	function exit() external {
		withdraw(_balances[msg.sender]);
		getReward();
	}

	/* ========== RESTRICTED FUNCTIONS ========== */

	/* issues with adding multiple tokens
	 * Either we leave them and there will be wasted gas for expired rewards or
	 * we remove a token from the array and prevent anyone from claiming if they forgot to do so
	 * An announcement may be given a week prior from removing a secondary reward token.
	 * this would keep calls as efficient as possible.
	 */
	function notifyRewardAmount(
		uint256[] calldata _rewards,
		address[] calldata _tokens
	)
		external
		override
		onlyRewardsDistribution
		updateReward(address(0))
		lazyUpdateReward(address(0))
	{
		require(
			block.timestamp > periodFinish,
			"RollStakingRewards: Previous rewards period must be complete before changing the duration for the new period"
		);
		require(
			periodStart > 0 && block.timestamp < periodStart,
			"RollStakingRewards: Period not set"
		);
		require(
			_rewards.length == _tokens.length &&
				rewardTokensAddresses.length == _tokens.length,
			"RollStakingRewards: Amount of rewards not matching reward token count."
		);
		moveFreeTokenToCreator();
		for (uint256 i = 0; i < _tokens.length; i++) {
			uint256 balance = 0;
			TokenRewardData storage data = rewardTokens[_tokens[i]];

			data.rewardRate = _rewards[i].div(rewardsDuration);

			//==============================
			// transfer the tokens
			IERC20 _token = IERC20(_tokens[i]);
			bool ok = _token.transferFrom(
				msg.sender,
				address(this),
				_rewards[i]
			);
			require(ok, "LM: no enough tokens");
			uint256 leftover = _rewards[i].sub(
				data.rewardRate.mul(rewardsDuration)
			);
			freeTokens[_tokens[i]] = freeTokens[_tokens[i]].add(leftover);

			balance = _rewards[i];
			//==============================
			require(
				data.rewardRate <= balance.div(rewardsDuration),
				"RollStakingRewards: Provided reward too high"
			);
			emit RewardAdded(_rewards[i], _tokens[i]);
		}
		lastUpdateTime = periodStart;
		periodFinish = periodStart.add(rewardsDuration);
	}

	function setRewardsDuration(uint256 _periodStart, uint256 _rewardsDuration)
		external
		onlyOwner
		updateReward(address(0))
		lazyUpdateReward(address(0))
	{
		require(
			block.timestamp > periodFinish,
			"RollStakingRewards: Previous rewards period must be complete before changing the duration for the new period"
		);
		require(
			block.timestamp < _periodStart || _periodStart == 0,
			"RollStakingRewards: Start must be a future date"
		);

		// if is not the first campaing let's reset reaward balances
		if (periodStart > 0) {
			claimFreeTokensImpl();
		}

		if (_periodStart == 0) {
			periodStart = block.timestamp;
		} else {
			periodStart = _periodStart;
		}

		periodFinish = 0;
		lastUpdateTime = periodStart;
		lastUnstake = periodStart;
		rewardsDuration = _rewardsDuration;
		emit RewardsUpdated(periodStart, rewardsDuration);
	}

	function claimFreeTokensImpl() internal {
		require(
			block.timestamp > periodFinish,
			"RollStakingRewards: Previous rewards period must be complete before claim"
		);

		// check if there's some pending calculation
		moveFreeTokenToCreator();

		// do the transfer
		for (uint256 i = 0; i < rewardTokensAddresses.length; i++) {
			address token = rewardTokensAddresses[i];
			uint256 freeTokenAmount = freeTokens[token];
			freeTokens[token] = 0;
			if (freeTokenAmount > 0) {
				IERC20 _token = IERC20(token);
				bool ok = _token.transfer(msg.sender, freeTokenAmount);
				require(ok, "LM: no enough tokens");
			}
		}

		emit RewardsUpdated(periodStart, rewardsDuration);
	}

	function claimFreeTokens() external onlyOwner {
		claimFreeTokensImpl();
	}

	/* ========== MODIFIERS ========== */
	modifier lazyUpdateReward(address _account) {
		_;
		updateRewardImpl(_account);
	}

	modifier updateReward(address _account) {
		updateRewardImpl(_account);
		_;
	}

	function updateRewardImpl(address _account) internal {
		for (uint256 i = 0; i < rewardTokensAddresses.length; i++) {
			TokenRewardData storage data = rewardTokens[
				rewardTokensAddresses[i]
			];
			data.rewardPerTokenStored = rewardPerToken(
				rewardTokensAddresses[i]
			);
		}
		lastUpdateTime = lastTimeRewardApplicable();
		for (uint256 i = 0; i < rewardTokensAddresses.length; i++) {
			TokenRewardData storage data = rewardTokens[
				rewardTokensAddresses[i]
			];
			if (_account != address(0)) {
				rewards[rewardTokensAddresses[i]][_account] = earned(
					_account,
					rewardTokensAddresses[i]
				);
				userRewardPerTokenPaid[rewardTokensAddresses[i]][
					_account
				] = data.rewardPerTokenStored;
			}
		}
	}

	event RewardAdded(uint256 reward, address indexed token);
	event Staked(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RewardPaid(
		address indexed user,
		address indexed token,
		uint256 reward
	);
	event RewardsUpdated(uint256 newStart, uint256 newDuration);
	event Recovered(address token, uint256 amount);
}