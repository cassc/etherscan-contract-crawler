// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

import "../interfaces/IDelegateFunction.sol";
import "../interfaces/ILiquidityPool.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/structs/DelegateMapView.sol";

contract SnapshotToke is IERC20, Ownable {
	using EnumerableSet for EnumerableSet.AddressSet;
	using SafeMath for uint256;

	uint256 private constant SUPPLY = 100_000_000e18;
	uint8 private constant DECIMALS = 18;
	string private constant NAME = "Tokemak Snapshot Vote";
	string private constant SYMBOL = "vTOKE";
	bytes32 private constant VOTING_FUNCTION = "voting";

	IERC20 private immutable sushiLPPool;
	IStaking private immutable staking;
	IDelegateFunction private immutable delegation;
	IERC20 private immutable toke;

	IERC20 private immutable sushiLP;

	/// @dev to => from[]
	mapping(address => EnumerableSet.AddressSet) private delegationsTo;

	/// @dev from => true/false
	mapping(address => bool) private delegatedAway;

	constructor(address _sushiLPPool, address _staking, address _delegation, address _toke) public {
		require(_sushiLPPool != address(0), "ZERO_ADDRESS_SUSHILP");
		require(_staking != address(0), "ZERO_ADDRESS_STAKING");
		require(_delegation != address(0), "ZERO_ADDRESS_DELEGATION");
		require(_toke != address(0), "ZERO_ADDRESS_TOKE");

		sushiLPPool = IERC20(_sushiLPPool);
		staking = IStaking(_staking);
		delegation = IDelegateFunction(_delegation);
		toke = IERC20(_toke);

		sushiLP = IERC20(address(ILiquidityPool(_sushiLPPool).underlyer()));
	}

	event DelegationSetup(address indexed from, address indexed to, address indexed sender);
	event DelegationRemoved(address indexed from, address indexed to, address indexed sender);

	/**
	 * @dev Returns the amount of tokens owned by `account`.
	 */
	function balanceOf(address account) external view override returns (uint256 bal) {
		// See if they've setup a delegation locally
		bool delegatedAway = delegatedAway[account];

		if (delegatedAway) {
			// Ensure the delegate away is still valid
			DelegateMapView memory delegationFrom = delegation.getDelegation(account, VOTING_FUNCTION);
			delegatedAway = delegationFrom.otherParty != address(0) && !delegationFrom.pending;
		}

		if (!delegatedAway) {
			// Get TOKE directly assigned to this wallet
			bal = getBalance(account);

			// Get TOKE balance from delegated accounts
			EnumerableSet.AddressSet storage delegations = delegationsTo[account];
			uint256 length = delegations.length();
			for (uint256 i = 0; i < length; ++i) {
				address delegatedFrom = delegations.at(i);

				//Ensure the delegation to account is still valid
				DelegateMapView memory queriedDelegation = delegation.getDelegation(delegatedFrom, VOTING_FUNCTION);
				if (queriedDelegation.otherParty == account && !queriedDelegation.pending) {
					bal = bal.add(getBalance(delegatedFrom));
				}
			}
		}
	}

	function addDelegations(address[] memory from, address[] memory to) external onlyOwner {
		uint256 length = from.length;
		require(length > 0, "ZERO_LENGTH");
		require(length == to.length, "MISMATCH_LENGTH");
		for (uint256 i = 0; i < length; ++i) {
			_addDelegation(from[i], to[i]);
		}
	}

	function removeDelegations(address[] memory from, address[] memory to) external onlyOwner {
		uint256 length = from.length;
		require(length > 0, "ZERO_LENGTH");
		require(length == to.length, "MISMATCH_LENGTH");
		for (uint256 i = 0; i < length; ++i) {
			_removeDelegation(from[i], to[i]);
		}
	}

	function addDelegation(address from, address to) external onlyOwner {
		_addDelegation(from, to);
	}

	function removeDelegation(address from, address to) external onlyOwner {
		_removeDelegation(from, to);
	}

	function name() public view virtual returns (string memory) {
		return NAME;
	}

	function symbol() public view virtual returns (string memory) {
		return SYMBOL;
	}

	function decimals() public view virtual returns (uint8) {
		return DECIMALS;
	}

	function totalSupply() external view override returns (uint256) {
		return SUPPLY;
	}

	/**
	 * @dev Moves `amount` tokens from the caller's account to `recipient`.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 */
	function transfer(address, uint256) external override returns (bool) {
		revert("NO_TRANSFERS_ALLOWED");
	}

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 */
	function allowance(address, address) external view override returns (uint256) {
		return 0;
	}

	/**
	 * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 */
	function approve(address, uint256) external override returns (bool) {
		revert("NO_TRANSFERS_ALLOWED");
	}

	/**
	 * @dev Moves `amount` tokens from `sender` to `recipient` using the
	 * allowance mechanism. `amount` is then deducted from the caller's
	 * allowance.
	 *
	 * Returns a boolean value indicating whether the operation succeeded.
	 */
	function transferFrom(address, address, uint256) external override returns (bool) {
		revert("NO_TRANSFERS_ALLOWED");
	}

	/// @notice Returns straight balance of the account. No delegations considered
	/// @param account Account to check
	/// @return bal Balance across all valid areas
	function getBalance(address account) private view returns (uint256 bal) {
		// Get TOKE sitting in their wallet
		bal = toke.balanceOf(account);

		// Get staked TOKE either liquid or vesting
		bal = bal.add(staking.balanceOf(account));

		// Get TOKE from SUSHI LP
		uint256 stakedSushiLP = sushiLPPool.balanceOf(account);
		if (stakedSushiLP > 0) {
			uint256 sushiLPTotalSupply = sushiLP.totalSupply();
			uint256 tokeInSushiPool = toke.balanceOf(address(sushiLP));
			bal = bal.add(stakedSushiLP.mul(tokeInSushiPool).div(sushiLPTotalSupply));
		}
	}

	function _addDelegation(address from, address to) private {
		DelegateMapView memory queriedDelegation = delegation.getDelegation(from, VOTING_FUNCTION);
		require(from != address(0), "INVALID_FROM");
		require(to != address(0), "INVALID_TO");
		require(queriedDelegation.otherParty == to, "INVALID_DELEGATION");
		require(queriedDelegation.pending == false, "DELEGATION_PENDING");
		require(delegationsTo[to].add(from), "ALREADY_ADDED");
		require(delegatedAway[from] == false, "ALREADY_DELEGATED");

		delegatedAway[from] = true;

		emit DelegationSetup(from, to, msg.sender);
	}

	function _removeDelegation(address from, address to) private {
		require(from != address(0), "INVALID_FROM");
		require(to != address(0), "INVALID_TO");
		require(delegationsTo[to].remove(from), "DOES_NOT_EXIST");
		require(delegatedAway[from], "NOT_DELEGATED_FROM");

		delegatedAway[from] = false;

		emit DelegationRemoved(from, to, msg.sender);
	}
}