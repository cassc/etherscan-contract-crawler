// SPDX-License-Identifier: BUSL-1.1
// Metadrop Contracts (v2.1.0)

pragma solidity 0.8.21;

import {IERC20ConfigByMetadrop} from "../ERC20/IERC20ConfigByMetadrop.sol";
import {IErrors} from "../../Global/IErrors.sol";

interface IERC20DRIPool is IERC20ConfigByMetadrop, IErrors {
  enum PhaseStatus {
    beforePoolPhase,
    duringPoolPhase,
    afterPoolPhase
  }

  event AddToPool(address dripHolder, uint256 dripTokenMinted);

  event ClaimFromPool(
    address dripHolder,
    uint256 dripTokenBurned,
    uint256 pooledTokenClaimed
  );

  event RefundFromPool(
    address dripHolder,
    uint256 dripTokenBurned,
    uint256 ethRefunded
  );

  event LiquidityAddedFromPool(uint256 ethTotal, uint256 tokenTotal);

  /**
   * @dev {initialiseDRIP}
   *
   * Initalise configuration on a new minimal proxy clone
   *
   * @param poolParams_ bytes parameter object that will be decoded into configuration
   * items.
   * @param name_ the name of the associated ERC20 token
   * @param symbol_ the symbol of the associated ERC20 token
   */
  function initialiseDRIP(
    bytes calldata poolParams_,
    string calldata name_,
    string calldata symbol_
  ) external;

  /**
   * @dev {supplyForLP}
   *
   * Convenience function to return the LP supply from the ERC-20 token contract.
   *
   * @return supplyForLP_ The total supply for LP creation.
   */
  function supplyForLP() external view returns (uint256 supplyForLP_);

  /**
   * @dev {poolPhaseStatus}
   *
   * Convenience function to return the pool status in string format.
   *
   * @return poolPhaseStatus_ The pool phase status as a string
   */
  function poolPhaseStatus()
    external
    view
    returns (string memory poolPhaseStatus_);

  /**
   * @dev {vestingEndDate}
   *
   * The vesting end date, being the end of the pool phase plus number of days vesting, if any
   *
   * @return vestingEndDate_ The vesting end date as a timestamp
   */
  function vestingEndDate() external view returns (uint256 vestingEndDate_);

  /**
   * @dev Return if the pool total has exceeded the minimum:
   *
   * @return poolIsAboveMinimum_ If the pool is above the minimum (or not)
   */
  function poolIsAboveMinimum()
    external
    view
    returns (bool poolIsAboveMinimum_);

  /**
   * @dev {loadERC20AddressAndSeedETH}
   *
   * Load the target ERC-20 address. This is called by the factory in the same transaction as the clone
   * is instantiated
   *
   * @param createdERC20_ The ERC-20 address
   * @param poolCreator_ The creator of this pool
   */
  function loadERC20AddressAndSeedETH(
    address createdERC20_,
    address poolCreator_
  ) external payable;

  /**
   * @dev {addToPool}
   *
   * A user calls this to contribute to the pool
   *
   * Note that we could have used the receive method for this, and processed any ETH send to the
   * contract as a contribution to the pool. We've opted for the clarity of a specific method,
   * with the recieve method reverting an unidentified ETH.
   */
  function addToPool() external payable;

  /**
   * @dev {claimFromPool}
   *
   * A user calls this to burn their DRIP and claim their ERC-20 tokens
   *
   */
  function claimFromPool() external;

  /**
   * @dev {refundFromPool}
   *
   * A user calls this to burn their DRIP and claim an ETH refund where the
   * minimum ETH pooled amount was not exceeded
   *
   */
  function refundFromPool() external;

  /**
   * @dev {supplyLiquidity}
   *
   * When the pool phase is over this can be called to supply the pooled ETH to
   * the token contract. There it will be forwarded along with the LP supply of
   * tokens to uniswap to create the funded pair
   *
   * Note that this function can be called by anyone. While clearly it is likely
   * that this will be the project team, having this method open to anyone ensures that
   * liquidity will not be trapped in this contract if the team as unable to perform
   * this action.
   *
   * @param lockerFee_ The ETH fee required to lock LP tokens
   *
   */
  function supplyLiquidity(uint256 lockerFee_) external payable;
}