// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "IERC20.sol";

/**
 * @title StablePlaza exchange contract, a low-cost multi token DEX for stable coins.
 * @author Jazzer9F
 */
interface IStablePlaza {
  error TokenNotFound();                        // 0xcbdb7b30
  error ExchangeLocked();                       // 0x2903d20f
  error InsufficientOutput();                   // 0xbb2875c3
  error InvariantViolation();                   // 0x302e29cb
  error StakeIsStillLocked();                   // 0x828aa811
  error AdminRightsRequired();                  // 0x9c60c1ef
  error TokenReserveNotEmpty();                 // 0x51692a42
  error InsufficientLiquidity();                // 0xbb55fd27
  error ExcessiveLiquidityInput();              // 0x5bdb0437
  error InsufficientFlashloanRepayment();       // 0x56cc0682
  error ZeroStakeAdditionIsNotSupported();      // 0xa38d3034

  // exchange configuration
  struct Config {
    uint16 locked;                    // 1st bit is function lock, 2nd bit is admin lock (16 bits to align the rest properly)
    uint8 feeLevel;                   // parts out of 10000 levied as fee on swaps / liquidity add (max fee 2.55%)
    uint8 flashLoanFeeLevel;          // parts out of 10000 levied as fee on flash loans (max fee 2.55%)
    uint8 stakerFeeFraction;          // cut of the fee for the stakers (parts out of 256)
    uint8 maxLockingBonus;            // bonus that can be achieved by staking longer
    uint16 maxLockingTime;            // time at which maximum bonus is achieved [days]
    uint64 Delta;                     // virtual liquidity, projecting onto desired curve
    uint64 unclaimedRewards;          // liquidity rewards that have no owner yet
    uint64 totalSupply;               // copy of the totalSupply for flash removals
  }

  // listed token data
  struct Token {
    IERC20 token;                     // ERC20 contract address of listed token
    uint64 denormFactor;              // factor to scale as if it used 6 decimals
  }

  // used to group variables in swap function
  struct SwapVariables {              // struct keeping variables relevant to swap together
    Token token0;                     // token used as input into the swap
    Token token1;                     // token used as output of the swap
    uint256 balance0;                 // balance of input token
    uint256 balance1;                 // balance of output token
    uint256 inputAmount;              // amount of input token supplied into swap
  }

  // global staking variables squeezed in 256 bits
  struct StakingState {
    uint64 totalShares;                 // total staking shares issued currently
    uint96 rewardsPerShare;             // rewards accumulated per staked token (16.80 bits)
    uint64 lastSyncedUnclaimedRewards;  // unclaimed rewards at last (un)stake
  }

  // struct holding data for each staker
  struct StakerData {
    uint64 stakedAmount;                // amount of staked tokens belonging to this staker (times 2^32)
    uint64 sharesEquivalent;            // equivalent shares of stake (locking longer grants more shares)
    uint96 rewardsPerShareWhenStaked;   // baseline rewards when this stake began (16.80 bits)
    uint32 unlockTime;                  // timestamp when stake can be unstaked
  }

  /**
   * @notice Retrieve the index of a token in the pool.
   * @param token The address of the token to retrieve the index of
   * @return index The index of the token in the pool
   */
  function getIndex(IERC20 token) external view returns (uint256 index);

  /**
   * @notice Retrieve the token corresponding to a certain index.
   * @param index The index of the token in the pool
   * @return token The address of the token to retrieve the index of
   */
  function getTokenFromIndex(uint256 index) external view returns (IERC20 token);

  /**
   * @notice Calculates the maximum outputToken that can be asked for a certain amount of inputToken.
   * @param inputIndex The index of the inputToken on StablePlaza tokens array
   * @param outputIndex The index of the outputToken on StablePlaza tokens array
   * @param inputAmount The amount of inputToken to be used
   * @return maxOutputAmount The maximum amount of outputToken that can be asked for
   */
  function getOutFromIn(
    uint256 inputIndex,
    uint256 outputIndex,
    uint256 inputAmount
  ) external view returns(uint256 maxOutputAmount);

  /**
   * @notice Calculates the minimum input required to swap a certain output
   * @param inputIndex The index of the inputToken on StablePlaza tokens array
   * @param outputIndex The index of the outputToken on StablePlaza tokens array
   * @param outputAmount The amount of outputToken desired
   * @return minInputAmount The minimum amount of inputToken required
   */
  function getInFromOut(
    uint256 inputIndex,
    uint256 outputIndex,
    uint256 outputAmount
  ) external view returns(uint256 minInputAmount);

  /**
   * @notice Calculates the amount of LP tokens generated for given input amount
   * @param tokenIndex The index of the token in the reserves array
   * @param inputAmount The amount of the input token added as new liquidity
   * @return maxLPamount The maximum amount of LP tokens generated
   */
  function getLPsFromInput(
    uint256 tokenIndex,
    uint256 inputAmount
  ) external view returns(uint256 maxLPamount);

