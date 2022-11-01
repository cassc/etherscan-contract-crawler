// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IPriceGetter.sol";
import "./interfaces/IAggregatorV3.sol";
import "./interfaces/IStargatePool.sol";
import "./interfaces/IStargateVault.sol";

contract VaultRangePriceGetter is IPriceGetter {
  using SafeMath for uint; 
  
  uint[2] public priceRange;
  IStargatePool public immutable stargatePool;
  IStargateVault public immutable stargateVault;
  IAggregatorV3 public immutable aggregator;

  address public owner;

  constructor(IStargateVault _stargateVault, IStargatePool _stargatePool, IAggregatorV3 _aggregator, uint[2] memory _priceRange) {
    stargateVault = _stargateVault;
    stargatePool = _stargatePool;
    aggregator = _aggregator;
    priceRange = _priceRange;
    owner = msg.sender;
  }

  function getPrice() external view returns (uint256 price) {
    (, int256 usdcPriceInUSD,,,) = aggregator.latestRoundData();
    uint lpAmount = stargateVault.previewWithdraw(10 ** uint(stargateVault.decimals()));
    uint ratio = stargatePool.totalLiquidity().mul(1e18).div(stargatePool.totalSupply());
    uint vaultPrice = ratio.mul(lpAmount).mul(uint(usdcPriceInUSD)).div(1e18).div(10 ** uint(stargateVault.decimals()));
    uint256 minPrice = min(priceRange[0], priceRange[1]);
    uint256 maxPrice = max(priceRange[0], priceRange[1]);
    if (vaultPrice > maxPrice) {
      price = maxPrice;
    } else if (vaultPrice < minPrice) {
      price = minPrice;
    } else {
      price = vaultPrice;
    }

  }

  function setPriceRange(uint256[2] calldata _priceRange) external onlyOwner {
    priceRange = _priceRange;
  }

  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? b : a;
  }

  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    owner = newOwner;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call this function.");
    _;
  }
}