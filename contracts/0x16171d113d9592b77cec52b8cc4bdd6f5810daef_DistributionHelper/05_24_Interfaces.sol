// SPDX-License-Identifier: MIT
import { DataTypes } from "./utils/DataTypes.sol";
pragma solidity >=0.8.0;

pragma experimental ABIEncoderV2;

interface ERC20 {
	function balanceOf(address addr) external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function approve(address spender, uint256 amount) external returns (bool);

	function decimals() external view returns (uint8);

	function mint(address to, uint256 mintAmount) external returns (uint256);

	function burn(uint256 amount) external;

	function totalSupply() external view returns (uint256);

	function allowance(
		address owner,
		address spender
	) external view returns (uint256);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	function name() external view returns (string memory);

	function symbol() external view returns (string memory);

	event Transfer(address indexed from, address indexed to, uint256 amount);
	event Transfer(
		address indexed from,
		address indexed to,
		uint256 amount,
		bytes data
	);
}

interface cERC20 is ERC20 {
	function mint(uint256 mintAmount) external returns (uint256);

	function redeemUnderlying(uint256 mintAmount) external returns (uint256);

	function redeem(uint256 mintAmount) external returns (uint256);

	function exchangeRateCurrent() external returns (uint256);

	function exchangeRateStored() external view returns (uint256);

	function underlying() external returns (address);
}

interface IGoodDollar is ERC20 {
	// view functions
	function feeRecipient() external view returns (address);

	function getFees(
		uint256 value,
		address sender,
		address recipient
	) external view returns (uint256 fee, bool senderPays);

	function cap() external view returns (uint256);

	function isPauser(address _pauser) external view returns (bool);

	function getFees(uint256 value) external view returns (uint256, bool);

	function isMinter(address minter) external view returns (bool);

	function formula() external view returns (address);

	function identity() external view returns (address);

	function owner() external view returns (address);

	// state changing functions
	function setFeeRecipient(address _feeRecipient) external;

	function setFormula(address _formula) external;

	function transferOwnership(address _owner) external;

	function addPauser(address _pauser) external;

	function pause() external;

	function unpause() external;

	function burn(uint256 amount) external;

	function burnFrom(address account, uint256 amount) external;

	function renounceMinter() external;

	function addMinter(address minter) external;

	function transferAndCall(
		address to,
		uint256 value,
		bytes calldata data
	) external returns (bool);

	function setIdentity(address identity) external;
}

interface IERC2917 is ERC20 {
	/// @dev This emit when interests amount per block is changed by the owner of the contract.
	/// It emits with the old interests amount and the new interests amount.
	event InterestRatePerBlockChanged(uint256 oldValue, uint256 newValue);

	/// @dev This emit when a users' productivity has changed
	/// It emits with the user's address and the the value after the change.
	event ProductivityIncreased(address indexed user, uint256 value);

	/// @dev This emit when a users' productivity has changed
	/// It emits with the user's address and the the value after the change.
	event ProductivityDecreased(address indexed user, uint256 value);

	/// @dev Return the current contract's interests rate per block.
	/// @return The amount of interests currently producing per each block.
	function interestsPerBlock() external view returns (uint256);

	/// @notice Change the current contract's interests rate.
	/// @dev Note the best practice will be restrict the gross product provider's contract address to call this.
	/// @return The true/fase to notice that the value has successfully changed or not, when it succeed, it will emite the InterestRatePerBlockChanged event.
	function changeInterestRatePerBlock(uint256 value) external returns (bool);

	/// @notice It will get the productivity of given user.
	/// @dev it will return 0 if user has no productivity proved in the contract.
	/// @return user's productivity and overall productivity.
	function getProductivity(
		address user
	) external view returns (uint256, uint256);

	/// @notice increase a user's productivity.
	/// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
	/// @return true to confirm that the productivity added success.
	function increaseProductivity(
		address user,
		uint256 value
	) external returns (bool);

