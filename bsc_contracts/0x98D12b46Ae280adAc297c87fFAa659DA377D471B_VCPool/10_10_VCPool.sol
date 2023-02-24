//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IVC is IERC20{
	function mint(address account, uint256 amount) external;
}

contract VCPool is OwnableUpgradeable, PausableUpgradeable,ReentrancyGuardUpgradeable {
	IVC public token;

	error NotEnoughBNB();
	error FailSendBNB();
	error FailSendToken();
	error ValueZero();

	function initialize(address _token) public initializer {
		__Ownable_init();
		__Pausable_init();
		__ReentrancyGuard_init();

		token = IVC(_token);
  }

	function swapBNB(uint amount) public whenNotPaused nonReentrant {
		uint outAmount = amount / 50000 ;
		if(!token.transferFrom(msg.sender, address(this), amount)) revert FailSendToken();
		if(bnbBalance() < outAmount) revert NotEnoughBNB();
		
		payable(msg.sender).transfer(outAmount);
	}

	function swapToken() public payable whenNotPaused {
		_swapTokenTo(msg.sender);
	}

	function swapTokenTo(address to) public payable whenNotPaused returns (uint){
		return _swapTokenTo(to);
	}

	function _swapTokenTo(address to) private whenNotPaused nonReentrant returns (uint){
		if(msg.value<=0) revert ValueZero();

		uint outAmount = msg.value * 50000 ;

		uint allAmount = token.balanceOf(address(this));
		if(outAmount>allAmount){
			token.mint(address(this), outAmount-allAmount);
		}
		
		if(!token.transfer(to, outAmount)) revert FailSendToken();

		return outAmount;
	}

	function bnbBalance() public view returns(uint) {
		return address(this).balance;
	}

	function tokenBalance() public  view returns(uint) {
		return token.balanceOf(address(this));
	}


	receive() external payable {
	}

}