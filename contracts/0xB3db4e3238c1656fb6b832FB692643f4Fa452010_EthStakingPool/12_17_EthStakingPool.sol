// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./lib/CurrencyTransferLib.sol";
import "./interfaces/IWETH.sol";
import "./StakingPool.sol";

contract EthStakingPool is StakingPool {
  using SafeMath for uint256;

  IWETH public weth;
 
  /* ========== CONSTRUCTOR ========== */

  constructor(
    address _rewardsDistribution,
    address _rewardsToken,
    address _nativeTokenWrapper,
    uint256 _durationInDays
  ) StakingPool(_rewardsDistribution, _rewardsToken, _nativeTokenWrapper, _durationInDays) {
    weth = IWETH(_nativeTokenWrapper);
  }

  function _transferStakingToken(uint256 amount) override internal virtual {
    require(msg.value >= amount, 'Not enough value');
    weth.deposit{value: amount}();
    
    uint256 diff = msg.value.sub(amount);
    if (diff > 0) {
      CurrencyTransferLib.transferCurrency(CurrencyTransferLib.NATIVE_TOKEN, address(this), msg.sender, diff);
    }
  }

  function _withdrawStakingToken(uint256 amount) override internal virtual {
    weth.withdraw(amount);
    CurrencyTransferLib.transferCurrency(CurrencyTransferLib.NATIVE_TOKEN, address(this), msg.sender, amount);
  }

  // Admin could withdraw Ethers that are accidently sent to the pool
  function withdrawELRewards(address to) external override virtual nonReentrant onlyRewardsDistribution {
    require(block.timestamp >= periodFinish, 'Not ready to withdraw EL rewards');

    uint256 amount = address(this).balance;
    require(amount > 0, 'No extra EL rewards to withdraw');

    CurrencyTransferLib.transferCurrency(CurrencyTransferLib.NATIVE_TOKEN, address(this), to, amount);
    emit ELRewardWithdrawn(to, amount);
  }

}