  /**
   * @notice Calculates the amount of input tokens required to generate a certain amount of LP tokens
   * @param tokenIndex The index of the token in the reserves array
   * @param LPamount The amount of LP tokens to be generated
   * @param fromCallback Set to true if this function is called from IStablePlazaAddCallee to compensate for preminted LPs
   * @return minInputAmount The minimum amount of input tokens required
   */
  function getInputFromLPs(
    uint256 tokenIndex,
    uint256 LPamount,
    bool fromCallback
  ) external view returns(uint256 minInputAmount);

  /**
   * @notice Calculates the amount tokens released when withdrawing a certain amount of LP tokens
   * @param tokenIndex The index of the token in the reserves array
   * @param LPamount The amount of LP tokens of the caller to be burnt
   * @return maxOutputAmount The amount of tokens that can be withdrawn for this amount of LP tokens
   */
  function getOutputFromLPs(
    uint256 tokenIndex,
    uint256 LPamount
  ) external view returns(uint256 maxOutputAmount);

  /**
   * @notice Calculates the amount of LP tokens required for to withdraw given amount of tokens
   * @param tokenIndex The index of the token in the reserves array
   * @param outputAmount The amount of tokens the caller wishes to receive
   * @return minLPamount The minimum amount of LP tokens required
   */
  function getLPsFromOutput(
    uint256 tokenIndex,
    uint256 outputAmount
  ) external view returns(uint256 minLPamount);

  /**
   * @notice Function to allow users to swap between any two tokens listed on the DEX. Confirms the trade meets the user requirements and then invokes {swap}.
   * @dev If the amount of output tokens falls below the `minOutputAmount` due to slippage, the swap will fail.
   * @param pairSelector The index of the input token + 256 times the index of the output token
   * @param inputAmount Amount of tokens inputed into the swap
   * @param minOutputAmount Minimum desired amount of output tokens
   * @param destination Address to send the amount of output tokens to
   * @return actualOutput The actual amount of output tokens send to the destination address
   */
  function easySwap(
    uint256 pairSelector,
    uint256 inputAmount,
    uint256 minOutputAmount,
    address destination
  ) external returns (uint256 actualOutput);

  /**
   * @notice Low level function to allow users to swap between any two tokens listed on the DEX. User needs to prepay or pay in the callback function. Does not protect against overpaying. For use in smart contracts which perform safety checks.
   * @dev Follows the constant product (x*y=k) swap invariant hyperbole with virtual liquidity.
   * @param pairSelector The index of the input token + 256 times the index of the output token
   * @param outputAmount Desired amount of output received from the swap
   * @param destination Address to send the amount of output output tokens to
   * @param data When not empty, swap callback function is invoked and this data array is passed through
   */
  function swap(
    uint256 pairSelector,
    uint256 outputAmount,
    address destination,
    bytes calldata data
  ) external;

  /**
   * @notice Single sided liquidity add which takes some tokens from the user, adds them to the liquidity pool and converts them into LP tokens.
   * @notice Adding followed by withdrawing incurs a penalty of ~0.74% when the exchange is in balance. The penalty can be mitigated or even be converted into a gain by adding to a token that is underrepresented and withdrawing from a token that is overrepresented in the exchange.
   * @dev Mathematically works like adding all tokens and swapping back to 1 token at no fee.
   *
   *         R = (1 + X_supplied/X_initial)^(1/4) - 1
   *         LP_minted = R * LP_total
   *
   * Adding liquidity incurs two forms of price impact.
   *   1. Impact from single sided add which is modeled with 3 internal swaps
   *   2. Impact from the numerical approximation required for calculation
   *
   * Price impact from swaps is limited to 1.5% in the most extreme cases, slippage due to approximation is in the order of 10-8.
   * @dev Takes payment and then invokes {addLiquidity}
   * @param tokenIndex Index of the token to be added
   * @param inputAmount Amount of input tokens to add to the pool
   * @param minLP Minimum accepted amount of LP tokens to receive in return
   * @param destination Address that LP tokens will be credited to
   * @return actualLP Actual amount of LP tokens received in return
   */
  function easyAdd(
    uint256 tokenIndex,
    uint256 inputAmount,
    uint256 minLP,
    address destination
  ) external returns (uint256 actualLP);

  /**
   * @notice Low level liquidity add function that assumes required token amount is already payed or payed in the callback.
   * @dev Doesn't protect the user from overpaying. Only for use in smart contracts which perform safety checks.
   * @param tokenIndex Index of the token to be added
   * @param LPamount Amount of liquidity tokens to be minted
   * @param destination Address that LP tokens will be credited to
   * @param data When not empty, addLiquidity callback function is invoked and this data array is passed through
   */
  function addLiquidity(
    uint256 tokenIndex,
    uint256 LPamount,
    address destination,
    bytes calldata data
  ) external;

