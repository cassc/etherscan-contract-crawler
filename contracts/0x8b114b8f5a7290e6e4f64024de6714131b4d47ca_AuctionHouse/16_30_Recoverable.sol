// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Recoverable feature
 * @dev should _only_ be used with contracts that should not store assets,
 * but instead interacted with value so there is potential to lose assets.
 */
abstract contract Recoverable is AccessControl {
  using SafeERC20 for IERC20;
  using Address for address payable;

  /* ========== CONSTANTS ========== */
  bytes32 public constant RECOVER_ROLE = keccak256("RECOVER_ROLE");

  /* ============ Events ============ */

  event Recovered(address onBehalfOf, address tokenAddress, uint256 amount);

  /* ========== MODIFIERS ========== */

  modifier isRecoverer {
    require(hasRole(RECOVER_ROLE, _msgSender()), "Recoverable/RecoverRole");
    _;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */
  /* ----- RECOVER_ROLE ----- */

  /**
   * @notice Provide accidental token retrieval.
   * @dev Sourced from synthetix/contracts/StakingRewards.sol
   */
  function recoverERC20(
    address to,
    address tokenAddress,
    uint256 tokenAmount
  ) external isRecoverer {
    emit Recovered(to, tokenAddress, tokenAmount);

    IERC20(tokenAddress).safeTransfer(to, tokenAmount);
  }

  /**
   * @notice Provide accidental ETH retrieval.
   */
  function recoverETH(address to) external isRecoverer {
    uint256 contractBalance = address(this).balance;

    emit Recovered(to, address(0), contractBalance);

    payable(to).sendValue(contractBalance);
  }
}