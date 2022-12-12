// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IChick.sol";
import "./interfaces/IBullish.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract TokenXBaseV3 is ERC20, Ownable
{
	uint256 public constant MAX_TAX_BUY = 501; // 5%
	uint256 public constant MAX_TAX_SELL = 2001; // 20%
	uint256 public constant TAX_FREE = 8888; // 8888 means zero tax in this code

	address public constant ADDRESS_BURN = 0x000000000000000000000000000000000000dEaD;

	address public address_operator;
	address public address_controller;
	address public address_chick;

	bool private chick_work = true;
	bool private is_chick_busy = false;

	uint256 internal tax_rate_send_e4 = MAX_TAX_SELL;
	uint256 internal tax_rate_recv_e4 = MAX_TAX_BUY;
	uint256 internal tax_rate_send_with_nft_e4 = MAX_TAX_SELL;
	uint256 internal tax_rate_recv_with_nft_e4 = MAX_TAX_BUY;
	
	mapping(address => bool) private is_send_blocked;
	mapping(address => bool) private is_recv_blocked;
	mapping(address => bool) private is_sell_blocked;

	mapping(address => bool) private is_tax_free_send;
	mapping(address => bool) private is_tax_free_recv;
	mapping(address => uint256) private send_limit_amount;

	mapping(address => bool) private is_address_lp;
	mapping(address => bool) private is_internal_contract;

	//---------------------------------------------------------------
	// Front-end connectors
	//---------------------------------------------------------------
	event SetOperatorCB(address indexed operator, address _new_address_operator, address _new_address);
	event SetControllerCB(address indexed operator, address _new_address_operator, address _new_address);
	event SetChickCB(address indexed operator, address _chick);
	event SetSendTaxFreeCB(address indexed operator, address _address, bool _is_free);
	event SetRecvTaxFreeCB(address indexed operator, address _address, bool _is_free);
	event SetNativeLPAddressCB(address indexed operator, address _lp_address, bool _is_enabled);
	event SetSellAmountLimitCB(address indexed operator, address _lp_address, uint256 _limit);
	event ToggleTransferPauseCB(address indexed operator, bool _is_paused);
	event ToggleBlockSendCB(address indexed operator, address[] _accounts, bool _is_blocked);
	event ToggleBlockRecvCB(address indexed operator, address[] _accounts, bool _is_blocked);
	event SetSendTaxCB(address indexed operator, uint256 _tax_rate, uint256 _tax_with_nft_rate);
	event SetRecvTaxCB(address indexed operator, uint256 _tax_rate, uint256 _tax_with_nft_rate);
	event SetChickWorkCB(address indexed operator, bool _is_work);

	//---------------------------------------------------------------
	// Modifier
	//---------------------------------------------------------------
	modifier onlyOperator() { require(address_operator == msg.sender, "onlyOperator: caller is not the operator");	_; }
	modifier onlyController() { require(address_controller == msg.sender, "onlyController: caller is not the controller");	_; }
	modifier onlyAdmin() { require(address_operator == msg.sender || address_controller == msg.sender, "onlyAdmin: caller is not the administrator");	_; }

	//---------------------------------------------------------------
	// Setters
	//---------------------------------------------------------------
	function set_operator(address _new_address) public onlyOperator
	{
		require(_new_address != address(0), "set_operator: Wrong address");

		exchange_internal_address(address_operator, _new_address);
		address_operator = _new_address;

		emit SetOperatorCB(msg.sender, address_operator, _new_address);
	}

	function set_controller(address _new_address) public onlyOperator
	{
		require(_new_address != address(0), "set_operator: Wrong address");

		exchange_internal_address(address_controller, _new_address);
		address_controller = _new_address;

		emit SetControllerCB(msg.sender, address_operator, _new_address);
	}

	function set_chick(address _new_chick) external onlyController
	{
		require(!is_chick_busy, "set_chick: the chick is working.");

		exchange_internal_address(address_chick, _new_chick);
		address_chick = _new_chick;

		emit SetChickCB(msg.sender, address_chick);
	}

	function set_send_tax_free(address _address, bool _is_free) public onlyOperator
	{
		require(_address != address(0), "set_send_tax_free: Wrong address");
		is_tax_free_send[_address] = _is_free;
		emit SetSendTaxFreeCB(msg.sender, _address, _is_free);
	}

	function set_recv_tax_free(address _address, bool _is_free) public onlyOperator
	{
		require(_address != address(0), "set_recv_tax_free: Wrong address");
		is_tax_free_recv[_address] = _is_free;
		emit SetRecvTaxFreeCB(msg.sender, _address, _is_free);
	}

	function set_lp_address(address _lp_address, bool _is_enabled) public onlyOperator
	{
		require(_lp_address != address(0), "set_native_lp_address_list: Wrong address");
		is_address_lp[_lp_address] = _is_enabled;
		emit SetNativeLPAddressCB(msg.sender, _lp_address, _is_enabled);
	}

	function set_sell_amount_limit(address _address_to_limit, uint256 _limit) public onlyOperator
	{
		require(_address_to_limit != address(0), "set_sell_amount_limit: Wrong address");
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

	function set_send_tax_e4(uint256 _tax_rate, uint256 _tax_with_nft_rate) public onlyOperator
	{
		require(_tax_rate < MAX_TAX_SELL, "set_send_tax_e4: tax rate manimum exceeded.");
		require(_tax_with_nft_rate < MAX_TAX_SELL, "set_send_tax_e4: tax rate manimum exceeded.");

		tax_rate_send_e4 = _tax_rate;
		tax_rate_send_with_nft_e4 = _tax_with_nft_rate;
		emit SetSendTaxCB(msg.sender, _tax_rate, _tax_with_nft_rate);
	}
	
	function set_recv_tax_e4(uint256 _tax_rate, uint256 _tax_with_nft_rate) public onlyOperator
	{
		require(_tax_rate < MAX_TAX_BUY, "set_recv_tax_e4: tax rate manimum exceeded.");
		require(_tax_with_nft_rate < MAX_TAX_BUY, "set_recv_tax_e4: tax rate manimum exceeded.");

		tax_rate_recv_e4 = _tax_rate;
		tax_rate_recv_with_nft_e4 = _tax_with_nft_rate;
		emit SetRecvTaxCB(msg.sender, _tax_rate, _tax_with_nft_rate);
	}

	function set_chick_work(bool _is_work) external onlyOperator
	{
		chick_work = _is_work;
		emit SetChickWorkCB(msg.sender, _is_work);
	}

	//---------------------------------------------------------------
	// External Method
	//---------------------------------------------------------------
	constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol)
	{
		address_operator = msg.sender;

		is_tax_free_send[address_operator] = true;
		is_tax_free_recv[address_operator] = true;

		is_tax_free_send[ADDRESS_BURN] = true;
		is_tax_free_recv[ADDRESS_BURN] = true;
	}

	function mint(address _to, uint256 _amount) external onlyController
	{
		super._mint(_to, _amount);
	}

	function burn(uint256 _amount) external onlyOwner
	{
		super._burn(msg.sender, _amount);
	}

	//---------------------------------------------------------------
	// Internal Method
	//---------------------------------------------------------------
	function _transfer(address sender, address recipient, uint256 amount) internal virtual override
	{
		require(sender != address(0), "_transfer: Wrong sender address");
		require(!is_send_blocked[sender], "_transfer: Sender is blocked by contract.");

		require(recipient != address(0), "_transfer: Wrong recipient address");
		require(!is_recv_blocked[recipient], "_transfer: Recipient is blocked by contract.");

		_check_send_limit(sender, recipient, amount);

		_make_juice_by_chick(sender, recipient);
		
		uint256 cur_tax_e4 = (chick_work == false)? TAX_FREE : _get_tax_rate_e4(sender, recipient);
		
		if(cur_tax_e4 == TAX_FREE)
			super._transfer(sender, recipient, amount);
		else
		{
			uint256 tax_amount = amount * cur_tax_e4 / 1e4;
			uint256 final_send_amount = amount - tax_amount;

			super._transfer(sender, address_chick, tax_amount);
			super._transfer(sender, recipient, final_send_amount);
		}
	}

	function _make_juice_by_chick(address _from, address _to) internal
	{
		if(chick_work == true && is_chick_busy == false && address_chick != address(0x0))
		{
			if(!is_internal_contract[_from] && !is_internal_contract[_to])
			{
				IChick chick = IChick(address_chick);
				is_chick_busy = true;
					chick.make_juice();
				is_chick_busy = false;
			}
		}
	}

	function _check_send_limit(address _from, address _to, uint256 _amount) internal view
	{
		if(is_address_lp[_to]) // User -> LP // Sell
			require(_amount <= send_limit_amount[_from], "_check_send_limit: Sender is sending-limited.");
	}

	function _get_tax_rate_e4(address _from, address _to) internal view returns(uint256)
	{		
		// 지갑에서 지갑으로 전송은 sell, buy가 아닌것으로 처리
		uint256 tax_rate_e4 = TAX_FREE;

		// LP에 들어오고 나간다는 것이 sell, buy를 말함
		// LP에서 들어오고 나가는건 무조건 택스를 떼되, 
		if(is_address_lp[_from]) // LP -> User // Buy
		{
			// 사이트에서 하는건 텍스를 안 떼게
			// (중간에 넘기는 놈 LPTool을 두고 그 놈을 화이트리스트 처리)
			if(!is_tax_free_send[_from])
				tax_rate_e4 = tax_rate_send_e4;
			else if(address_controller != address(0x0))
			{
				IBullish controller = IBullish(address_controller);
				if(controller.has_nft(_to))
					tax_rate_e4 = tax_rate_send_with_nft_e4;
			}
		}
		else if(is_address_lp[_to]) // User -> LP // Sell
		{
			if(!is_tax_free_recv[_from])
				tax_rate_e4 = tax_rate_recv_e4;
			else if(address_controller != address(0x0))
			{
				IBullish controller = IBullish(address_controller);
				if(controller.has_nft(_from))
					tax_rate_e4 = tax_rate_recv_with_nft_e4;
			}
		}

		return tax_rate_e4;
	}

	function exchange_internal_address(address _address_old, address _address_new) private
	{
		if(_address_old != address(0x0))
		{
			is_internal_contract[_address_old] = false;
			is_tax_free_send[_address_old] = false;
			is_tax_free_recv[_address_old] = false;
		}

		if(_address_new != address(0x0))
		{
			is_internal_contract[_address_new] = true;
			is_tax_free_send[_address_new] = true;
			is_tax_free_recv[_address_new] = true;			
		}
	}
}