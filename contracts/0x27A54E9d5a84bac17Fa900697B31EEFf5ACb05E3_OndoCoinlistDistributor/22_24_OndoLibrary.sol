/**SPDX-License-Identifier: AGPL-3.0

          ▄▄█████████▄                                                                  
       ╓██▀└ ,╓▄▄▄, '▀██▄                                                               
      ██▀ ▄██▀▀╙╙▀▀██▄ └██µ           ,,       ,,      ,     ,,,            ,,,         
     ██ ,██¬ ▄████▄  ▀█▄ ╙█▄      ▄███▀▀███▄   ███▄    ██  ███▀▀▀███▄    ▄███▀▀███,     
    ██  ██ ╒█▀'   ╙█▌ ╙█▌ ██     ▐██      ███  █████,  ██  ██▌    └██▌  ██▌     └██▌    
    ██ ▐█▌ ██      ╟█  █▌ ╟█     ██▌      ▐██  ██ └███ ██  ██▌     ╟██ j██       ╟██    
    ╟█  ██ ╙██    ▄█▀ ▐█▌ ██     ╙██      ██▌  ██   ╙████  ██▌    ▄██▀  ██▌     ,██▀    
     ██ "██, ╙▀▀███████████⌐      ╙████████▀   ██     ╙██  ███████▀▀     ╙███████▀`     
      ██▄ ╙▀██▄▄▄▄▄,,,                ¬─                                    '─¬         
       ╙▀██▄ '╙╙╙▀▀▀▀▀▀▀▀                                                               
          ╙▀▀██████R⌐                                                                   

 */
pragma solidity >=0.8.3;

import "@openzeppelin/contracts/utils/Arrays.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Helper functions
 */
