/**
 *Submitted for verification at Etherscan.io on 2020-06-22
*/

pragma solidity ^0.5.13;


/**
 * 
 * Mammoth's Liquidity Vault
 * 
 * Simple smart contract to decentralize the uniswap liquidity, providing proof of liquidity indefinitely.
 * For more info visit: https://t.me/mammothcorp
 * 
 */
contract MammothLiquidityVault {
    
    ERC20 constant mammothToken = ERC20(0x821144518dfE9e7b44fCF4d0824e15e8390d4637);
    ERC20 constant liquidityToken = ERC20(0x490B5B2489eeFC4106C69743F657e3c4A2870aC5);
    
    address tszunami = msg.sender;
    uint256 public lastTradingFeeDistribution;
    
    
    /**
     * To allow distributing of trading fees to be split between dapps 
     * (Dapps cant be hardcoded because more will be added in future)
     * Has a hardcap of 1% per 24 hours -trading fees consistantly exceeding that 1% is not a bad problem to have(!)
     */
    function distributeTradingFees(address recipient, uint256 amount) external {
        uint256 liquidityBalance = liquidityToken.balanceOf(address(this));
        require(amount < (liquidityBalance / 100)); // Max 1%
        require(lastTradingFeeDistribution + 24 hours < now); // Max once a day
        require(msg.sender == tszunami);
        
        liquidityToken.transfer(recipient, amount);
        lastTradingFeeDistribution = now;
    } 
    
    
    /**
     * This contract may also hold Mammoth tokens (donations) to run promo, this function lets them be withdrawn.
     */
    function distributeMammoth(address recipient, uint256 amount) external {
        require(msg.sender == tszunami);
        mammothToken.transfer(recipient, amount);
    } 
    
}





interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint tokens, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}