	/// @notice decrease a user's productivity.
	/// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
	/// @return true to confirm that the productivity removed success.
	function decreaseProductivity(
		address user,
		uint256 value
	) external returns (bool);

	/// @notice take() will return the interests that callee will get at current block height.
	/// @dev it will always calculated by block.number, so it will change when block height changes.
	/// @return amount of the interests that user are able to mint() at current block height.
	function take() external view returns (uint256);

	/// @notice similar to take(), but with the block height joined to calculate return.
	/// @dev for instance, it returns (_amount, _block), which means at block height _block, the callee has accumulated _amount of interests.
	/// @return amount of interests and the block height.
	function takeWithBlock() external view returns (uint256, uint256);

	/// @notice mint the avaiable interests to callee.
	/// @dev once it mint, the amount of interests will transfer to callee's address.
	/// @return the amount of interests minted.
	function mint() external returns (uint256);
}

interface Staking {
	struct Staker {
		// The staked DAI amount
		uint256 stakedDAI;
		// The latest block number which the
		// staker has staked tokens
		uint256 lastStake;
	}

	function stakeDAI(uint256 amount) external;

	function withdrawStake() external;

	function stakers(address staker) external view returns (Staker memory);
}

interface Uniswap {
	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function WETH() external pure returns (address);

	function factory() external pure returns (address);

	function quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) external pure returns (uint256 amountB);

	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountIn);

	function getAmountOut(
		uint256 amountI,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountOut);

	function getAmountsOut(
		uint256 amountIn,
		address[] memory path
	) external pure returns (uint256[] memory amounts);
}

interface UniswapFactory {
	function getPair(
		address tokenA,
		address tokenB
	) external view returns (address);
}

interface UniswapPair {
	function getReserves()
		external
		view
		returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

	function kLast() external view returns (uint256);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);
}

interface Reserve {
	function buy(
		address _buyWith,
		uint256 _tokenAmount,
		uint256 _minReturn
	) external returns (uint256);
}

interface IIdentity {
	function isWhitelisted(address user) external view returns (bool);

	function addWhitelistedWithDID(address account, string memory did) external;

	function removeWhitelisted(address account) external;

	function addBlacklisted(address account) external;

	function removeBlacklisted(address account) external;

	function isBlacklisted(address user) external view returns (bool);

	function addIdentityAdmin(address account) external returns (bool);

	function setAvatar(address _avatar) external;

	function isIdentityAdmin(address account) external view returns (bool);

	function owner() external view returns (address);

	function removeContract(address account) external;

	function isDAOContract(address account) external view returns (bool);

	function addrToDID(address account) external view returns (string memory);

	function didHashToAddress(bytes32 hash) external view returns (address);

	function lastAuthenticated(address account) external view returns (uint256);

	event WhitelistedAdded(address user);
}

interface IIdentityV2 is IIdentity {
	function addWhitelistedWithDIDAndChain(
		address account,
		string memory did,
		uint256 orgChainId,
		uint256 dateAuthenticated
	) external;

	function getWhitelistedRoot(
		address account
	) external view returns (address root);
}

interface IUBIScheme {
	function currentDay() external view returns (uint256);

	function periodStart() external view returns (uint256);

	function hasClaimed(address claimer) external view returns (bool);
}

interface IFirstClaimPool {
	function awardUser(address user) external returns (uint256);

	function claimAmount() external view returns (uint256);

	function end() external;
}

interface ProxyAdmin {
	function getProxyImplementation(
		address proxy
	) external view returns (address);

	function getProxyAdmin(address proxy) external view returns (address);

	function upgrade(address proxy, address implementation) external;

	function owner() external view returns (address);

	function transferOwnership(address newOwner) external;

	function upgradeAndCall(
		address proxy,
		address implementation,
		bytes memory data
	) external;
}

/**
 * @dev Interface for chainlink oracles to obtain price datas
 */