library OLib {
  using Arrays for uint256[];

  // State transition per Vault. Just linear transitions.
  enum State {
    Inactive,
    Deposit,
    Live,
    Withdraw
  }

  // Only supports 2 tranches for now
  enum Tranche {
    Senior,
    Junior
  }

  struct VaultParams {
    address seniorAsset;
    address juniorAsset;
    address strategist;
    address strategy;
    uint256 hurdleRate;
    uint256 startTime;
    uint256 enrollment;
    uint256 duration;
    string seniorName;
    string seniorSym;
    string juniorName;
    string juniorSym;
    uint256 seniorTrancheCap;
    uint256 seniorUserCap;
    uint256 juniorTrancheCap;
    uint256 juniorUserCap;
  }

  struct RolloverParams {
    address strategist;
    string seniorName;
    string seniorSym;
    string juniorName;
    string juniorSym;
  }

  bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
  bytes32 public constant PANIC_ROLE = keccak256("PANIC_ROLE");
  bytes32 public constant GUARDIAN_ROLE = keccak256("GUARDIAN_ROLE");
  bytes32 public constant DEPLOYER_ROLE = keccak256("DEPLOYER_ROLE");
  bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
  bytes32 public constant STRATEGIST_ROLE = keccak256("STRATEGIST_ROLE");
  bytes32 public constant VAULT_ROLE = keccak256("VAULT_ROLE");
  bytes32 public constant ROLLOVER_ROLE = keccak256("ROLLOVER_ROLE");
  bytes32 public constant STRATEGY_ROLE = keccak256("STRATEGY_ROLE");
  bytes32 public constant SINGLE_ASSET_WHITELIST_ROLE =
    keccak256("SINGLE_ASSET_WHITELIST_ROLE");
  bytes32 public constant LAAS_WHITELIST_ROLE =
    keccak256("LAAS_WHITELIST_ROLE");

  // Both sums are running sums. If a user deposits [$1, $5, $3], then
  // userSums would be [$1, $6, $9]. You can figure out the deposit
  // amount be subtracting userSums[i]-userSum[i-1].

  // prefixSums is the total deposited for all investors + this
  // investors deposit at the time this deposit is made. So at
  // prefixSum[0], it would be $1 + totalDeposits, where totalDeposits
  // could be $1000 because other investors have put in money.
  struct Investor {
    uint256[] userSums;
    uint256[] prefixSums;
    bool claimed;
    bool withdrawn;
  }

  /**
   * @dev Given the total amount invested by the Vault, we want to find
   *   out how many of this investor's deposits were actually
   *   used. Use findUpperBound on the prefixSum to find the point
   *   where total deposits were accepted. For example, if $2000 was
   *   deposited by all investors and $1000 was invested, then some
   *   position in the prefixSum splits the array into deposits that
   *   got in, and deposits that didn't get in. That same position
   *   maps to userSums. This is the user's deposits that got
   *   in. Since we are keeping track of the sums, we know at that
   *   position the total deposits for a user was $15, even if it was
   *   15 $1 deposits. And we know the amount that didn't get in is
   *   the last value in userSum - the amount that got it.

   * @param investor A specific investor
   * @param invested The total amount invested by this Vault
   */
  function getInvestedAndExcess(Investor storage investor, uint256 invested)
    internal
    view
    returns (uint256 userInvested, uint256 excess)
  {
    uint256[] storage prefixSums_ = investor.prefixSums;
    uint256 length = prefixSums_.length;
    if (length == 0) {
      // There were no deposits. Return 0, 0.
      return (userInvested, excess);
    }
    uint256 leastUpperBound = prefixSums_.findUpperBound(invested);
    if (length == leastUpperBound) {
      // All deposits got in, no excess. Return total deposits, 0
      userInvested = investor.userSums[length - 1];
      return (userInvested, excess);
    }
    uint256 prefixSum = prefixSums_[leastUpperBound];
    if (prefixSum == invested) {
      // Not all deposits got in, but there are no partial deposits
      userInvested = investor.userSums[leastUpperBound];
      excess = investor.userSums[length - 1] - userInvested;
    } else {
      // Let's say some of my deposits got in. The last deposit,
      // however, was $100 and only $30 got in. Need to split that
      // deposit so $30 got in, $70 is excess.
      userInvested = leastUpperBound > 0
        ? investor.userSums[leastUpperBound - 1]
        : 0;
      uint256 depositAmount = investor.userSums[leastUpperBound] - userInvested;
      if (prefixSum - depositAmount < invested) {
        userInvested += (depositAmount + invested - prefixSum);
        excess = investor.userSums[length - 1] - userInvested;
      } else {
        excess = investor.userSums[length - 1] - userInvested;
      }
    }
  }

  /*
   Used to avoid phantom overflow issues that can arise during this calculation:
   @notice Calculates floor(x*y÷denominator) with full precision.
   @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
   @dec Credit to prb-math for refactoring for solidity ^0.8 https://github.com/paulrberg/prb-math/blob/main/contracts/PRBMath.sol
  */
  function safeMulDiv(
    uint256 x,
    uint256 y,
    uint256 denominator
  ) internal pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
    // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2^256 + prod0.
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly {
      let mm := mulmod(x, y, not(0))
      prod0 := mul(x, y)
      prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }
    // Handle non-overflow cases, 256 by 256 division.
    if (prod1 == 0) {
      unchecked {
        result = prod0 / denominator;
      }
      return result;
    }
    // Make sure the result is less than 2^256. Also prevents denominator == 0.
    if (prod1 >= denominator) {
      revert("OLib__MulDivOverflow(prod1, denominator)");
    }
    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////
    // Make division exact by subtracting the remainder from [prod1 prod0].
    uint256 remainder;
    assembly {
      // Compute remainder using mulmod.
      remainder := mulmod(x, y, denominator)
      // Subtract 256 bit number from 512 bit number.
      prod1 := sub(prod1, gt(remainder, prod0))
      prod0 := sub(prod0, remainder)
    }
    // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
    // See https://cs.stackexchange.com/q/138556/92363.
    unchecked {
      // Does not overflow because the denominator cannot be zero at this stage in the function.
      uint256 lpotdod = denominator & (~denominator + 1);
      assembly {
        // Divide denominator by lpotdod.
        denominator := div(denominator, lpotdod)
        // Divide [prod1 prod0] by lpotdod.
        prod0 := div(prod0, lpotdod)
        // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
        lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
      }
      // Shift in bits from prod1 into prod0.
      prod0 |= prod1 * lpotdod;
      // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
      // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
      // four bits. That is, denominator * inv = 1 mod 2^4.
      uint256 inverse = (3 * denominator) ^ 2;
      // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel’s lifting lemma, this also works
      // in modular arithmetic, doubling the correct bits in each step.
      inverse *= 2 - denominator * inverse; // inverse mod 2^8
      inverse *= 2 - denominator * inverse; // inverse mod 2^16
      inverse *= 2 - denominator * inverse; // inverse mod 2^32
      inverse *= 2 - denominator * inverse; // inverse mod 2^64
      inverse *= 2 - denominator * inverse; // inverse mod 2^128
      inverse *= 2 - denominator * inverse; // inverse mod 2^256
      // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
      // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
      // less than 2^256, this is the final result. We don’t need to compute the high bits of the result and prod1
      // is no longer required.
      result = prod0 * inverse;
      return result;
    }
  }
}

/**
 * @title Subset of SafeERC20 from openZeppelin
 *
 * @dev Some non-standard ERC20 contracts (e.g. Tether) break
 * `approve` by forcing it to behave like `safeApprove`. This means
 * `safeIncreaseAllowance` will fail when it tries to adjust the
 * allowance. The code below simply adds an extra call to
 * `approve(spender, 0)`.
 */
library OndoSaferERC20 {
  using SafeERC20 for IERC20;

  function ondoSafeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    token.safeApprove(spender, 0);
    token.safeApprove(spender, newAllowance);
  }
}