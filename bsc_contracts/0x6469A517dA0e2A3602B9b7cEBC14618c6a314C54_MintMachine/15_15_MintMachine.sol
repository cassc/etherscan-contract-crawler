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
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./interfaces/IXNFT.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract MintMachine is ReentrancyGuard, Pausable, ERC1155Holder
{
	using SafeERC20 for IERC20;

	address public address_operator;

	uint256 public mint_start_block_id;
	uint256 public mint_price=150;
	uint256 public amount_bonus_count=10;
	address	public address_nft;
	
	address public address_deposit_token;
	address public address_deposit_vault;

	uint256[] public gacha_prob_table_e4=[6500, 2500, 1000];

	uint256[3] public mint_total_amount_list;
	mapping(address => uint256[]) public mint_log;

	//---------------------------------------------------------------
	// Front-end connectors
	//---------------------------------------------------------------
	event PauseCB(address indexed operator);
	event ResumeCB(address indexed operator);
	event SetOperatorCB(address indexed operator, address _new_operator);
	event SetMintPriceCB(address indexed operator, uint256 _new_mint_price);
	event SetMintStartBlockID(address indexed operator, uint256 _mint_start_block_id);
	event SetTokenVaultCB(address indexed operator, address _token_vault);
	event GachaCB(address indexed user, uint256 _cur_mint_amount);
	event SetAmountBonusCB(address indexed user, uint256 _bonus_count);

	//---------------------------------------------------------------
	// Modifier
	//---------------------------------------------------------------
	modifier onlyOperator() { require(msg.sender == address_operator, "onlyOperator: Not authorized"); _; }

	//---------------------------------------------------------------
	// Variable Interfaces
	//---------------------------------------------------------------
	function set_operator(address _new_operator) external onlyOperator
	{
		require(_new_operator != address(0), "set_address_reward_token: Wrong address");
		address_operator = _new_operator;
		emit SetOperatorCB(msg.sender, _new_operator);
	}

	function set_mint_price(uint256 _new_mint_price) external onlyOperator
	{
		require(_new_mint_price > 0, "set_mint_price: Wrong price");
		mint_price = _new_mint_price;
		emit SetMintPriceCB(msg.sender, _new_mint_price);
	}

	function set_mint_start_block_id(uint256 _mint_start_block_id) external onlyOperator
	{
		mint_start_block_id = _mint_start_block_id;
		emit SetMintStartBlockID(msg.sender, _mint_start_block_id);
	}

	function set_token_vault(address _address_token_vault) external onlyOperator
	{
		address_deposit_vault = _address_token_vault;
		emit SetTokenVaultCB(msg.sender, _address_token_vault);
	}

	function get_minted_total_amount() external view returns(uint256)
	{
		uint256 total_count = 0;
		for(uint256 i=0; i < mint_total_amount_list.length; i++)
			total_count += mint_total_amount_list[i];
		return total_count;
	}
	
	function get_minted_amount() external view returns(uint256)
	{
		return mint_log[msg.sender].length;
	}

	function set_amount_bonus(uint256 _bonus_count) external onlyOperator
	{
		amount_bonus_count = _bonus_count;
		emit SetAmountBonusCB(msg.sender, _bonus_count);
	}

	//---------------------------------------------------------------
	// External Method
	//---------------------------------------------------------------
	constructor(address _address_xnft, address _deposit_token, address _address_deposit_vault, uint256 _price, uint256 _mint_start_block_id)
	{
		uint256 total_gacha_prob=0;
		for(uint16 i=0; i<gacha_prob_table_e4.length; i++)
			total_gacha_prob += gacha_prob_table_e4[i];

		require(total_gacha_prob == 10000, "constructor: Wrong probability for gacha");

		address_operator = msg.sender;

		address_nft = _address_xnft;
		address_deposit_token = _deposit_token;
		address_deposit_vault = _address_deposit_vault;
		mint_price = _price;
		mint_start_block_id = (block.number > _mint_start_block_id)? block.number : _mint_start_block_id;
	}

	function gacha(uint256 _amount) public nonReentrant whenNotPaused returns(uint256)
	{
		require(_amount > 0, "gacha: Wrong amount");

		address address_user = msg.sender;
		IXNFT nft = IXNFT(address_nft);
		IERC20 deposit_token = IERC20(address_deposit_token);

		uint256 bonus_count = _amount / amount_bonus_count;
		uint256 gacha_count = _amount + bonus_count;
		for(uint256 i=0; i<gacha_count; i++)
		{
			if(i < _amount) // except bonus gacha
				deposit_token.safeTransferFrom(address_user, address_deposit_vault, mint_price);

			uint16 grade = _get_random_grade();

			uint256 mint_serial = mint_total_amount_list[grade];
			nft.mint(address(this), mint_serial, 1, grade);

			uint256 level_id_prefix = grade * 1e6; // 1000000, 2000000 ...
			uint256 mint_id = level_id_prefix + mint_serial;
			
			mint_log[address_user].push(mint_id);

			nft.safeTransferFrom(address(this), address_user, mint_id, 1, "");
			mint_total_amount_list[grade] += 1;
		}

		emit GachaCB(address_user, gacha_count);
		return gacha_count;
	}

	function pause() external onlyOperator
	{ 
		_pause(); 
		emit PauseCB(msg.sender);
	}
	
	function resume() external onlyOperator
	{ 
		_unpause();
		emit ResumeCB(msg.sender);
	}

	//---------------------------------------------------------------
	// Internal Method
	//---------------------------------------------------------------
	function _get_random_grade() internal view returns(uint16)
	{
		uint256 random_hash = uint256(keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp)));
		uint256 lucky_pot = random_hash % 10000; // 100.00% (0~9999)
			
		// Finding grade
		uint256 cur_scope;
		for(uint16 g=0; g < gacha_prob_table_e4.length; g++)
		{
			cur_scope += gacha_prob_table_e4[g]; // 6500 -> 9000 -> 10000
			if(lucky_pot < cur_scope)
				return g+1;
		}

		return 1; // exception
	}
}