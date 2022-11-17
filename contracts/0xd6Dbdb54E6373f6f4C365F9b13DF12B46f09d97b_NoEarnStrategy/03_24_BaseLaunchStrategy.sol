// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/access/AccessControlEnumerable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '../../Interfaces/IUniswapFarm.sol';
import '../../Interfaces/IStrategy.sol';
import '../../utils/PriceCalculator.sol';

/*
 * @dev Abstraction of external yield strategies for launch farms
 */
abstract contract BaseLaunchStrategy is
	AccessControlEnumerable,
	ReentrancyGuard,
	Pausable,
	IStrategy,
	PriceCalculator
{
	bytes32 public constant earnerRole = keccak256('earner');

	using SafeMath for uint256;
	using SafeERC20 for IERC20;

	// The staked token
	IERC20 public override stakedToken;

	// The token earned from farm
	IERC20 public override earnedToken;

	// The main contract that accepts user deposits
	address public masterTribe;

	// Address that staked tokens is deposited to earn yield (if any)
	address public farmAddress;

	// Address that earned tokens is transferred
	address public earnerAddress;

	// Router to compute prices
	IUniswapV2Router02 public router;

	// The amount handled by this strategy
	uint256 public override stakedLockedTotal = 0;

	// Path from single staking token or LP token0 to stable
	address[] public stakingTokenOrLP0ToStable;

	// Path from staked LP token1 to stable
	address[] public stakingLP1ToStable;

	// True is staked token is LP token
	bool public stakedIsLp;

	// Deposits staked tokens in the underlying farm
	function _depositToFarm(uint256 amount) internal virtual;

	// Withdraws staked tokens from the underlying farm
	function _withdrawFromFarm(uint256 amount) internal virtual;

	event AdminTokenRecovery(address tokenRecovered, uint256 amount);
	event Earn(address indexed earner, uint256 amount);

	constructor(
		address _masterTribe,
		IERC20 _stakedToken,
		IERC20 _earnedToken,
		address _farm,
		address _earner,
		IUniswapV2Router02 _router,
		address[] memory _stakingTokenOrLP0ToStable,
		address[] memory _stakingLP1ToStable,
		bool _stakedIsLp
	) {
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
		masterTribe = _masterTribe;
		stakedToken = _stakedToken;
		earnedToken = _earnedToken;
		earnerAddress = _earner;
		farmAddress = _farm;
		router = _router;
		stakingTokenOrLP0ToStable = _stakingTokenOrLP0ToStable;
		stakingLP1ToStable = _stakingLP1ToStable;
		stakedIsLp = _stakedIsLp;

		if (_farm != address(0)) {
			IERC20(address(stakedToken)).approve(_farm, type(uint256).max);
		}
	}

	/*
	 * @notice Deposit staked tokens in the underlying farm (if any)
	 * @dev This increases the stakedLockedTotal. Can only be called by master contract when not paused
	 * @param _amount: amount to deposit (in stakedToken)
	 */
	function deposit(uint256 _amount)
		external
		override
		whenNotPaused
		nonReentrant
		returns (uint256)
	{
		require(address(msg.sender) == masterTribe, 'Not master');
		stakedToken.safeTransferFrom(
			address(msg.sender),
			address(this),
			_amount
		);

		stakedLockedTotal = stakedLockedTotal.add(_amount);

		_depositToFarm(_amount);

		return _amount;
	}

	/*
	 * @notice Withdraw staked tokens in the underlying farm (if any)
	 * @dev This decreases the stakedLockedTotal. Can only be called by master contract when not paused
	 * @param _amount: amount to withdraw (in stakedToken)
	 */
	function withdraw(uint256 _amount)
		external
		override
		nonReentrant
		returns (uint256)
	{
		require(address(msg.sender) == masterTribe, 'Not master');
		require(_amount > 0, '_amount <= 0');

		_withdrawFromFarm(_amount);

		// ensure we make the right amount
		_amount = Math.min(_amount, stakedToken.balanceOf(address(this)));
		_amount = Math.min(_amount, stakedLockedTotal);

		stakedLockedTotal = stakedLockedTotal.sub(_amount);
		stakedToken.safeTransfer(masterTribe, _amount);

		return _amount;
	}

	/*
	 * @notice Transfers earned tokens to earnerAddress
	 * @dev This harvests any tokens from farm and transfers all earned tokens to earnerAddress.
	 * Can only be called by earnerRole.
	 */
	function earn() external override whenNotPaused onlyRole(earnerRole) {
		require(
			earnerAddress != address(0),
			'Earner address cannot be burn address'
		);

		_withdrawFromFarm(0);

		// safe even when staked = earned, as all staked is in farm
		uint256 earnedAmt = earnedToken.balanceOf(address(this));
		earnedToken.safeTransfer(earnerAddress, earnedAmt);

		emit Earn(earnerAddress, earnedAmt);
	}

	/**
	 * @notice It allows the admin to recover wrong tokens sent to the contract
	 * @param _tokenAddress: the address of the token to withdraw
	 * @param _tokenAmount: the number of tokens to withdraw
	 * @dev This function is only callable by admin.
	 */
	function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount)
		external
		override
		onlyRole(DEFAULT_ADMIN_ROLE)
	{
		require(_tokenAddress != address(stakedToken), '!safe');
		IERC20(_tokenAddress).safeTransfer(address(msg.sender), _tokenAmount);

		emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
	}

	/**
	 * @notice It allows the strategy to be paused
	 * @dev This function is only callable by admin
	 */
	function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
		_pause();
	}

	/**
	 * @notice It allows the strategy to be resumed
	 * @dev This function is only callable by admin
	 */
	function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
		_unpause();
	}

	/*
	 * @notice Computes price of the staked token
	 *
	 */
	function stakedTokenPrice() external view override returns (uint256) {
		return
			stakedIsLp
				? _getLPTokenPrice(
					router,
					stakingTokenOrLP0ToStable,
					stakingLP1ToStable,
					stakedToken
				)
				: _getTokenPrice(router, stakingTokenOrLP0ToStable);
	}
}