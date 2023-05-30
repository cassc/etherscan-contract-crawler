// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.7.6;


import './IERC20.sol';
import './SafeMath.sol';
import './Address.sol';


import './Context.sol';
import './Ownable.sol';


// Alternative route after calling v2 swap function  
// UniswaoFactory.sol line 165  
// require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');  
// Normally you would never want these circumstances except 
// this scenario where the token is essentially self sustaining


contract PolkaBank is Context, Ownable {

 using SafeMath for uint256;
 using Address for address;
 
 
 IERC20 private _usdc;
 address public immutable _polkaContract;
 
 constructor (address polkaContract, IERC20 usdc) {
     _usdc = usdc;
     _polkaContract = polkaContract;

 }
 
 
    // @dev Emitted when `value` tokens are moved from one account (`from`) to
    // another (`to`).
    // Note that `value` may be zero.
    event Transfer(address indexed from, address indexed to, uint256 value);
 

    // Added in case of any unforseen errors 
    function bankDeposit( uint256 usdcAmount) external {
     require(msg.sender == owner(), 'Unauthorized Address');    
     _usdc.transferFrom(msg.sender, address(this), usdcAmount);
 }

    // Make token transfer back to primary contract 
    function bankWithdraw() external {
      require(msg.sender == _polkaContract, 'Unauthorized Address');
      uint256 bankBalance = _usdc.balanceOf(address(this));
     _usdc.transfer(_polkaContract, bankBalance);
 }
 
}