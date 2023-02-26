// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "./interfaces/IXNFTBase.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract MintMachine is ReentrancyGuard, Pausable
{
	using SafeERC20 for IERC20;

	address public address_operator;

	uint256 public mint_start_block_id;
	uint256 public mint_end_block_id;

	uint256 public mint_price;
	uint256 public bouns_per_amount;
	
	address public address_deposit_token;
	address public address_deposit_vault;

	address public address_reward_vault;

	struct RewardInfo
	{
		uint256 gacha_probability_e6;

		bool is_nft;
		address address_reward_token;
		uint256 amount_or_grade;
		
		uint256 accu_reward_amount;
	}

	struct GachaLog
	{
		uint256 total_deposit_amount;
		uint256 total_atari_amount;
		uint256 bonus_mileage;
	}
	
	RewardInfo[] public reward_info;
	mapping(address => GachaLog) public log_gacha;

	//---------------------------------------------------------------
	// Front-end connectors
	//---------------------------------------------------------------
	event SetOperatorCB(address indexed operator, address _new_operator);
	event SetMintPriceCB(address indexed operator, address _address_deposit_token, uint256 _new_mint_price);
	event SetTokenVaultCB(address indexed operator, address _token_vault);
	event GachaCB(address indexed user, uint256 _cur_mint_amount);
	event SetAmountBonusCB(address indexed operator, uint256 _bonus_count);
	event SetPeriodCB(address indexed operator, uint256 _mint_start_block_id, uint256 _mint_end_block_id);
	event TestRandomCB(address indexed operator, uint256 random_number);

	//---------------------------------------------------------------
	// Modifier
	//---------------------------------------------------------------
	modifier onlyOperator() { require(msg.sender == address_operator, "onlyOperator: Not authorized"); _; }
	
	//---------------------------------------------------------------
	// External Method
	//---------------------------------------------------------------
	constructor(address _address_deposit_vault, address _address_reward_vault)
	{
		address_operator = msg.sender;
		address_deposit_vault = _address_deposit_vault;
		address_reward_vault = _address_reward_vault;
	}

	function make_reward(uint256 _prob_e6, bool _is_nft, address _address_token_reward, uint256 _amount_or_grade) external onlyOperator
	{
		require(_prob_e6 > 0, "make_reward: Wrong probability");
		require(_amount_or_grade > 0, "make_reward: Wrong amount or grade");
		require(_address_token_reward != address(0), "make_reward: Wrong address");

		uint256 total_gacha_prob=0;
		for(uint256 i=0; i<reward_info.length; i++)
			total_gacha_prob += reward_info[i].gacha_probability_e6;

		require(total_gacha_prob + _prob_e6 <= 1000000, "constructor: Wrong probability for gacha");

		reward_info.push(RewardInfo({
			gacha_probability_e6: _prob_e6,

			is_nft: _is_nft,
			address_reward_token: _address_token_reward,
			amount_or_grade: _amount_or_grade,

			accu_reward_amount: 0
		}));
	}

	function gacha(uint256 _amount) external nonReentrant whenNotPaused
	{
		require(_amount > 0, "gacha: Wrong amount");
		//require(block.number <= mint_end_block_id, "gacha: the end");
		require(mint_price > 0 && address_deposit_token != address(0), "gacha: Wrong token address");

		address address_user = msg.sender;
		IERC20 deposit_token = IERC20(address_deposit_token);

		GachaLog storage log = log_gacha[address_user];

		uint256 bonus_count = (bouns_per_amount > 0)? ((log.bonus_mileage + _amount) / bouns_per_amount) : 0;		
		uint256 cur_atari_amount = 0;

		uint256 gacha_count = _amount + bonus_count;
		for(uint256 i=0; i<gacha_count; i++)
		{
			if(i < _amount) // is not free?
				deposit_token.safeTransferFrom(address_user, address_deposit_vault, mint_price);

			uint256 reward_serial = _get_random_reward_serial();
			if(reward_serial < reward_info.length)
			{
				_deploy_reward(reward_serial, address_user);
				cur_atari_amount += 1;
			}
		}

		log.total_deposit_amount += _amount;
		log.total_atari_amount += cur_atari_amount;
		log.bonus_mileage = (bonus_count > 0)? 
			(log.bonus_mileage - (bonus_count * bouns_per_amount)) :
			(log.bonus_mileage + _amount);

		emit GachaCB(address_user, cur_atari_amount);
	}

	function gacha_test(uint256 _amount) external nonReentrant whenNotPaused
	{
		require(_amount > 0, "gacha: Wrong amount");
		//require(block.number <= mint_end_block_id, "gacha: the end");
		require(mint_price > 0 && address_deposit_token != address(0), "gacha: Wrong token address");

		address address_user = msg.sender;
		IERC20 deposit_token = IERC20(address_deposit_token);

		GachaLog storage log = log_gacha[address_user];

		uint256 bonus_count = (bouns_per_amount > 0)? ((log.bonus_mileage + _amount) / bouns_per_amount) : 0;		
		uint256 cur_atari_amount = 0;

		uint256 gacha_count = _amount + bonus_count;
		for(uint256 i=0; i<gacha_count; i++)
		{
			if(i < _amount) // is not free?
				deposit_token.safeTransferFrom(address_user, address_deposit_vault, mint_price);

			uint256 reward_serial = _get_random_reward_serial();
			if(reward_serial < reward_info.length)
			{
				_deploy_reward(reward_serial, address_user);
				cur_atari_amount += 1;
			}
		}

		log.total_deposit_amount += _amount;
		log.total_atari_amount += cur_atari_amount;
		log.bonus_mileage = (bonus_count > 0)? 
			(log.bonus_mileage - (bonus_count * bouns_per_amount)) :
			(log.bonus_mileage + _amount);

		emit GachaCB(address_user, cur_atari_amount);
	}

	function deploy_nft_with_random_test5() public
	{
		uint256 reward_serial = _get_random_reward_serial();
		if(reward_serial < reward_info.length)
			_deploy_reward(reward_serial, msg.sender);
	}

	function deploy_nft_with_random_test6() public
	{
		uint256 reward_serial = _get_random_reward_serial();
		if(reward_serial < reward_info.length)
			_deploy_reward(0, msg.sender);
	}

	function deploy_nft_with_random_test7() public
	{
		uint256 reward_serial = 0;
		if(reward_serial < reward_info.length)
			_deploy_reward(reward_serial, msg.sender);
	}

	function deploy_nft_with_random_test8() public
	{
		uint256 reward_serial = _get_random_reward_serial();
		if(reward_serial == reward_info.length)
			return;
			
		_deploy_reward(reward_serial, msg.sender);
	}

	function deploy_nft_with_random_test9() public
	{
		uint256 aa = _get_random_reward_serial();
		uint256 reward_serial = 0;
		if(reward_serial == reward_info.length)
			_deploy_reward(reward_serial, msg.sender);
	}

	//---------------------------------------------------------------
	// Internal Method
	//---------------------------------------------------------------
	function _get_random_reward_serial() internal view returns(uint256)
	{
		require(reward_info.length > 0, "_get_random_reward_serial: Wrong reward info");
		
		bytes32 keccak = keccak256(abi.encodePacked(msg.sender, block.timestamp, block.difficulty));
		uint256 random_hash = uint256(keccak);
		uint256 lucky_pot = random_hash % 1e6;

		uint256 cur_scope = 0;
		for(uint256 i=0; i < reward_info.length; i++)
		{
			cur_scope += reward_info[i].gacha_probability_e6; // 6500 -> 9000 -> 10000
			if(lucky_pot < cur_scope)
				return i;
		}

		return reward_info.length;
	}

	function _deploy_reward(uint256 _reward_serial, address _address_receiver) internal
	{
		require(_reward_serial < reward_info.length, "_deploy_reward: Wrong reward serial");

		RewardInfo storage reward = reward_info[_reward_serial];
		
		if(reward.is_nft == true)
			reward.accu_reward_amount += _deploy_xnft(reward, _address_receiver);
		else
			reward.accu_reward_amount += _deploy_erc20(reward, _address_receiver);
	}

	function _deploy_xnft(RewardInfo memory _reward, address _address_receiver) internal returns(uint256)
	{
		require(_reward.address_reward_token != address(0), "_deploy_xnft: Wrong reward vault address");

		IXNFTBase nft = IXNFTBase(_reward.address_reward_token);
		nft.mint(_address_receiver, _reward.amount_or_grade);
		
		return _reward.amount_or_grade;
	}
	
	function _deploy_erc20(RewardInfo memory _reward, address _address_receiver) internal returns(uint256)
	{
		require(address_reward_vault != address(0), "_deploy_erc20: Wrong reward vault address");
		require(_reward.address_reward_token != address(0), "_deploy_erc20: Wrong reward vault address");

		IERC20 reward_token = IERC20(_reward.address_reward_token);
		reward_token.safeTransferFrom(address_reward_vault, _address_receiver, _reward.amount_or_grade);
		
		return _reward.amount_or_grade;
	}
	
	//---------------------------------------------------------------
	// Variable Interfaces
	//---------------------------------------------------------------
	function set_operator(address _new_operator) external onlyOperator whenPaused
	{
		require(_new_operator != address(0), "set_address_reward_token: Wrong address");
		address_operator = _new_operator;
		emit SetOperatorCB(msg.sender, _new_operator);
	}

	function set_mint_price(address _address_deposit_token, uint256 _new_mint_price) external onlyOperator
	{
		require(_new_mint_price > 0, "set_mint_price: Wrong price");
		require(_address_deposit_token != address(0), "set_address_reward_token: Wrong address");
		
		address_deposit_token = _address_deposit_token;
		mint_price = _new_mint_price;

		emit SetMintPriceCB(msg.sender, address_deposit_token, _new_mint_price);
	}

	function set_token_vault(address _address_token_vault) external onlyOperator whenPaused
	{
		address_deposit_vault = _address_token_vault;
		emit SetTokenVaultCB(msg.sender, _address_token_vault);
	}

	function set_bouns_per_amount(uint256 _bonus_count) external onlyOperator whenPaused
	{
		bouns_per_amount = _bonus_count;
		emit SetAmountBonusCB(msg.sender, _bonus_count);
	}

	function set_period(uint256 _mint_start_block_id, uint256 _mint_end_block_id) external onlyOperator whenPaused
	{
		require(_mint_start_block_id < _mint_end_block_id, "set_period: Wrong block id");
		mint_start_block_id = (block.number > _mint_start_block_id)? block.number : _mint_start_block_id;
		mint_end_block_id = _mint_end_block_id;
		emit SetPeriodCB(msg.sender, _mint_start_block_id, _mint_end_block_id);
	}
	
	function pause() external onlyOperator
	{ 
		_pause(); 
	}
	
	function resume() external onlyOperator
	{ 
		_unpause();
	}
}