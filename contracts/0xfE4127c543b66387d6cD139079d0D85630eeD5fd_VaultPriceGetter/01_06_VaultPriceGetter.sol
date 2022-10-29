// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IPriceGetter.sol";
import "./interfaces/IAggregatorV3.sol";
import "./interfaces/IVaultWrapper.sol";
import "./interfaces/IVault.sol";


contract VaultPriceGetter is IPriceGetter {
  using SafeMath for uint256; 
  
  IAggregatorV3 public immutable aggregator;
  IVault public immutable vault;
  IVaultWrapper public immutable vaultWrapper;

  constructor(IVault _vault, IVaultWrapper _vaultWrapper, IAggregatorV3 _aggregator) {
    vault = _vault;
    vaultWrapper = _vaultWrapper;
    aggregator = _aggregator;
  }

  function getPrice() external view returns (uint256 price) {
    uint amount = 10 ** uint(vault.decimals());
    (, uint assetsPool) = vaultWrapper.previewWithdrawUnderlyingFromVault(address(vault), amount);
    (, int256 answer,,,) = aggregator.latestRoundData();
    price = assetsPool.mul(uint(answer)).div(amount);
  }
}