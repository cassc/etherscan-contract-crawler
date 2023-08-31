pragma solidity 0.6.12;

import 'OpenZeppelin/[email protected]/contracts/math/SafeMath.sol';

import './UsingBaseOracle.sol';
import '../utils/BNum.sol';
import '../../interfaces/IBaseOracle.sol';
import '../../interfaces/IBalancerPool.sol';

contract BalancerPairOracle is UsingBaseOracle, IBaseOracle, BNum {
  using SafeMath for uint;

  constructor(IBaseOracle _base) public UsingBaseOracle(_base) {}

  /// @dev Return fair reserve amounts given spot reserves, weights, and fair prices.
  /// @param resA Reserve of the first asset
  /// @param resB Reserev of the second asset
  /// @param wA Weight of the first asset
  /// @param wB Weight of the second asset
  /// @param pxA Fair price of the first asset
  /// @param pxB Fair price of the second asset
  function computeFairReserves(
    uint resA,
    uint resB,
    uint wA,
    uint wB,
    uint pxA,
    uint pxB
  ) internal pure returns (uint fairResA, uint fairResB) {
    uint r0 = bdiv(resA, resB);
    uint r1 = bdiv(bmul(wA, pxB), bmul(wB, pxA));
    // fairResA = resA * (r1 / r0) ^ wB
    // fairResB = resB * (r0 / r1) ^ wA
    if (r0 > r1) {
      uint ratio = bdiv(r1, r0);
      fairResA = bmul(resA, bpow(ratio, wB));
      fairResB = bdiv(resB, bpow(ratio, wA));
    } else {
      uint ratio = bdiv(r0, r1);
      fairResA = bdiv(resA, bpow(ratio, wB));
      fairResB = bmul(resB, bpow(ratio, wA));
    }
  }

  /// @dev Return the value of the given input as ETH per unit, multiplied by 2**112.
  /// @param token The ERC-20 token to check the value.
  function getETHPx(address token) external view override returns (uint) {
    IBalancerPool pool = IBalancerPool(token);
    require(pool.getNumTokens() == 2, 'num tokens must be 2');
    address[] memory tokens = pool.getFinalTokens();
    address tokenA = tokens[0];
    address tokenB = tokens[1];
    uint pxA = base.getETHPx(tokenA);
    uint pxB = base.getETHPx(tokenB);
    (uint fairResA, uint fairResB) =
      computeFairReserves(
        pool.getBalance(tokenA),
        pool.getBalance(tokenB),
        pool.getNormalizedWeight(tokenA),
        pool.getNormalizedWeight(tokenB),
        pxA,
        pxB
      );
    return fairResA.mul(pxA).add(fairResB.mul(pxB)).div(pool.totalSupply());
  }
}