  /**
   * @notice Single sided liquidity withdrawal.
   * @notice Adding followed by withdrawing incurs a penalty of ~0.74% when the exchange is in balance. The penalty can be mitigated or even be converted into a gain by adding to a token that is underrepresented and withdrawing from a token that is overrepresented in the exchange.
   * @dev Mathematically withdraws all 4 tokens in ratio and then swaps 3 back in at no fees.
   * Calculates the following:
   *
   *        R = LP_burnt / LP_initial
   *        X_out = X_initial * (1 - (1 - R)^4)
   *
   * No fee is applied for withdrawals.
   * @param tokenIndex Index of the token to be withdrawn, ranging from 0 to 3
   * @param LPamount Amount of LP tokens to exchange for the token to be withdrawn
   * @param minOutputAmount Minimum desired amount of tokens to receive in return
   * @param destination Address where the withdrawn liquidity is sent to
   * @return actualOutput Actual amount of tokens received in return
   */
  function easyRemove(
   uint256 tokenIndex,
   uint256 LPamount,
   uint256 minOutputAmount,
   address destination
  ) external returns (uint256 actualOutput);

  /**
   * @notice Low level liquidity remove function providing callback functionality. Doesn't protect the user from overpaying. Only for use in smart contracts which perform required calculations.
   * @param tokenIndex Index of the token to be withdrawn, ranging from 0 to 3
   * @param outputAmount Amount of tokens to be withdrawn from the pool
   * @param destination Address where the withdrawn liquidity is sent to
   * @param data Any data is passed through to the callback function
   */
  function removeLiquidity(
    uint256 tokenIndex,
    uint256 outputAmount,
    address destination,
    bytes calldata data
  ) external;

  /**
   * @notice Emit Swap event when tokens are swapped
   * @param sender Address of the caller
   * @param inputToken Input token of the swap
   * @param outputToken Output token of the swap
   * @param inputAmount Amount of input tokens inputed into the swap function
   * @param outputAmount Amount of output tokens received from the swap function
   * @param destination Address the amount of output tokens were sent to
   */
  event Swap(
    address sender,
    IERC20 inputToken,
    IERC20 outputToken,
    uint256 inputAmount,
    uint256 outputAmount,
    address destination
  );

  /**
   * @notice Emit Swap event when tokens are swapped
   * @param lender Address of the caller
   * @param token Token that was loaned out
   * @param amountLoaned The amount that was loaned out Output token of the swap
   * @param amountRepayed The amount that was repayed (includes fee)
   */
  event FlashLoan(
    address lender,
    IERC20 token,
    uint256 amountLoaned,
    uint256 amountRepayed
  );

  /**
   * @notice Emit LiquidityAdded event when liquidity is added
   * @param sender Address of the caller
   * @param token The token the liquidity was added in
   * @param tokenAmount Amount of tokens added
   * @param LPs Actual ammount of LP tokens minted
   */
  event LiquidityAdded(
    address sender,
    IERC20 token,
    uint256 tokenAmount,
    uint256 LPs
  );

  /**
   * @notice Emit LiquidityRemoved event when liquidity is removed
   * @param creditor Address of the entity withdrawing their liquidity
   * @param token The token the liquidity was removed from
   * @param tokenAmount Amount of tokens removed
   * @param LPs Actual ammount of LP tokens burned
   */
  event LiquidityRemoved(
    address creditor,
    IERC20 token,
    uint256 tokenAmount,
    uint256 LPs
  );

  /**
   * @notice Emit ListingChange event when listed tokens change
   * @param removedToken Token that used to be listed before this event
   * @param replacementToken Token that is listed from now on
   */
  event ListingChange(
    IERC20 removedToken,
    IERC20 replacementToken
  );

  /**
   * @notice Emit adminChanged event when the exchange admin address is changed
   * @param newAdmin Address of new admin, who can (un)lock the exchange
   */
  event AdminChanged(
    address newAdmin
  );

  /**
   * @notice Emit LockChanged event when the exchange is (un)locked by an admin
   * @param exchangeAdmin Address of the admin making the change
   * @param newLockValue The updated value of the lock variable
   */
  event LockChanged(
    address exchangeAdmin,
    uint256 newLockValue
  );

  /**
   * @notice Emit configUpdated event when parameters are changed
   * @param newFeeLevel Fee for swapping and adding liquidity (bps)
   * @param newFlashLoanFeeLevel Fee for flashloans (bps)
   * @param newStakerFeeFraction Fraction out of 256 of fee that is shared with stakers (-)
   * @param newMaxLockingBonus Maximum staker bonus for locking liquidity longer (-)
   * @param newMaxLockingTime Amount of time for which the maximum bonus is given (d)
   */
  event ConfigUpdated(
    uint8 newFeeLevel,
    uint8 newFlashLoanFeeLevel,
    uint8 newStakerFeeFraction,
    uint8 newMaxLockingBonus,
    uint16 newMaxLockingTime
  );
}