// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IClientBatchStorageAccess } from "./IClientBatchStorageAccess.sol";
/**
 * @notice Defines if the Batch will mint or redeem 3X
 */
enum BatchType {
  Mint,
  Redeem
}

/**
 * @notice The Batch structure is used both for Batches of Minting and Redeeming
 * @param batchType Determines if this Batch is for Minting or Redeeming 3X
 * @param batchId bytes32 id of the batch
 * @param claimable Shows if a batch has been processed and is ready to be claimed, the suppliedToken cant be withdrawn if a batch is claimable
 * @param unclaimedShares The total amount of unclaimed shares in this batch
 * @param sourceTokenBalance The total amount of deposited token (either DAI or 3X)
 * @param claimableTokenBalance The total amount of claimable token (either sUSD or 3X)
 * @param sourceToken the token one supplies for minting/redeeming another token. the token collateral used to mint or redeem a mintable/redeemable token
 * @param targetToken the token that is claimable after providing the suppliedToken for mint/redeem. the token that a mintable/redeemable token turns into during mint/redeem
 * @param owner address of client (controller contract) that owns this batch and has access rights to it. this makes it so that all balances are isolated and not accessible by other clients that added to this contract over time
 * todo add deposit caps
 */
struct Batch {
  bytes32 id;
  BatchType batchType;
  bytes32 batchId;
  bool claimable;
  uint256 unclaimedShares;
  uint256 sourceTokenBalance;
  uint256 targetTokenBalance;
  IERC20 sourceToken;
  IERC20 targetToken;
  address owner;
}

/**
 * @notice Each type of batch (mint/redeem) have a source token and target token.
 * @param targetToken the token which is minted or redeemed for
 * @param sourceToken the token which is supplied to the batch to be minted/redeemed
 */
struct BatchTokens {
  IERC20 targetToken;
  IERC20 sourceToken;
}

interface IViewableBatchStorage {
  function getAccountBatches(address account) external view returns (bytes32[] memory);

  function getBatch(bytes32 batchId) external view returns (Batch memory);

  function getBatchIds(uint256 index) external view returns (Batch memory);

  function getAccountBalance(bytes32 batchId, address owner) external view returns (uint256);
}

interface IAbstractBatchStorage is IClientBatchStorageAccess {
  function getBatchType(bytes32 batchId) external view returns (BatchType);

  /* ========== VIEW ========== */

  function previewClaim(
    bytes32 batchId,
    address owner,
    uint256 shares
  )
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  /* ========== SETTER ========== */

  function claim(
    bytes32 batchId,
    address owner,
    uint256 shares,
    address recipient
  ) external returns (uint256, uint256);

  /**
   * @notice This function allows a user to withdraw their funds from a batch before that batch has been processed
   * @param batchId From which batch should funds be withdrawn from
   * @param owner address that owns the account balance
   * @param amount amount of tokens to withdraw from batch
   * @param recipient address that will receive the token transfer. if address(0) then no transfer is made
   */
  function withdraw(
    bytes32 batchId,
    address owner,
    uint256 amount,
    address recipient
  ) external returns (uint256);

  function deposit(
    bytes32 batchId,
    address owner,
    uint256 amount
  ) external returns (uint256);

  /**
   * @notice approve allows the client contract to approve an address to be the recipient of a withdrawal or claim
   */
  function approve(
    IERC20 token,
    address delegatee,
    bytes32 batchId,
    uint256 amount
  ) external;

  /**
   * @notice This function transfers the batch source tokens to the client usually for a minting or redeming operation
   * @param batchId From which batch should funds be withdrawn from
   */
  function withdrawSourceTokenFromBatch(bytes32 batchId) external returns (uint256);

  /**
   * @notice Moves funds from unclaimed batches into the current mint/redeem batch
   * @param _sourceBatch the id of the claimable batch
   * @param _destinationBatch the id of the redeem batch
   * @param owner owner of the account balance
   * @param shares how many shares should be claimed
   */
  function moveUnclaimedIntoCurrentBatch(
    bytes32 _sourceBatch,
    bytes32 _destinationBatch,
    address owner,
    uint256 shares
  ) external returns (uint256);

  function depositTargetTokensIntoBatch(bytes32 id, uint256 amount) external returns (bool);

  function createBatch(BatchType _batchType, BatchTokens memory _tokens) external returns (bytes32);
}