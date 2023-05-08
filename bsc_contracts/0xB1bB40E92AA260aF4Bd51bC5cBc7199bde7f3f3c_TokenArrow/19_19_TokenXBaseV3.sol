// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

import "./interfaces/IChick.sol";
import "./interfaces/IXNFTBase.sol";
import "./interfaces/IXNFTHolder.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract TokenXBaseV3 is ERC20, Ownable
{
	using SafeERC20 for IERC20;

	uint256 public constant MAX_TAX_BUY = 50100; // 5%
	uint256 public constant MAX_TAX_SELL = 200100; // 20%

	uint256 public constant TAX_FREE = 888888; // 888888 means zero tax in this code

	address public constant ADDRESS_BURN = 0x000000000000000000000000000000000000dEaD;

	uint256 public total_supply_limit;

	address public address_operator;
	address[] public address_controllers;
	mapping(address => bool) public is_controller;

	address public address_xnft;
	
	// Black List
	mapping(address => bool) private is_send_blocked;
	mapping(address => bool) private is_recv_blocked;
	mapping(address => bool) private is_sell_blocked;

	mapping(address => uint256) private send_limit_amount;

	// Tax Controller
	address private address_chick;

	uint256 public tax_rate_send_e6; // send is sell
	uint256 public tax_rate_send_with_nft_e6;

	uint256 public tax_rate_recv_e6; // recv is buy
	uint256 public tax_rate_recv_with_nft_e6;

	mapping(address => bool) private is_tax_free;
	mapping(address => bool) private is_intenal_address;

	address public constant ADDRESS_BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
	address public constant ADDRESS_PANCAKESWAP_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
	IUniswapV2Router02 public PancakeRouter = IUniswapV2Router02(ADDRESS_PANCAKESWAP_ROUTER);

	address public address_busd_pair;
	address public address_wbnb_pair;

	//---------------------------------------------------------------
	// Front-end connectors
	//---------------------------------------------------------------
	event SetOperatorCB(address indexed operator, address _new_address_operator);
	event SetControllerCB(address indexed operator, address _controller);
	event SetChickCB(address indexed operator, address _chick);

	event SetSendTaxCB(address indexed operator, uint256 _tax_rate, uint256 _tax_with_nft_rate);
	event SetRecvTaxCB(address indexed operator, uint256 _tax_rate, uint256 _tax_with_nft_rate);
	event SetTaxFreeCB(address indexed operator, address _address, bool _is_free);
	event SetSellAmountLimitCB(address indexed operator, address _lp_address, uint256 _limit);
	
	event ToggleBlockSendCB(address indexed operator, address[] _accounts, bool _is_blocked);
	event ToggleBlockRecvCB(address indexed operator, address[] _accounts, bool _is_blocked);

	//---------------------------------------------------------------
	// Modifier
	//---------------------------------------------------------------
	modifier onlyOperator() { require(address_operator == msg.sender, "onlyOperator: caller is not the operator");	_; }
	modifier onlyController() { require(is_controller[msg.sender] == true, "onlyController: caller is not the controller"); _; }

	//---------------------------------------------------------------
	// External Method
	//---------------------------------------------------------------
	constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol)
	{
		address_operator = msg.sender;

		is_tax_free[address_operator] = true;
		is_tax_free[ADDRESS_BURN] = true;

		address_wbnb_pair = IUniswapV2Factory(PancakeRouter.factory()).createPair(address(this), PancakeRouter.WETH());
		address_busd_pair = IUniswapV2Factory(PancakeRouter.factory()).createPair(address(this), ADDRESS_BUSD);
	}

	function mint(address _to, uint256 _amount) external onlyController
	{
		require(total_supply_limit == 0 || totalSupply()+_amount < total_supply_limit, "mint: limit exceed");
		_mint(_to, _amount);
	}

	function burn(uint256 _amount) external onlyOwner
	{
		_burn(msg.sender, _amount);
	}

	//---------------------------------------------------------------
	// Internal Method
	//---------------------------------------------------------------
	function _transfer(address sender, address recipient, uint256 amount) internal virtual override
	{
		require(sender != address(0), "_transfer: Wrong sender address");
		require(recipient != address(0), "_transfer: Wrong recipient address");

		require(!is_send_blocked[sender], "_transfer: Sender is blocked by contract.");
		require(!is_recv_blocked[recipient], "_transfer: Recipient is blocked by contract.");

		require(_is_lp_address(recipient) == false || send_limit_amount[sender] == 0 || amount <= send_limit_amount[sender],
			"_check_send_limit: limit exceed");

		uint256 cur_tax_rate_e6 = _get_tax_rate_e6(sender, recipient); // sell, buy tax		
		if(cur_tax_rate_e6 == TAX_FREE || address_chick == address(0))
			super._transfer(sender, recipient, amount);
		else
		{
			uint256 tax_amount = (amount * cur_tax_rate_e6) / 1e6;
			uint256 final_send_amount = amount - tax_amount;

			super._transfer(sender, address_chick, tax_amount);
			super._transfer(sender, recipient, final_send_amount);

			if(tax_amount > 0)
				IChick(address_chick).make_juice(address(this));
		}
	}
	
	function _get_tax_rate_e6(address _from, address _to) internal view returns(uint256)
	{		
		uint256 tax_rate_e6 = TAX_FREE;

 		// LP -> User // Buy
		if(_is_lp_address(_from) && !is_tax_free[_to])
		{
			if(_has_xnft(_to) == true)
				tax_rate_e6 = tax_rate_send_with_nft_e6;
			else
				tax_rate_e6 = tax_rate_send_e6;

		} // User -> LP // Sell
		else if(_is_lp_address(_to) && !is_tax_free[_from]) 
		{
			if(_has_xnft(_from) == true)
				tax_rate_e6 = tax_rate_recv_with_nft_e6;
			else
				tax_rate_e6 = tax_rate_recv_e6;
		}

		return tax_rate_e6;
	}

	function _is_lp_address(address _address_contract) internal view returns(bool)
	{
		return (address_wbnb_pair != address(0) && address_wbnb_pair == _address_contract) ||
			(address_busd_pair != address(0) && address_busd_pair == _address_contract);
	}

	function _has_xnft(address _owner) public view returns(bool) 
	{
		if(address_xnft == address(0)) return false;
		
		IXNFTBase xnft = IXNFTBase(address_xnft);

		// !!! uint256[] id_list = xnft.get_my_id_list(); // XNFT v2
		uint256[] memory id_list = xnft.get_list(1);
		if(id_list.length > 0 && id_list[0] != 0)
			return true;

		for(uint256 i=0; i<address_controllers.length; i++)
		{
			if(is_controller[address_controllers[i]] == false)
				continue;

			IXNFTHolder holder = IXNFTHolder(address_controllers[i]);
			if(address(holder) == address(0))
				continue;

			uint256 staked_amount = holder.user_total_staked_amount(_owner);
			if(staked_amount > 0)
				return true;
		}

		return false;
	}

	function _set_internal_address(address _address, bool _is_set) private
	{
		if(_address != address(0))
		{
			is_intenal_address[_address] = _is_set;
			is_tax_free[_address] = _is_set;
		}
	}

	//---------------------------------------------------------------
	// Setters
	//---------------------------------------------------------------
	function set_operator(address _new_address) public onlyOperator
	{
		_set_internal_address(address_operator, false);
		_set_internal_address(_new_address, true);

		address_operator = _new_address;

		emit SetOperatorCB(msg.sender, _new_address);
	}

	function set_controller(address _new_address, bool _is_set) public onlyOperator
	{
		require(_new_address != address(0), "set_controller: Wrong address");

		_set_internal_address(_new_address, _is_set);
		is_controller[_new_address] = _is_set;
		
		if(_is_set == true)
			address_controllers.push(_new_address);

		emit SetControllerCB(msg.sender, _new_address);
	}

	function set_chick(address _new_chick) public onlyOperator
	{
		_set_internal_address(address_chick, false);		
		_set_internal_address(_new_chick, true);

		address_chick = _new_chick;

		emit SetChickCB(msg.sender, address_chick);
	}

	function set_total_supply_limit(uint256 _amount) public onlyOperator
	{
		total_supply_limit = _amount;
	}

	function set_tax_free(address _to, bool _is_free) public onlyOperator
	{
		require(_to != address(0), "set_send_tax_free: Wrong address");
		is_tax_free[_to] = _is_free;

		emit SetTaxFreeCB(msg.sender, _to, _is_free);
	}

	function set_sell_amount_limit(address _address_to_limit, uint256 _limit) public onlyOperator
	{
		require(_address_to_limit != address(0), "set_sell_amount_limit: Wrong address");
		require(_limit > totalSupply() / 1000, "set_sell_amount_limit: Wrong limit"); // 0.1% of totalSupply

		send_limit_amount[_address_to_limit] = _limit;
		emit SetSellAmountLimitCB(msg.sender, _address_to_limit, _limit);
	}

	function toggle_block_send(address[] memory _accounts, bool _is_blocked) external onlyOperator
	{
		for(uint256 i=0; i < _accounts.length; i++)
			is_send_blocked[_accounts[i]] = _is_blocked;
		
		emit ToggleBlockSendCB(msg.sender, _accounts, _is_blocked);
	}

	function toggle_block_recv(address[] memory _accounts, bool _is_blocked) external onlyOperator
	{
		for(uint256 i=0; i < _accounts.length; i++)
			is_recv_blocked[_accounts[i]] = _is_blocked;
		
		emit ToggleBlockRecvCB(msg.sender, _accounts, _is_blocked);
	}

	function set_send_tax_e6(uint256 _tax_rate, uint256 _tax_with_nft_rate) public onlyOperator
	{
		require(_tax_rate < MAX_TAX_SELL, "set_send_tax_e6: tax rate manimum exceeded.");
		require(_tax_with_nft_rate < MAX_TAX_SELL, "set_send_tax_e6: tax rate manimum exceeded.");

		tax_rate_send_e6 = _tax_rate;
		tax_rate_send_with_nft_e6 = _tax_with_nft_rate;
		emit SetSendTaxCB(msg.sender, _tax_rate, _tax_with_nft_rate);
	}
	
	function set_recv_tax_e6(uint256 _tax_rate, uint256 _tax_with_nft_rate) public onlyOperator
	{
		require(_tax_rate < MAX_TAX_BUY, "set_recv_tax_e6: tax rate manimum exceeded.");
		require(_tax_with_nft_rate < MAX_TAX_BUY, "set_recv_tax_e6: tax rate manimum exceeded.");

		tax_rate_recv_e6 = _tax_rate;
		tax_rate_recv_with_nft_e6 = _tax_with_nft_rate;
		emit SetRecvTaxCB(msg.sender, _tax_rate, _tax_with_nft_rate);
	}

	function set_address_xnft(address _address_xnft) external onlyOperator
	{
		require(_address_xnft != address(0), "set_address_xnft: Wrong address");
		address_xnft = _address_xnft;
	}
}