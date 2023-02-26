// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "./interfaces/IPancakeswapFarm.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract CakeBaker is ReentrancyGuard, Pausable
{
	using SafeERC20 for IERC20;

	address public constant ADDRESS_PANCAKE_ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
	IUniswapV2Router02 public constant PancakeRouter = IUniswapV2Router02(ADDRESS_PANCAKE_ROUTER);

	struct PancakeFarm
	{
		uint256 pool_id;
		address address_token_reward; // e.g CAKE on pancakeswap
		uint256 lp_locked_amount;
		uint256 last_rewarded_block_id;
	}
	
	address public address_operator;
	address public address_controller1;
	address public address_controller2;
	address public address_reward_vault;

	mapping(address => PancakeFarm) pancake_pool_list; // address 
	address[] public address_pancake_pool_list; // https://pancakeswap.finance/farms

	//---------------------------------------------------------------
	// Front-end connectors
	//---------------------------------------------------------------
	event SetAddressFeeCB(address indexed operator, address _new_address);
	event SetAddressRewardTokenCB(address indexed operator, address _new_address);
	event SetOperatorCB(address indexed operator, address _new_address);
	event SetControllerCB(address indexed operator, address _new_address1, address _new_address2);
	event SetPancakeFarmCB(address indexed operator, address _new_address);
	event DelegateCB(address indexed operator, uint256 _amount);
	event RetainCB(address indexed operator, uint256 _amount);
	event HarvestCB(address indexed operator);
	event HandleStuckCB(address indexed operator, address _token, uint256 _amount, address _to);
	event AddPancakeFarmCB(address indexed operator, uint256 _pool_id, address _address_lp, address _address_reward);

	//---------------------------------------------------------------
	// Modifier
	//---------------------------------------------------------------
	modifier onlyOperator() { require(msg.sender == address_operator, "onlyOperator: Not authorized"); _; }
	modifier onlyController() { require(msg.sender == address_controller1 || msg.sender == address_controller2, "onlyController: caller is not the controller"); _; }

	//---------------------------------------------------------------
	// Variable Interfaces
	//---------------------------------------------------------------
	function set_address_reward_vault(address _new_address) external onlyOperator
	{
		require(_new_address != address(0), "set_address_reward_vault: Wrong address");
		address_reward_vault = _new_address;
		emit SetAddressFeeCB(msg.sender, _new_address);
	}

	function set_operator(address _new_address) external onlyOperator
	{
		require(_new_address != address(0), "set_address_token_reward: Wrong address");
		address_operator = _new_address;
		emit SetOperatorCB(msg.sender, _new_address);
	}

	function set_controller(address _address_ctrl1, address _address_ctrl2) public onlyOperator
	{
		require(address_controller1 == address(0), "set_controller: Already set");
		require(address_controller2 == address(0), "set_controller: Already set");

		require(_address_ctrl1 != address(0), "set_controller: Wrong address");
		require(_address_ctrl2 != address(0), "set_controller: Wrong address");

		address_controller1 = _address_ctrl1;
		address_controller2 = _address_ctrl2;

		emit SetControllerCB(msg.sender, address_controller1, address_controller2);
	}

	//---------------------------------------------------------------
	// External Method
	//---------------------------------------------------------------
	constructor(address _address_reward_vault)
	{
		require(_address_reward_vault != address(0), "constructor: Wrong address");

		address_operator = msg.sender;
		address_reward_vault = _address_reward_vault;
	}

	function add_pancake_farm(uint256 _pool_id, address _address_lp, address _address_token_reward) external
		onlyOperator returns(uint256)
	{
		require(_address_lp != address(0), "add_pancake_farm: Wrong address");
		require(_address_token_reward != address(0), "add_pancake_farm: Wrong address");

		pancake_pool_list[_address_lp] = PancakeFarm({
			pool_id: _pool_id,
			address_token_reward: _address_token_reward,
			lp_locked_amount: 0,
			last_rewarded_block_id: 0
		});
		
		address_pancake_pool_list.push(_address_lp);
		
		emit AddPancakeFarmCB(msg.sender, _pool_id, _address_lp, _address_token_reward);
		return address_pancake_pool_list.length;
	}

	function delegate(address _address_lp_vault, address _address_lp, uint256 _amount) external 
		whenNotPaused nonReentrant onlyController returns(uint256)
	{
		require(_address_lp != address(0), "deposit: Wrong address");
		require(_address_lp_vault != address(0), "deposit: Wrong address");

		uint256 cur_pool_id = pancake_pool_list[_address_lp].pool_id;
		if(cur_pool_id == 0 || _amount == 0)
			return 0;

		_collect_reward(pancake_pool_list[_address_lp]);

		// LP Vault -> CakeBaker
		IERC20 lp_token = IERC20(_address_lp);
		uint256 balance_prev = lp_token.balanceOf(address(this));
		lp_token.safeTransferFrom(_address_lp_vault, address(this), _amount);

		uint256 balance_cur = lp_token.balanceOf(address(this));
		uint256 balance_diff = balance_cur - balance_prev;

		pancake_pool_list[_address_lp].lp_locked_amount += balance_diff;

		// CakeBaker -> Pancake
		lp_token.safeIncreaseAllowance(_address_lp, balance_diff);
		IPancakeswapFarm(_address_lp).deposit(cur_pool_id, balance_diff);

		emit DelegateCB(msg.sender, _amount);
		return balance_diff;
	}

	function retain(address _address_lp_vault, address _address_lp, uint256 _amount) external 
		nonReentrant onlyController returns(uint256)
	{
		require(_address_lp != address(0), "deposit: Wrong address");
		require(_address_lp_vault != address(0), "deposit: Wrong address");

		uint256 cur_pool_id = pancake_pool_list[_address_lp].pool_id;
		if(cur_pool_id == 0 || _amount == 0)
			return 0;

		_collect_reward(pancake_pool_list[_address_lp]);

		IERC20 lp_token = IERC20(_address_lp);
		uint256 lp_balance = lp_token.balanceOf(address(this));

		uint256 withdraw_amount = (_amount > lp_balance)? lp_balance : _amount;
		if(withdraw_amount > pancake_pool_list[_address_lp].lp_locked_amount)
			withdraw_amount = pancake_pool_list[_address_lp].lp_locked_amount;

		// Pancake -> CakeBaker
		IPancakeswapFarm(_address_lp).withdraw(cur_pool_id, withdraw_amount);

		// CakeBaker -> LP Vault
		lp_token.safeTransfer(_address_lp_vault, withdraw_amount);
		pancake_pool_list[_address_lp].lp_locked_amount -= withdraw_amount;

		emit RetainCB(msg.sender, _amount);
		return withdraw_amount;
	}

	function harvest() external nonReentrant
	{
		for(uint256 i=0; i<address_pancake_pool_list.length; i++)
			_collect_reward(pancake_pool_list[address_pancake_pool_list[i]]);

		emit HarvestCB(msg.sender);
	}

	function handle_stuck(address _token, uint256 _amount, address _to) public onlyOperator nonReentrant
	{
		IERC20(_token).safeTransfer(_to, _amount);
		emit HandleStuckCB(msg.sender, _token, _amount, _to);
	}

	function pause() external onlyOperator
	{ 
		_pause(); 
	}
	
	function resume() external onlyOperator
	{ 
		_unpause();
	}

	//---------------------------------------------------------------
	// Internal Method
	//---------------------------------------------------------------
	function _get_approve_token(address _address_token) private nonReentrant
	{
		IERC20 token = IERC20(_address_token);
		if(token.allowance(address(this), address(PancakeRouter)) == 0)
			token.safeApprove(address(PancakeRouter), type(uint256).max);
	}

	function _collect_reward(PancakeFarm storage _pool_info) private nonReentrant
	{
		require(_pool_info.address_token_reward != address(0), "_collect_reward: reward address is wrong.");

		IPancakeswapFarm pancake_pool = IPancakeswapFarm(address_pancake_pool_list[_pool_info.pool_id]);
		pancake_pool.withdraw(_pool_info.pool_id, 0);

		IERC20 reward_token = IERC20(_pool_info.address_token_reward);
		uint256 total_earned = reward_token.balanceOf(address(this));
		reward_token.safeTransfer(address_reward_vault, total_earned);

		_pool_info.last_rewarded_block_id = block.number;
	}	
}