// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../IOracleRelay.sol";
import "../../_external/IERC20.sol";
import "../../_external/balancer/IBalancerVault.sol";

interface IBalancerPool {
  function getPoolId() external view returns (bytes32);

  function totalSupply() external view returns (uint256);

  function getLastInvariant() external view returns (uint256, uint256);
}

/*****************************************
 *
 * This relay gets a USD price for BPT LP token from a balancer MetaStablePool or StablePool
 * Comparing the results of outGivenIn to known safe oracles for the underlying assets,
 * we can safely determine if manipulation has transpired.
 * After confirming that the naive price is safe, we return the naive price.
 */

contract BPTstablePoolOracle is IOracleRelay {
  bytes32 public immutable _poolId;

  uint256 public immutable _widthNumerator;
  uint256 public immutable _widthDenominator;

  IBalancerPool public immutable _priceFeed;

  mapping(address => IOracleRelay) public assetOracles;

  //Balancer Vault
  IBalancerVault public immutable VAULT;

  /**
   * @param pool_address - Balancer StablePool or MetaStablePool address
   * @param balancerVault is the address for the Balancer Vault contract
   * @param _tokens should be length 2 and contain both underlying assets for the pool
   * @param _oracles shoulb be length 2 and contain a safe external on-chain oracle for each @param _tokens in the same order
   * @notice the quotient of @param widthNumerator and @param widthDenominator should be the percent difference the exchange rate
   * is able to diverge from the expected exchange rate derived from just the external oracles
   */
  constructor(
    address pool_address,
    IBalancerVault balancerVault,
    address[] memory _tokens,
    address[] memory _oracles,
    uint256 widthNumerator,
    uint256 widthDenominator
  ) {
    _priceFeed = IBalancerPool(pool_address);

    _poolId = _priceFeed.getPoolId();

    VAULT = balancerVault;

    //register oracles
    for (uint256 i = 0; i < _tokens.length; i++) {
      assetOracles[_tokens[i]] = IOracleRelay(_oracles[i]);
    }

    _widthNumerator = widthNumerator;
    _widthDenominator = widthDenominator;
  }

  function currentValue() external view override returns (uint256) {
    //check for reentrancy, further protects against manipulation
    ensureNotInVaultContext();

    (IERC20[] memory tokens, uint256[] memory balances /**uint256 lastChangeBlock */, ) = VAULT.getPoolTokens(_poolId);

    uint256 tokenAmountIn = 1000e18;

    uint256 outGivenIn = getOutGivenIn(balances, tokenAmountIn);

    (uint256 calcedRate, uint256 expectedRate) = getExchangeRates(
      outGivenIn,
      tokenAmountIn,
      assetOracles[address(tokens[0])].currentValue(),
      assetOracles[address(tokens[1])].currentValue()
    );

    verifyExchangeRate(expectedRate, calcedRate);

    uint256 naivePrice = getNaivePrice(tokens, balances);

    return naivePrice;
  }

  /*******************************GET & CHECK NAIVE PRICE********************************/
  ///@notice get the naive price by dividing the TVL/total BPT supply
  function getNaivePrice(IERC20[] memory tokens, uint256[] memory balances) internal view returns (uint256 naivePrice) {
    uint256 naiveTVL = 0;
    for (uint256 i = 0; i < tokens.length; i++) {
      naiveTVL += ((assetOracles[address(tokens[i])].currentValue() * balances[i]));
    }
    naivePrice = naiveTVL / _priceFeed.totalSupply();
    require(naivePrice > 0, "invalid naive price");
  }

  ///@notice ensure the exchange rate is within the expected range
  ///@notice ensuring the price is in bounds prevents price manipulation
  function verifyExchangeRate(uint256 expectedRate, uint256 outGivenInRate) internal view {
    uint256 delta = percentChange(expectedRate, outGivenInRate);
    uint256 buffer = divide(_widthNumerator, _widthDenominator, 18);

    require(delta < buffer, "Price out of bounds");
  }

  /*******************************OUT GIVEN IN********************************/
  function getOutGivenIn(uint256[] memory balances, uint256 tokenAmountIn) internal view returns (uint256 outGivenIn) {
    (uint256 v, uint256 amp) = _priceFeed.getLastInvariant();
    uint256 idxIn = 0;
    uint256 idxOut = 1;

    //first calculate the balances, math doesn't work with reported balances on their own
    uint256[] memory calcedBalances = new uint256[](2);
    calcedBalances[0] = _getTokenBalanceGivenInvariantAndAllOtherBalances(amp, balances, v, 0);
    calcedBalances[1] = _getTokenBalanceGivenInvariantAndAllOtherBalances(amp, balances, v, 1);

    //get the ending balance for output token (always index 1)
    uint256 finalBalanceOut = _calcOutGivenIn(amp, calcedBalances, idxIn, idxOut, tokenAmountIn, v);

    //outGivenIn is a function of the actual starting balance, not the calculated balance
    outGivenIn = ((balances[idxOut] - finalBalanceOut) - 1);
  }

  // Computes how many tokens can be taken out of a pool if `tokenAmountIn` are sent, given the current balances.
  // The amplification parameter equals: A n^(n-1)
  // The invariant should be rounded up.
  function _calcOutGivenIn(
    uint256 amplificationParameter,
    uint256[] memory balances,
    uint256 tokenIndexIn,
    uint256 tokenIndexOut,
    uint256 tokenAmountIn,
    uint256 invariant
  ) internal pure returns (uint256) {
    /**************************************************************************************************************
    // outGivenIn token x for y - polynomial equation to solve                                                   //
    // ay = amount out to calculate                                                                              //
    // by = balance token out                                                                                    //
    // y = by - ay (finalBalanceOut)                                                                             //
    // D = invariant                                               D                     D^(n+1)                 //
    // A = amplification coefficient               y^2 + ( S - ----------  - D) * y -  ------------- = 0         //
    // n = number of tokens                                    (A * n^n)               A * n^2n * P              //
    // S = sum of final balances but y                                                                           //
    // P = product of final balances but y                                                                       //
    **************************************************************************************************************/

    balances[tokenIndexIn] = balances[tokenIndexIn] + (tokenAmountIn);

    uint256 finalBalanceOut = _getTokenBalanceGivenInvariantAndAllOtherBalances(
      amplificationParameter,
      balances,
      invariant,
      tokenIndexOut
    );
    balances[tokenIndexIn] = balances[tokenIndexIn] - tokenAmountIn;

    //we simply return finalBalanceOut here, and get outGivenIn elsewhere
    return finalBalanceOut;
  }

  // This function calculates the balance of a given token (tokenIndex)
  // given all the other balances and the invariant
  function _getTokenBalanceGivenInvariantAndAllOtherBalances(
    uint256 amplificationParameter,
    uint256[] memory balances,
    uint256 invariant,
    uint256 tokenIndex
  ) internal pure returns (uint256) {
    // Rounds result up overall
    uint256 _AMP_PRECISION = 1e3;

    uint256 ampTimesTotal = amplificationParameter * balances.length;
    uint256 sum = balances[0];
    uint256 P_D = balances[0] * balances.length;
    for (uint256 j = 1; j < balances.length; j++) {
      P_D = (((P_D * balances[j]) * balances.length) / invariant);
      sum = sum + balances[j];
    }
    // No need to use safe math, based on the loop above `sum` is greater than or equal to `balances[tokenIndex]`
    sum = sum - balances[tokenIndex];

    uint256 inv2 = (invariant * invariant);
    // We remove the balance from c by multiplying it
    uint256 c = ((divUp(inv2, (ampTimesTotal * P_D)) * _AMP_PRECISION) * balances[tokenIndex]);
    uint256 b = sum + ((invariant / ampTimesTotal) * _AMP_PRECISION);

    // We iterate to find the balance
    uint256 prevTokenBalance = 0;
    // We multiply the first iteration outside the loop with the invariant to set the value of the
    // initial approximation.
    uint256 tokenBalance = divUp((inv2 + c), (invariant + b));

    for (uint256 i = 0; i < 255; i++) {
      prevTokenBalance = tokenBalance;

      uint256 numerator = (tokenBalance * tokenBalance) + c;
      uint256 denominator = ((tokenBalance * 2) + b) - invariant;

      tokenBalance = divUp(numerator, denominator);
      if (tokenBalance > prevTokenBalance) {
        if (tokenBalance - prevTokenBalance <= 1) {
          return tokenBalance;
        }
      } else if (prevTokenBalance - tokenBalance <= 1) {
        return tokenBalance;
      }
    }
    revert("STABLE_GET_BALANCE_DIDNT_CONVERGE");
  }

  //https://github.com/balancer/balancer-v2-monorepo/pull/2418/files#diff-36f155e03e561d19a594fba949eb1929677863e769bd08861397f4c7396b0c71R37
  function ensureNotInVaultContext() internal view {
    // Perform the following operation to trigger the Vault's reentrancy guard:
    //
    // IVault.UserBalanceOp[] memory noop = new IVault.UserBalanceOp[](0);
    // _vault.manageUserBalance(noop);
    //
    // However, use a static call so that it can be a view function (even though the function is non-view).
    // This allows the library to be used more widely, as some functions that need to be protected might be
    // view.
    //
    // This staticcall always reverts, but we need to make sure it doesn't fail due to a re-entrancy attack.
    // Staticcalls consume all gas forwarded to them on a revert. By default, almost the entire available gas
    // is forwarded to the staticcall, causing the entire call to revert with an 'out of gas' error.
    //
    // We set the gas limit to 100k, but the exact number doesn't matter because view calls are free, and non-view
    // calls won't waste the entire gas limit on a revert. `manageUserBalance` is a non-reentrant function in the
    // Vault, so calling it invokes `_enterNonReentrant` in the `ReentrancyGuard` contract, reproduced here:
    //
    //    function _enterNonReentrant() private {
    //        // If the Vault is actually being reentered, it will revert in the first line, at the `_require` that
    //        // checks the reentrancy flag, with "BAL#400" (corresponding to Errors.REENTRANCY) in the revertData.
    //        // The full revertData will be: `abi.encodeWithSignature("Error(string)", "BAL#400")`.
    //        _require(_status != _ENTERED, Errors.REENTRANCY);
    //
    //        // If the Vault is not being reentered, the check above will pass: but it will *still* revert,
    //        // because the next line attempts to modify storage during a staticcall. However, this type of
    //        // failure results in empty revertData.
    //        _status = _ENTERED;
    //    }
    //
    // So based on this analysis, there are only two possible revertData values: empty, or abi.encoded BAL#400.
    //
    // It is of course much more bytecode and gas efficient to check for zero-length revertData than to compare it
    // to the encoded REENTRANCY revertData.
    //
    // While it should be impossible for the call to fail in any other way (especially since it reverts before
    // `manageUserBalance` even gets called), any other error would generate non-zero revertData, so checking for
    // empty data guards against this case too.

    (, bytes memory revertData) = address(VAULT).staticcall{gas: 100_000}(
      abi.encodeWithSelector(VAULT.manageUserBalance.selector, 0)
    );

    require(revertData.length == 0, "REENTRANCY");
  }

  /*******************************PURE MATH FUNCTIONS********************************/
  ///@notice get exchange rates
  function getExchangeRates(
    uint256 outGivenIn,
    uint256 tokenAmountIn,
    uint256 price0,
    uint256 price1
  ) internal pure returns (uint256 calcedRate, uint256 expectedRate) {
    expectedRate = divide(price1, price0, 18);

    uint256 numerator = divide(outGivenIn * price1, 1e18, 18);

    uint256 denominator = divide((tokenAmountIn * price0), 1e18, 18);

    calcedRate = divide(numerator, denominator, 18);
  }

  ///@notice get the percent deviation from a => b as a decimal e18
  function percentChange(uint256 a, uint256 b) internal pure returns (uint256 delta) {
    uint256 max = a > b ? a : b;
    uint256 min = b != max ? b : a;
    delta = divide((max - min), min, 18);
  }

  ///@notice floating point division at @param factor scale
  function divide(uint256 numerator, uint256 denominator, uint256 factor) internal pure returns (uint256 result) {
    uint256 q = (numerator / denominator) * 10 ** factor;
    uint256 r = ((numerator * 10 ** factor) / denominator) % 10 ** factor;

    return q + r;
  }

  function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "divUp: Zero division");

    if (a == 0) {
      return 0;
    } else {
      return 1 + (a - 1) / b;
    }
  }
}