interface AggregatorV3Interface {
	function decimals() external view returns (uint8);

	function description() external view returns (string memory);

	function version() external view returns (uint256);

	// getRoundData and latestRoundData should both raise "No data present"
	// if they do not have data to report, instead of returning unset values
	// which could be misinterpreted as actual reported values.
	function getRoundData(
		uint80 _roundId
	)
		external
		view
		returns (
			uint80 roundId,
			int256 answer,
			uint256 startedAt,
			uint256 updatedAt,
			uint80 answeredInRound
		);

	function latestAnswer() external view returns (int256);
}

/**
	@dev interface for AAVE lending Pool
 */
interface ILendingPool {
	/**
	 * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
	 * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
	 * @param asset The address of the underlying asset to deposit
	 * @param amount The amount to be deposited
	 * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
	 *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
	 *   is a different wallet
	 * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
	 *   0 if the action is executed directly by the user, without any middle-man
	 **/
	function deposit(
		address asset,
		uint256 amount,
		address onBehalfOf,
		uint16 referralCode
	) external;

	/**
	 * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
	 * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
	 * @param asset The address of the underlying asset to withdraw
	 * @param amount The underlying amount to be withdrawn
	 *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
	 * @param to Address that will receive the underlying, same as msg.sender if the user
	 *   wants to receive it on his own wallet, or a different address if the beneficiary is a
	 *   different wallet
	 * @return The final amount withdrawn
	 **/
	function withdraw(
		address asset,
		uint256 amount,
		address to
	) external returns (uint256);

	/**
	 * @dev Returns the state and configuration of the reserve
	 * @param asset The address of the underlying asset of the reserve
	 * @return The state of the reserve
	 **/
	function getReserveData(
		address asset
	) external view returns (DataTypes.ReserveData memory);
}

interface IDonationStaking {
	function stakeDonations() external payable;
}

interface INameService {
	function getAddress(string memory _name) external view returns (address);
}

interface IAaveIncentivesController {
	/**
	 * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
	 * @param amount Amount of rewards to claim
	 * @param to Address that will be receiving the rewards
	 * @return Rewards claimed
	 **/
	function claimRewards(
		address[] calldata assets,
		uint256 amount,
		address to
	) external returns (uint256);

	/**
	 * @dev Returns the total of rewards of an user, already accrued + not yet accrued
	 * @param user The address of the user
	 * @return The rewards
	 **/
	function getRewardsBalance(
		address[] calldata assets,
		address user
	) external view returns (uint256);
}

interface IGoodStaking {
	function collectUBIInterest(
		address recipient
	) external returns (uint256, uint256, uint256);

	function iToken() external view returns (address);

	function currentGains(
		bool _returnTokenBalanceInUSD,
		bool _returnTokenGainsInUSD
	) external view returns (uint256, uint256, uint256, uint256, uint256);

	function getRewardEarned(address user) external view returns (uint256);

	function getGasCostForInterestTransfer() external view returns (uint256);

	function rewardsMinted(
		address user,
		uint256 rewardsPerBlock,
		uint256 blockStart,
		uint256 blockEnd
	) external returns (uint256);
}

interface IHasRouter {
	function getRouter() external view returns (Uniswap);
}

interface IAdminWallet {
	function addAdmins(address payable[] memory _admins) external;

	function removeAdmins(address[] memory _admins) external;

	function owner() external view returns (address);

	function transferOwnership(address _owner) external;
}

interface IMultichainRouter {
	// Swaps `amount` `token` from this chain to `toChainID` chain with recipient `to`
	function anySwapOut(
		address token,
		address to,
		uint256 amount,
		uint256 toChainID
	) external;

	// Swaps `amount` `token` from this chain to `toChainID` chain with recipient `to`
	function anySwapOutUnderlying(
		address token,
		address to,
		uint256 amount,
		uint256 toChainID
	) external;
}