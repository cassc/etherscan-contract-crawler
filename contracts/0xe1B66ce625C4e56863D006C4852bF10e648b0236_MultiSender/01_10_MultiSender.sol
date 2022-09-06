// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MultiSender is Ownable{
    using SafeMath for uint256;
    using Address for address payable;
    using SafeERC20 for IERC20;

    event SendETH(address send,uint256 amount,uint256 value);
    event SendToken(address send,uint256 amount,uint256 value);

    constructor()  {
        
    }
    
    function ethSendSameValue(address[] memory _to, uint256 _value) internal {
        uint256 sendAmount = _to.length.sub(1).mul(_value);
        uint256 remainingValue = msg.value;

        require(remainingValue >= sendAmount,"Not enough balance");

		for (uint256 i = 1; i < _to.length; i++) {
			remainingValue = remainingValue.sub(_value);
			require(payable(_to[i]).send(_value));
		}
	    emit SendETH(msg.sender,_to.length.sub(1),msg.value);
    }

    function ethSendDifferentValue(address[] memory _to, uint256[] memory _value) internal {

        uint256 sendAmount = _value[0];
		uint256 remainingValue = msg.value;

	    require(remainingValue >= sendAmount,"Not enough balance");

		require(_to.length == _value.length);

		for (uint256 i = 1; i < _to.length; i++) {
			remainingValue = remainingValue.sub(_value[i]);
			require(payable(_to[i]).send(_value[i]));
		}
	    emit SendETH(msg.sender,_to.length.sub(1),msg.value);
    }

    function coinSendSameValue(address _tokenAddress, address[] memory _to, uint256 _value)  internal {
		uint256 sendAmount = _to.length.sub(1).mul(_value);
        uint256 allowance = IERC20(_tokenAddress).allowance(msg.sender, address(this));
        require(allowance >= sendAmount,"Not enough allowance");

        uint256 balance = IERC20(_tokenAddress).balanceOf(msg.sender);
        require(balance >= sendAmount,"Not enough balance");

		for (uint256 i = 1; i < _to.length; i++) {
			IERC20(_tokenAddress).transferFrom(msg.sender, _to[i], _value);
		}

	    emit SendToken(msg.sender,_to.length.sub(1),sendAmount);
	}


	function coinSendDifferentValue(address _tokenAddress, address[] memory _to, uint256[] memory _value)  internal  {
		require(_to.length == _value.length);

        uint256 sendAmount = _value[0];

        uint256 allowance = IERC20(_tokenAddress).allowance(msg.sender, address(this));
        require(allowance >= sendAmount,"Not enough allowance");

        uint256 balance = IERC20(_tokenAddress).balanceOf(msg.sender);
        require(balance >= sendAmount,"Not enough balance");
        
		for (uint256 i = 1; i < _to.length; i++) {
			IERC20(_tokenAddress).transferFrom(msg.sender, _to[i], _value[i]);
		}
	    emit SendToken(msg.sender,_to.length.sub(1),sendAmount);
	}

	/*
        Send ether with the different value by a implicit call method
    */

	function mutiSendETHWithDifferentValue(address[] memory _to, uint256[] memory _value) payable public {
        ethSendDifferentValue(_to,_value);
	}

	/*
        Send ether with the same value by a implicit call method
    */

    function mutiSendETHWithSameValue(address[] memory _to, uint256 _value) payable public {
		ethSendSameValue(_to,_value);
	}

    /*
        Send coin with the same value by a implicit call method
    */

	function mutiSendCoinWithSameValue(address _tokenAddress, address[] memory _to, uint256 _value)  payable public {
	    coinSendSameValue(_tokenAddress, _to, _value);
	}

    /*
        Send coin with the different value by a implicit call method, this method can save some fee.
    */
	function mutiSendCoinWithDifferentValue(address _tokenAddress, address[] memory _to, uint256[] memory _value) payable public {
	    coinSendDifferentValue(_tokenAddress, _to, _value);
	}

    function rescueETH(address  toAddr)  external onlyOwner(){
        _transferEth(toAddr, address(this).balance);
    }

    function rescueERC20(address token,address  toAddr)  external  onlyOwner{ 
        IERC20(token).safeTransfer(toAddr, IERC20(token).balanceOf(address(this)));
    }

    function _transferEth(address _to, uint256 _amount) internal {
        (bool success, ) = _to.call{value: _amount}('');
        require(success, "_transferEth: Eth transfer failed");
    }
}