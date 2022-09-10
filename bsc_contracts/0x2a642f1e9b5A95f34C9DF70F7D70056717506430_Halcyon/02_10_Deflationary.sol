// SPDX-License-Identifier: MIT
pragma solidity =0.8.16;

import "../vendor/@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./ERC20.sol";
import "./Vaultable.sol";
//import "hardhat/console.sol";

abstract contract Deflationary is ERC20, Vaultable
{
  using SafeMath for uint256;
  
  uint256 private $reflection;
  uint256 private $burn;
  uint256 private $liquify;
  uint256 private $distribution;
  uint256 private $maxTransferAmount;
  mapping(address => bool) private _taxable;
  uint256 private $minimumTotalSupply = 10 ** 7 * (10 ** ERC20._decimals);
  
  event MaxTransferSet(uint256 current, uint256 previous);
  event BurnRateSet(uint256 current, uint256 previous);
  event ReflectionRateSet(uint256 current, uint256 previous);
  event LiquifyRateSet(uint256 current, uint256 previous);
  event FeesProcessed(uint256 amount);
  
  error overMaxBalance(uint256 balance, uint256 max);
  
  
  receive() external payable {}
  
  
  function balanceOf(address account) public view virtual override returns (uint256)
  {
    if (account == address(this) || account == address(1))
      return _balances[account];
    
    if (!_taxable[account] && $distribution > 0)
      return reflection(_balances[account]);
    
    return _balances[account];
  }
  
  
  /**
   * @dev
   *
   * proportional staking rewards to non-taxable holders of tokens collected by $reflection tax in deflate()
   */
  function reflection(uint256 amount) private view returns (uint256)
  {
    if (amount == 0)
      return 0;
    
    uint256 $staking = amount.mul($distribution).div(_totalSupply);
    
    return amount + $staking;
  }
  
  
  /**
   * @dev
   *
   * Owner can not receive tokens!
   * No tax fees on buying and regular transfers in+out!
   * +On selling: collect and process fees until $minimumTotalSupply is reached
   *
   * @notice custom error uses less gas compared to require()
   */
  function _transfer(address sender, address recipient, uint256 amount) internal override
  {
    require(sender != address(0) && recipient != address(0) && recipient != owner(),
      "!Sender|Recipient.");
    
    require(amount > 0, "Amount is zero.");
    
    uint256 senderBalance = balanceOf(sender);
    require(senderBalance >= amount, "Amount gt balance.");
    
    uint256 $amountToReceive = amount;
    {
      if (_taxable[recipient] && ERC20._totalSupply > $minimumTotalSupply)
      {
        $amountToReceive = deflate(sender, amount);
        
        if (amount > $amountToReceive)
          _balances[address(this)] += amount.mul($liquify + fees).div(10 ** 2);
        
        processFees(recipient);
      }
      
      _balances[sender] = senderBalance.sub(amount);
      _balances[recipient] += $amountToReceive;
      
      if (!_taxable[recipient])
        if ($maxTransferAmount > 0 && _balances[recipient] > $maxTransferAmount)
          revert overMaxBalance(
          {
          balance : _balances[recipient],
          max : $maxTransferAmount
          });
    }
    
    emit Transfer(sender, recipient, $amountToReceive);
  }
  
  
  function deflate(address sender, uint256 amount) private returns (uint256)
  {
    if (sender == owner() || sender == address(this))
      return amount;
    
    uint256 $tax = 0;
    uint256 $taxAmount = 0;
    uint256 $amountToReceive = amount;
    
    
    if (($reflection + $burn + $liquify + fees) > 0)
    {
      if ($reflection > 0)
        $tax += $reflection;
      if ($burn > 0)
        $tax += $burn;
      if ($liquify > 0)
        $tax += $liquify;
      if (fees > 0)
        $tax += fees;
      
      $taxAmount = amount.mul($tax).div(10 ** 2);
      $amountToReceive = amount.sub($taxAmount);
      
      if ($burn > 0)
      {
        uint256 burnt = amount.mul($burn).div(10 ** 2);
        
        ERC20._totalSupply = ERC20._totalSupply.sub(burnt);
        ERC20._transfer(sender, address(1), burnt);
      }
      
      $distribution += amount.mul($reflection).div(10 ** 2);
    }
    
    return $amountToReceive;
  }
  
  
  /**
   * @dev
   * @param recipient - LP contracts only!
   * Tax fees only on selling!
   * A taxable recipient receives amount minus tax fees, non-taxable recipients (everyone else including this contract!) has max wallet restriction!
   * All LP contracts are recipient on sells and need to be set as _taxable before creating LP.
   * Do not set any contract/wallet besides LP contracts as taxable!
   */
  function setTaxable(address recipient, bool state) external onlyOwner
  {
    _taxable[recipient] = state;
  }
  
  
  /**
   * @dev
   *
   * Burn the tokens collected by $liquify tax.
   * Lowers X in X*Y=K
   *
   * +Vaults are receiving their token share
   * e.g. Marketing, Development vaults
   */
  function processFees(address pair) private
  {
    uint256 amount = _balances[address(this)];
    
    if (amount < ERC20._totalSupply.div(10 ** 2)) return;
    
    uint256 vaultAllocation = fees.mul(amount).div(fees + $liquify);
    
    for (uint256 i = 0; i < _vaults.length; i++)
    {
      Vault memory $vault = getVaultByAddress(_vaults[i]);
      
      uint256 $vaultAmount = $vault.reflection.mul(vaultAllocation).div(fees);
      amount = amount.sub($vaultAmount);
      
      _balances[$vault.wallet] += $vaultAmount;
      _balances[address(this)] = _balances[address(this)].sub($vaultAmount);
    }
    
    {
      _balances[pair] = _balances[pair].sub(amount);
      _balances[address(1)] += amount;
      
      ERC20._totalSupply = ERC20._totalSupply.sub(amount);
      
      //deflation ends
      if (ERC20._totalSupply < $minimumTotalSupply)
        ERC20._totalSupply = $minimumTotalSupply;
    }
    
    emit FeesProcessed(amount);
  }
  
  
  /**
   * @dev
   *
   * divisor is number of wallets holding the set max.
   * e.g. 20 wallets of 5% TOKENSUPPLY. 200 of 0.5%
   * Note: burn address max wallet amount applies only to third party transfers.
   */
  function setMaxWallets(uint256 divisor) external onlyOwner
  {
    require(divisor >= 20, "Divisor must be gte 20 (=5% of TOKENSUPPLY).");
    uint256 previous = $maxTransferAmount;
    $maxTransferAmount = ERC20.TOKENSUPPLY.div(divisor);
    
    emit MaxTransferSet($maxTransferAmount, previous);
  }
  
  
  /**
   * @dev
   *
   * - contract does not implement ERC20Burnable
   * - tokens are sent to address(1)
   * - transfer() rejects address(0) which is a required check.
   */
  function setBurnRate(uint256 amount) external onlyOwner
  {
    require(amount <= 10, "Max burn rate must be lte 10%.");
    uint256 previous = $burn;
    $burn = amount;
    
    emit BurnRateSet($burn, previous);
  }
  
  
  function setReflectionRate(uint256 amount) external onlyOwner
  {
    require(amount <= 10, "Max staking rate must be lte 10%.");
    uint256 previous = $reflection;
    $reflection = amount;
    
    emit ReflectionRateSet($reflection, previous);
  }
  
  
  function setLiquifyRate(uint256 amount) external onlyOwner
  {
    require(amount <= 10, "Max liquify rate must be lte 10%.");
    uint256 previous = $liquify;
    $liquify = amount;
    
    emit LiquifyRateSet($liquify, previous);
  }
  
  
  /**
   * @notice
   *
   * Recover WETH sent to the contract by accident, back to the sender. On request only!
   */
  function sendWeth(address to, uint256 amount) external onlyOwner
  {
    require(to != address(0), "Transfer to zero address.");
    payable(to).transfer(amount);
  }
  
  
  /**
   * @notice
   *
   * Sends tokens sent by accident back to the sender on request!
   * Only common tokens with a long standing history are considered!
   */
  function sendTokens(address token, address to, uint256 amount) external onlyOwner returns (bool success)
  {
    success = IERC20(token).transfer(to, amount);
  }
}