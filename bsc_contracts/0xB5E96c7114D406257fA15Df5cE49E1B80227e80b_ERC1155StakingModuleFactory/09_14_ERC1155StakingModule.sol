/*
ERC1155StakingModule

https://github.com/FanbaseEU/Staking_Ethereum_SmartContracts

SPDX-License-Identifier: MIT
*/

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./interfaces/IStakingModule.sol";

/**
 * @title ERC721 staking module
 *
 * @notice this staking module allows users to deposit one or more ERC721
 * tokens in exchange for shares credited to their address. When the user
 * unstakes, these shares will be burned and a reward will be distributed.
 */
contract ERC1155StakingModule is IStakingModule {
	// constant
	uint256 public constant SHARES_PER_TOKEN = 10**18;
	mapping(uint256 => uint256) public sharePerTokenId;

	// members
	IERC1155 private immutable _token;
	address public immutable _factory;

	mapping(address => uint256) public userTotalBalance;
	mapping(address => mapping(uint256 => uint256)) public counts;
	mapping(uint256 => address) public owners;
	mapping(address => mapping(uint256 => uint256)) public tokenByOwner;
	mapping(uint256 => uint256) public tokenIndex;

	// newly defined
	uint256 private totalBalance;

	uint256[] public stakedTokenIds;

	event StakedERC1155(address user, address token, uint256[] tokenIds, uint256[] amounts, uint256 shares);

	// checksum
	bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
    bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

	/**
	 * @param token_ the token that will be rewarded
	 */
	constructor(address token_, address factory_) {
		require(
			IERC165(token_).supportsInterface(0xd9b67a26),
			"Interface ID not matched"
		);
		_token = IERC1155(token_);
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
		balances_[0] = userTotalBalance[user];
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
		totals_[0] = totalBalance;
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	// function stake(
	// 	address user,
	// 	uint256 amount,
	// 	bytes calldata data
	// ) external override onlyOwner returns (address, uint256) {
	// 	// validate
	// 	require(amount > 0, "Staking amount must be greater than 0");
	// 	require(amount <= _token.balanceOf(user), "Insufficient balance");
	// 	require(data.length == 32 * amount, "Invalid calldata");

	// 	uint256 count = counts[user];

	// 	// stake
	// 	for (uint256 i = 0; i < amount; i++) {
	// 		// get token id
	// 		uint256 id;
	// 		uint256 pos = 132 + 32 * i;
	// 		assembly {
	// 			id := calldataload(pos)
	// 		}

	// 		// ownership mappings
	// 		owners[id] = user;
	// 		uint256 len = count + i;
	// 		tokenByOwner[user][len] = id;
	// 		tokenIndex[id] = len;

	// 		// transfer to module
	// 		_token.transferFrom(user, address(this), id);
	// 	}

	// 	// update position
	// 	counts[user] = count + amount;

	// 	// emit
	// 	uint256 shares = amount * SHARES_PER_TOKEN;
	// 	emit Staked(user, address(_token), amount, shares);

	// 	return (user, shares);
	// }

	function stake(
		address user,
		uint256 amount,
		bytes calldata data
	) external override onlyOwner returns (address, uint256) {
		require(data.length == 32, "Invalid calldata");

		uint256 tokenId;

		assembly {
			tokenId := calldataload(68)
		}

		uint256 shares = amount * sharePerTokenId[tokenId];

		emit Staked(user, address(_token), amount, shares);
		return (user, shares);
	}

	function _stake(
		address user, 
		uint256[] memory tokenIds, 
		uint256[] memory amounts
	) 
		internal returns (address, uint256) {

		uint256 shares;

		for (uint256 i = 0; i < tokenIds.length; i++) {
			require(amounts[i] > 0, "Staking amount must be greater than 0");
			counts[user][tokenIds[i]] = counts[user][tokenIds[i]] + amounts[i];
			userTotalBalance[user] = userTotalBalance[user] + amounts[i];
			
			shares = shares + amounts[i] * sharePerTokenId[tokenIds[i]];

			totalBalance = totalBalance + amounts[i];

			stakedTokenIds.push(tokenIds[i]);
		}

		emit StakedERC1155(user, address(_token), tokenIds, amounts, shares);

		return (user, shares);
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	// function unstake(
	// 	address user,
	// 	uint256 amount,
	// 	bytes calldata data
	// ) external override onlyOwner returns (address, uint256) {
	// 	// validate
	// 	require(amount > 0, "Unstaking amount must be greater than 0");
	// 	uint256 count = counts[user];
	// 	require(amount <= count, "Insufficient staked balance");
	// 	require(data.length == 32 * amount, "Invalid calldata");

	// 	// unstake
	// 	for (uint256 i = 0; i < amount; i++) {
	// 		// get token id
	// 		uint256 id;
	// 		uint256 pos = 132 + 32 * i;
	// 		assembly {
	// 			id := calldataload(pos)
	// 		}

	// 		// ownership
	// 		require(owners[id] == user, "Only owner can unstake");
	// 		delete owners[id];

	// 		// clean up ownership mappings
	// 		uint256 lastIndex = count - 1 - i;
	// 		if (amount != count) {
	// 			// reindex on partial unstake
	// 			uint256 index = tokenIndex[id];
	// 			if (index != lastIndex) {
	// 				uint256 lastId = tokenByOwner[user][lastIndex];
	// 				tokenByOwner[user][index] = lastId;
	// 				tokenIndex[lastId] = index;
	// 			}
	// 		}
	// 		delete tokenByOwner[user][lastIndex];
	// 		delete tokenIndex[id];

	// 		// transfer to user
	// 		_token.safeTransferFrom(address(this), user, id);
	// 	}

	// 	// update position
	// 	counts[user] = count - amount;

	// 	// emit
	// 	uint256 shares = amount * SHARES_PER_TOKEN;
	// 	emit Unstaked(user, address(_token), amount, shares);

	// 	return (user, shares);
	// }

	function unstake(
		address user,
		uint256 amount,
		bytes calldata data
	) external override onlyOwner returns (address, uint256) {

		require(data.length == 32, "Invalid calldata");

		uint256 tokenId;

		assembly {
			tokenId := calldataload(68)
		}

		require(amount > 0, "Unstaking amount must be greater than 0");
		require(counts[user][tokenId] >= amount, "Insufficient staked balance");

		counts[user][tokenId] = counts[user][tokenId] - amount;
		userTotalBalance[user] = userTotalBalance[user] - amount;

		// decrease total balance
		totalBalance = totalBalance - amount;

		_token.safeTransferFrom(address(this), user, tokenId, amount, "");

		uint256 shares = amount * sharePerTokenId[tokenId];

		emit Unstaked(user, address(_token), amount, shares);
		return (user, shares);
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	// function claim(
	// 	address user,
	// 	uint256 amount,
	// 	bytes calldata
	// ) external override onlyOwner returns (address, uint256) {
	// 	// validate
	// 	require(amount > 0, "Claiming amount must be greater than 0");
	// 	require(amount <= counts[user], "Insufficient balance");

	// 	uint256 shares = amount * SHARES_PER_TOKEN;
	// 	emit Claimed(user, address(_token), amount, shares);
	// 	return (user, shares);
	// }

	function claim(
		address user, 
		uint256 amount, 
		bytes calldata data
	) external override onlyOwner returns (address, uint256) {
		require(data.length == 32, "Invalid calldata");
		
		require(amount > 0, "Claiming amount must be greater than 0");
		uint256 tokenId;

		assembly {
			tokenId := calldataload(68)
		}

		require(amount <= counts[user][tokenId], "Insufficient balance");

		uint256 shares = amount * sharePerTokenId[tokenId];
		emit Claimed(user, address(_token), amount, shares);
		return (user, shares);
	}

	function getStakedTokenIds() public view returns (uint256[] memory) {
		return stakedTokenIds;
	}

	/**
	 * @inheritdoc IStakingModule
	 */
	function update(address) external override {}

	/**
	 * @inheritdoc IStakingModule
	 */
	function clean() external override {}

	 /**
        ERC1155 receiver
     */
    function onERC1155Received(
		address _operator,
		address _from, 
		uint256 _id, 
		uint256 _amount, 
		bytes memory _data
	)
    public returns(bytes4)
    {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);

        ids[0] = _id;
        amounts[0] = _amount;

        require(
        ERC1155_BATCH_RECEIVED_VALUE == onERC1155BatchReceived(_operator, _from, ids, amounts, _data),
        "NE20#28"
        );

        return ERC1155_RECEIVED_VALUE;
    }

    function onERC1155BatchReceived(
        address, // _operator,
        address _from,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory)
    public returns(bytes4)
    {
        _stake(_from, _ids, _amounts);
        return ERC1155_BATCH_RECEIVED_VALUE;
    }
}