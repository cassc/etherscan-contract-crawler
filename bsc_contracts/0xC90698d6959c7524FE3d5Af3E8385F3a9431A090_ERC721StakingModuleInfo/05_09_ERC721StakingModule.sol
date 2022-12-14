/*
ERC721StakingModule

https://github.com/FanbaseEU/Staking_Ethereum_SmartContracts

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./interfaces/IStakingModule.sol";

/**
 * @title ERC721 staking module
 *
 * @notice this staking module allows users to deposit one or more ERC721
 * tokens in exchange for shares credited to their address. When the user
 * unstakes, these shares will be burned and a reward will be distributed.
 */
contract ERC721StakingModule is IStakingModule {
	// constant
	uint256 public constant SHARES_PER_TOKEN = 10**18;

	// members
	IERC721 private immutable _token;
	address public immutable _factory;

	mapping(address => uint256) public counts;
	mapping(uint256 => address) public owners;
	mapping(address => mapping(uint256 => uint256)) public tokenByOwner;
	mapping(uint256 => uint256) public tokenIndex;

	/**
	 * @param token_ the token that will be rewarded
	 */
	constructor(address token_, address factory_) {
		require(
			IERC165(token_).supportsInterface(0x80ac58cd),
			"Interface ID not matched"
		);
		_token = IERC721(token_);
		_factory = factory_;
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	function tokens()
		external
		view
		override
		returns (address[] memory tokens_)
	{
		tokens_ = new address[](1);
		tokens_[0] = address(_token);
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	function balances(address user)
		external
		view
		override
		returns (uint256[] memory balances_)
	{
		balances_ = new uint256[](1);
		balances_[0] = counts[user];
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	function factory() external view override returns (address) {
		return _factory;
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	function totals()
		external
		view
		override
		returns (uint256[] memory totals_)
	{
		totals_ = new uint256[](1);
		totals_[0] = _token.balanceOf(address(this));
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	function stake(
		address user,
		uint256 amount,
		bytes calldata data
	) external override onlyOwner returns (address, uint256) {
		// validate
		require(amount > 0, "Staking amount must be greater than 0");
		require(amount <= _token.balanceOf(user), "Insufficient balance");
		require(data.length == 32 * amount, "Invalid calldata");

		uint256 count = counts[user];

		// stake
		for (uint256 i = 0; i < amount; i++) {
			// get token id
			uint256 id;
			uint256 pos = 132 + 32 * i;
			assembly {
				id := calldataload(pos)
			}

			// ownership mappings
			owners[id] = user;
			uint256 len = count + i;
			tokenByOwner[user][len] = id;
			tokenIndex[id] = len;

			// transfer to module
			_token.transferFrom(user, address(this), id);
		}

		// update position
		counts[user] = count + amount;

		// emit
		uint256 shares = amount * SHARES_PER_TOKEN;
		emit Staked(user, address(_token), amount, shares);

		return (user, shares);
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	function unstake(
		address user,
		uint256 amount,
		bytes calldata data
	) external override onlyOwner returns (address, uint256) {
		// validate
		require(amount > 0, "Unstaking amount must be greater than 0");
		uint256 count = counts[user];
		require(amount <= count, "Insufficient staked balance");
		require(data.length == 32 * amount, "Invalid calldata");

		// unstake
		for (uint256 i = 0; i < amount; i++) {
			// get token id
			uint256 id;
			uint256 pos = 132 + 32 * i;
			assembly {
				id := calldataload(pos)
			}

			// ownership
			require(owners[id] == user, "Only owner can unstake");
			delete owners[id];

			// clean up ownership mappings
			uint256 lastIndex = count - 1 - i;
			if (amount != count) {
				// reindex on partial unstake
				uint256 index = tokenIndex[id];
				if (index != lastIndex) {
					uint256 lastId = tokenByOwner[user][lastIndex];
					tokenByOwner[user][index] = lastId;
					tokenIndex[lastId] = index;
				}
			}
			delete tokenByOwner[user][lastIndex];
			delete tokenIndex[id];

			// transfer to user
			_token.safeTransferFrom(address(this), user, id);
		}

		// update position
		counts[user] = count - amount;

		// emit
		uint256 shares = amount * SHARES_PER_TOKEN;
		emit Unstaked(user, address(_token), amount, shares);

		return (user, shares);
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	function claim(
		address user,
		uint256 amount,
		bytes calldata
	) external override onlyOwner returns (address, uint256) {
		// validate
		require(amount > 0, "Claiming amount must be greater than 0");
		require(amount <= counts[user], "Insufficient balance");

		uint256 shares = amount * SHARES_PER_TOKEN;
		emit Claimed(user, address(_token), amount, shares);
		return (user, shares);
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	function update(address) external override {}

	/**
	 * @inheritdoc IStakingModule
	 */
	function clean() external override {}
}