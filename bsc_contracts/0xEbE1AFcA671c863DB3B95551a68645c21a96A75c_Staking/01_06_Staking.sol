//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


/// @title Staking contract with roles reachable by time and amount.
contract Staking is ERC20, Ownable {

    /// @notice Contract of the token to stake.
  	address public token;

	/// @notice how much and how long does it take to achieve the role.
	struct role {
		uint256 time; 
		uint256 amount;
	}

	/// @notice only 4 roles.
	role[4] public roles;

    /// @dev if the rol can't be reached return this constant.
	uint256 internal constant MAX_INT = 2**256 - 1;

    /// investment made by the user.
	/// handled time as timestamp,
	/// ´time´ when the stake was made.
	/// ´roleTreasure´ when the Treasure role would be reached.
	/// ´roleStructure´ when the Structure role would be reached.
	struct stake {
		uint256 time; 
		uint256[4] role;
	}

    /// @notice All stakes made.
	mapping (address => stake) public stakes;

	constructor (
		uint256 _supply, 
		address _token, 
		string memory name_, 
		string memory symbol_, 
		role memory _roles1,
		role memory _roles2,
		role memory _roles3,
		role memory _roles4
	) ERC20(name_, symbol_) {
		_mint(address(this), _supply);
		token = _token;

		// role initialitation
		roles[0] = _roles1;
		roles[1] = _roles2;
		roles[2] = _roles3;
		roles[3] = _roles4;
	}


	function setRole1(uint256 _time,uint256 _amount) public onlyOwner {
		roles[0].time=_time;
		roles[0].amount=_amount;
	}


	function setRole2(uint256 _time,uint256 _amount) public onlyOwner {
	roles[1].time=_time;
		roles[1].amount=_amount;
	}


	function setRole3(uint256 _time,uint256 _amount) public onlyOwner {
		roles[2].time=_time;
		roles[2].amount=_amount;
	}
	function setRole4(uint256 _time,uint256 _amount) public onlyOwner {
		roles[3].time=_time;
		roles[3].amount=_amount;
	}

 
    /// @notice Check ´_account´ role.
	/// Returns;
	/// 2 if the ´_account´ has the structure role,
	/// 1 if has treasure role,
	/// 0 otherwise.
	function getRole(address _account) public view returns(uint256) {
		if (block.timestamp >= stakes[_account].role[3] && stakes[_account].role[2] != 0 && stakes[_account].role[2] != MAX_INT) {
			return 4000000000000000000;
		} else if (block.timestamp >= stakes[_account].role[2] && stakes[_account].role[2] != 0 && stakes[_account].role[2] != MAX_INT) {
			return 3000000000000000000;
		} else if (block.timestamp >= stakes[_account].role[1] && stakes[_account].role[1] != 0 && stakes[_account].role[1] != MAX_INT) {
			return 2000000000000000000;
		} else if (block.timestamp >= stakes[_account].role[0] && stakes[_account].role[0] != 0 && stakes[_account].role[0] != MAX_INT) {
			return 1000000000000000000;
		} else {
			return 0;
		}
	}

    /// @notice Make a stake, sending ´_amount´ of ´token´ to this contract,
	/// and sending back the same amount of token of staking.
	/// note: require allowance of the token to stake.
	function staking(uint256 _amount) public {
		stake storage _stake = stakes[msg.sender];
		_stake.time = block.timestamp;
		/// fee posiblemnte procentual
		ERC20(this).transfer(msg.sender, _amount);
		_approve(msg.sender, address(this), allowance(msg.sender, address(this)) + _amount);
		ERC20(token).transferFrom(msg.sender, address(this), _amount);
		_stake.role[0] = ERC20(this).balanceOf(msg.sender) >= roles[0].amount ? // si cumple con el minimo de staking para el rol
			(_stake.role[0] == 0 || _stake.role[0] == MAX_INT ? // si no tiene rol asignado
				block.timestamp + roles[0].time:
				_stake.role[0]): 
			MAX_INT;
		_stake.role[1] = ERC20(this).balanceOf(msg.sender) >= roles[1].amount ? 
			(_stake.role[1] == 0 || _stake.role[1] == MAX_INT ?
				block.timestamp + roles[1].time:
				_stake.role[1]): 
			MAX_INT;
		_stake.role[2] = ERC20(this).balanceOf(msg.sender) >= roles[2].amount ?
			(_stake.role[2] == 0 || _stake.role[2] == MAX_INT ?
				block.timestamp + roles[2].time:
				_stake.role[2]): 
			MAX_INT;
		_stake.role[3] = ERC20(this).balanceOf(msg.sender) >= roles[3].amount ? 
			(_stake.role[3] == 0 || _stake.role[3] == MAX_INT ?
				block.timestamp + roles[3].time:
				_stake.role[3]):
			MAX_INT;

	}

    /// @notice Send back ´token´ staked, and transfer back the stake token.
	function withdraw(uint256 _amount) public {
		require(ERC20(this).balanceOf(msg.sender) >= _amount, "STAKE: no funds");
		stake storage _stake = stakes[msg.sender];
		ERC20(this).transferFrom(msg.sender, address(this), _amount);
		ERC20(token).transfer(msg.sender, _amount);
		_stake.role[0] = ERC20(this).balanceOf(msg.sender) >= roles[0].amount ? _stake.role[0] : MAX_INT;
		_stake.role[1] = ERC20(this).balanceOf(msg.sender) >= roles[1].amount ? _stake.role[1] : MAX_INT;
		_stake.role[2] = ERC20(this).balanceOf(msg.sender) >= roles[2].amount ? _stake.role[2] : MAX_INT;
		_stake.role[3] = ERC20(this).balanceOf(msg.sender) >= roles[3].amount ? _stake.role[3] : MAX_INT;
	}

}