// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import {IERC173} from "./IERC173.sol";
import {IFiduLense} from "./IFiduLense.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";

interface IBackstop is IERC173 {
  /// @notice Returns the FIDU token contract address
  function fidu() external view returns (IERC20);

  /// @notice Returns the USDC token contract address
  function usdc() external view returns (IERC20);

  /* ================================================================================
                                     Terms
                               -----------------
  updating the terms of the backstop
  ================================================================================ */

  /**
   * @notice Propose new terms for the governor to accept
   * @dev only owner
   */
  function proposeTerms(TermsProposal calldata terms) external;

  /**
   * @notice Accept proposed terms and make them the active terms. Resets the proposed terms
   * @dev only governor
   */
  function acceptTerms() external;

  /**
   * @notice Returns the terms that are active. These terms control the parameters of the backstop
   */
  function activeTerms() external view returns (Terms memory);

  /**
   * @notice Returns the terms that are currently being proposed by the owner
   */
  function proposedTerms() external view returns (TermsProposal memory);

  /**
   * @notice Returns true if the backstop can still be swapped against
   */
  function isActive() external view returns (bool);

  /// @notice Returns the amount of backstop used
  function backstopUsed() external view returns (uint256);

  /// @notice Returns the amount of backstop available to the swapper,
  ///         accounting for their current position size.
  function backstopAvailable() external view returns (uint256);

  /* ================================================================================
                               Exchange functions
                               -----------------
  exchanging assets using the backstop
  ================================================================================ */

  /**
   * @notice Swap Usdc for Fidu using the current senior pool share price
   * @dev only swapper
   */
  function swapUsdcForFidu(uint256 usdcAmount) external returns (uint256);

  /**
   * @notice Returns the amount of FIDU received given a usdc amount
   */
  function previewSwapUsdcForFidu(uint256 usdcAmount) external returns (uint256);

  /**
   * @notice Swap Fidu for USDC using the current senior pool share price
   * @dev only swapper
   */
  function swapFiduForUsdc(uint256 fiduAmount) external returns (uint256);

  /**
   * @notice Returns the amount of usdc the received given a FIDU amount
   */
  function previewSwapFiduForUsdc(uint256 fiduAmount) external returns (uint256);

  /* ================================================================================
                               Funding functions
                               -----------------
  increasing or decreasing the balance of the backstop
  ================================================================================ */

  /**
   * @notice Withdraw any free FIDU and USDC. Only USDC above the backstop amount can be withdrawn
   * before the term end time. Fidu cannot be withdrawn before term end time.
   * @dev only owner
   */
  function sweep() external returns (uint256 amountUsdc, uint256 amountFidu);

  /**
   * @notice Returns the expected amount of FIDU and USDC that will be sent to
   * the caller of the sweep function
   */
  function previewSweep() external view returns (uint256 amountUsdc, uint256 amountFidu);

  /* ================================================================================
                            Access control functions
                            ------------------------
  Determining who has what role and transferring roles
  ================================================================================*/

  /**
   * @notice Returns the address that is permitted to exchange FIDU/USDC
   */
  function swapper() external view returns (address);

  /// @notice Returns the address that can set who the exchanger is
  function governor() external view returns (address);

  /**
   * @notice Transfer the governor role to another address
   */
  function transferGovernor(address addr) external;

  /* ================================================================================
                                     Events
  ================================================================================ */
  event GovernorTransferred(address indexed oldGovernor, address indexed newGovernor);

  /// @notice Emitted when USDC is swapped for FIDU
  /// @param usdcAmount amount of USDC swapped
  /// @param fiduReceived amount of FIDU received
  event SwapUsdcForFidu(address indexed from, uint256 usdcAmount, uint256 fiduReceived);

  /// @notice Emitted when FIDU for USDC is swapped
  /// @param from address that swapped
  /// @param fiduAmount amount of fidu that was swapped
  /// @param usdcReceived amount of usdc that was received
  event SwapFiduForUsdc(address indexed from, uint256 fiduAmount, uint256 usdcReceived);

  /// @notice Emitted when new terms are proposed
  /// @param from address that proposed the terms
  /// @param endTime term end time
  /// @param backstopPercentage value of swappers position needed to swap
  /// @param lense lense used for determining
  /// @param maxBackstopAmount backstop limit
  event TermsProposed(
    address indexed from,
    address swapper,
    uint64 endTime,
    uint64 backstopPercentage,
    IFiduLense lense,
    uint256 maxBackstopAmount
  );

  /// @notice Emitted when terms are accepted
  /// @param from address that accepted the terms
  /// @param endTime accepted end time
  /// @param backstopPercentage value of swappers position needed to swap
  /// @param lense lense contract
  /// @param maxBackstopAmount amount of backstop available
  event TermsAccepted(
    address indexed from,
    address swapper,
    uint64 endTime,
    uint64 backstopPercentage,
    IFiduLense lense,
    uint256 maxBackstopAmount
  );

  /// @notice Emitted when USDC is deposited into the contract
  event Deposit(address indexed from, uint256 amount);
  /// @notice Emitted when funds are swept from the contract
  event FundsSwept(address indexed from, uint256 usdcAmount, uint256 fiduAmount);
}

struct TermsProposal {
  /// @notice end of term. After the term end
  uint64 endTime;
  /// @notice lense contract for
  IFiduLense lense;
  /// @notice the address that can swap against the backstop
  address swapper;
  /// @notice Percentage of current position that will be backstopped
  uint64 backstopPercentage;
  /// @notice amount of backstop available
  uint256 maxBackstopAmount;
}

struct Terms {
  /// @notice end of term. After the term end
  uint64 endTime;
  /// @notice lense contract for
  IFiduLense lense;
  /// @notice the address that can swap against the backstop
  address swapper;
  /// @notice Percentage of current position that will be backstopped
  uint64 backstopPercentage;
  /// @notice amount of backstop that has been withdrawn
  uint256 backstopUsed;
  /// @notice amount of backstop available
  uint256 maxBackstopAmount;
}