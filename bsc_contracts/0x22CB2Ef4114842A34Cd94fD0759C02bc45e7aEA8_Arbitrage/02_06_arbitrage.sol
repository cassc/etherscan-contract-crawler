// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IUniswapV2Router01.sol";


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        _owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "onlyOwner");
        _;
    }
    
    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
        return _owner;
    }
    
    /**
    * @dev Returns the address of the pending owner.
    */
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public {
        require(msg.sender == _pendingOwner, "onlyPendingOwner");
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
        _pendingOwner = address(0);
    }
}


interface ITokenBridge {
    function incomingTransfer(
        address _user,
        uint256 _amount,
        uint256 _nonce
    ) external;

    function outgoingTransfer(uint256 _amount) external;

    function outgoingTransfer(uint256 _amount, address _recipient) external;
}


contract Arbitrage is Ownable {
  using SafeERC20 for IERC20;
  
  address private swapRouter;
  address private arbitrageAgent;
  address private bridge;
  address private bridgeRecipient;

  event Received(address, uint);
  
  
  constructor(
    address _swapRouter,
    address _arbitrageAgent
    )    
  {
    require(_swapRouter != address(0), "Arbitrage: swap router address must not be zero");
	require(_arbitrageAgent != address(0), "Arbitrage: arbitrage agent address must not be zero");
    
    swapRouter = _swapRouter;
	arbitrageAgent = _arbitrageAgent;    
  }
    	
  receive() external payable {
   emit Received(msg.sender, msg.value);
  }	
	
  modifier onlyAgent() {
        require(msg.sender == arbitrageAgent, "onlyAgent");
        _;
  }	

  function getSwapRouter() public view returns (address) {
	return swapRouter;
  }
  
    
  function getAgent() public view returns (address) {
	return arbitrageAgent;
  }

  function getBridge() public view returns (address) {
	  return bridge;
  }

  function getBridgeRecipient() public view returns (address) {
	  return bridgeRecipient;
  }


  function setAgent(address _arbitrageAgent) public onlyOwner {
	arbitrageAgent = _arbitrageAgent;
  }

  function setBridge(address _bridge) public onlyOwner {
	bridge = _bridge;
  }

  function setBridgeRecipient(address _bridgeRecipient) public onlyOwner {
	bridgeRecipient = _bridgeRecipient;
  }

  function setSwapRouter(address _swapRouter) public onlyOwner {
	swapRouter = _swapRouter;
  }

  function increaseAllowance(uint256 value, address _token) public onlyOwner {
	  IERC20(_token).safeIncreaseAllowance(swapRouter, value);
  }
  
  function decreaseAllowance(uint256 value, address _token) public onlyOwner {
	  IERC20(_token).safeDecreaseAllowance(swapRouter, value);
  }


  function increaseSpenderAllowance(address spender, uint256 value, address _token) public onlyOwner {
	  IERC20(_token).safeIncreaseAllowance(spender, value);
  }
  
  function decreaseSpenderAllowance(address spender, uint256 value, address _token) public onlyOwner {
	  IERC20(_token).safeDecreaseAllowance(spender, value);
  }


  function buy(uint amountOut, uint amountInMax, address[] calldata path, uint deadline) external payable onlyAgent returns (uint[] memory amounts) {	  
	  return IUniswapV2Router01(swapRouter).swapETHForExactTokens{value: amountInMax}(amountOut, path, address(this), deadline);  				
  }
  
  
  function sell(uint amountIn, uint amountOutMin, address[] calldata path, uint deadline) external onlyAgent returns (uint[] memory amounts) {	  
	  return IUniswapV2Router01(swapRouter).swapExactTokensForETH(amountIn, amountOutMin, path, address(this), deadline);	  
  }

  function buyByToken(uint amountOut, uint amountInMax, address[] calldata path, uint deadline) external onlyAgent returns (uint[] memory amounts) {	  
	  return IUniswapV2Router01(swapRouter).swapTokensForExactTokens(amountOut, amountInMax, path, address(this), deadline);  				
  }
  
  
  function sellByToken(uint amountIn, uint amountOutMin, address[] calldata path, uint deadline) external onlyAgent returns (uint[] memory amounts) {	  
	  return IUniswapV2Router01(swapRouter).swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), deadline);	  
  }


  function outgoingTransfer(uint256 _amount) external onlyAgent {
	  require(bridge != address(0), "Bridge address is not set");
	  require(bridgeRecipient != address(0), "Bridge recipient address is not set");
	  ITokenBridge(bridge).outgoingTransfer(_amount, bridgeRecipient);
  }


  function withdrawAllToken(address _token) public onlyOwner {
    uint256 balance = IERC20(_token).balanceOf(address(this));
    IERC20(_token).safeTransfer(owner(), balance);    
  }
  
  function withdrawAllBaseToken() public onlyOwner {
    uint256 balance = address(this).balance;	
	address _to = owner();
	(bool sent, bytes memory data) = _to.call{value: balance}("");    
	require(sent, "Failed to send Ether");    
  }

  function withdrawToken(address _token, uint256 _amount) public onlyOwner {
    uint256 balance = IERC20(_token).balanceOf(address(this));
	require(balance >= _amount, "Amount is higher than the balance");
    IERC20(_token).safeTransfer(owner(), _amount);    
  }
  
  function withdrawBaseToken(uint256 _amount) public onlyOwner {
    uint256 balance = address(this).balance;	
    require(balance >= _amount, "Amount is higher than the balance");
	address _to = owner();
	(bool sent, bytes memory data) = _to.call{value: _amount}("");    
	require(sent, "Failed to send Ether");    
  }

}