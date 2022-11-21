// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Exchange {
  
	IERC20 coin1;
	IERC20 coin2;

	address Owner;

  bool stopped = false;

	event Exchanged(
		address indexed who, 
		uint256 indexed amountIn, 
		uint256 indexed amountOut
	); 

	constructor(IERC20 _coin1, IERC20 _coin2, address _owner) {
		coin1 = _coin1;
		coin2 = _coin2;
		Owner = _owner;
	}

	function executeExchange(uint256 amountIn) public {
    require(!stopped, "Contract is currently stopped");
    address sender = msg.sender;
		uint256 amountOut = amountIn * 10**10;
		require(coin1.balanceOf(sender) >= amountIn, 
						"You do not have enough tokens to exchange.");
		require(coin2.balanceOf(address(this)) >= amountOut, 
						"Contract does not have enough tokens to exchange.");
		coin1.transferFrom(sender, address(this), amountIn);
		coin2.transfer(sender, amountOut);
		emit Exchanged(sender, amountIn, amountOut);
	}
	
	function changeOwner(address _newOwner) public {
		require(msg.sender == Owner, "You are not the Owner!");
		Owner = _newOwner;
	}

	function changeStop(bool _status) public {
		require(msg.sender == Owner, "You are not the Owner!");
    stopped = _status;
  }

	function withdrawCoin1() public {
		require(msg.sender == Owner, "You are not the Owner!");
		uint256 _balance = coin1.balanceOf(address(this));
		coin1.transfer(Owner, _balance);
	}

	function withdrawCoin2() public {
		require(msg.sender == Owner, "You are not the Owner!");
		uint256 _balance = coin2.balanceOf(address(this));
		coin2.transfer(Owner, _balance);
	}
}