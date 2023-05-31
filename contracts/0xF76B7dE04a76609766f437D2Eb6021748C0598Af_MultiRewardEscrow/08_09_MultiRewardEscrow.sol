// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.15

pragma solidity ^0.8.15;

import { SafeERC20Upgradeable as SafeERC20 } from "openzeppelin-contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { IERC20Upgradeable as IERC20 } from "openzeppelin-contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { Math } from "openzeppelin-contracts/utils/math/Math.sol";
import { Owned } from "./Owned.sol";
import { SafeCastLib } from "solmate/utils/SafeCastLib.sol";
import { Fee, Escrow } from "../interfaces/IMultiRewardEscrow.sol";

/**
 * @title   MultiRewardEscrow
 * @author  RedVeil
 * @notice  Permissionlessly escrow tokens for a specific period of time.
 *
 * Anyone can create an escrow for any token and any user.
 * The owner can only decide to take fees on the creation of escrows with certain tokens.
 */
contract MultiRewardEscrow is Owned {
  using SafeERC20 for IERC20;
  using SafeCastLib for uint256;

  /**
   * @notice Constructor for the Escrow contract.
   * @param _owner Owner of the contract. Controls management functions.
   * @param _feeRecipient Receiver of all fees.
   */
  constructor(address _owner, address _feeRecipient) Owned(_owner) {
    if(_feeRecipient == address(0)) revert ZeroAddress();
    feeRecipient = _feeRecipient;
  }

  /*//////////////////////////////////////////////////////////////
                            GET ESCROW VIEWS
    //////////////////////////////////////////////////////////////*/

  function getEscrowIdsByUser(address account) external view returns (bytes32[] memory) {
    return userEscrowIds[account];
  }

  function getEscrowIdsByUserAndToken(address account, IERC20 token) external view returns (bytes32[] memory) {
    return userEscrowIdsByToken[account][token];
  }

  /**
   * @notice Returns an array of Escrows.
   * @param escrowIds Array of escrow ids.
   * @dev there is no check to ensure that all escrows are owned by the same account. Make sure to account for this either by only sending ids for a specific account or by filtering the Escrows by account later on.
   */
  function getEscrows(bytes32[] calldata escrowIds) external view returns (Escrow[] memory) {
    Escrow[] memory selectedEscrows = new Escrow[](escrowIds.length);
    for (uint256 i = 0; i < escrowIds.length; i++) {
      selectedEscrows[i] = escrows[escrowIds[i]];
    }
    return selectedEscrows;
  }

  /*//////////////////////////////////////////////////////////////
                            LOCK LOGIC
    //////////////////////////////////////////////////////////////*/

  // EscrowId => Escrow
  mapping(bytes32 => Escrow) public escrows;

  // User => Escrows
  mapping(address => bytes32[]) public userEscrowIds;
  // User => RewardsToken => Escrows
  mapping(address => mapping(IERC20 => bytes32[])) public userEscrowIdsByToken;

  uint256 internal nonce;

  event Locked(IERC20 indexed token, address indexed account, uint256 amount, uint32 duration, uint32 offset);

  error ZeroAddress();
  error ZeroAmount();

  /**
   * @notice Locks funds for escrow.
   * @param token The token to be locked.
   * @param account Recipient of the escrowed funds.
   * @param amount Amount of tokens to be locked.
   * @param duration Duration of the escrow. Every escrow unlocks token linearly.
   * @param offset A cliff before the escrow starts.
   * @dev This creates a separate escrow structure which can later be iterated upon to unlock the escrowed funds.
   * @dev The Owner may decide to add a fee to the escrowed amount.
   */
  function lock(
    IERC20 token,
    address account,
    uint256 amount,
    uint32 duration,
    uint32 offset
  ) external {
    if (token == IERC20(address(0))) revert ZeroAddress();
    if (account == address(0)) revert ZeroAddress();
    if (amount == 0) revert ZeroAmount();
    if (duration == 0) revert ZeroAmount();

    token.safeTransferFrom(msg.sender, address(this), amount);

    nonce++;

    bytes32 id = keccak256(abi.encodePacked(token, account, amount, nonce));

    uint256 feePerc = fees[token].feePerc;
    if (feePerc > 0) {
      uint256 fee = Math.mulDiv(amount, feePerc, 1e18);

      amount -= fee;
      token.safeTransfer(feeRecipient, fee);
    }

    uint32 start = block.timestamp.safeCastTo32() + offset;

    escrows[id] = Escrow({
      token: token,
      start: start,
      end: start + duration,
      lastUpdateTime: start,
      initialBalance: amount,
      balance: amount,
      account: account
    });

    userEscrowIds[account].push(id);
    userEscrowIdsByToken[account][token].push(id);

    emit Locked(token, account, amount, duration, offset);
  }

  /*//////////////////////////////////////////////////////////////
                            CLAIM LOGIC
    //////////////////////////////////////////////////////////////*/

  event RewardsClaimed(IERC20 indexed token, address indexed account, uint256 amount);

  error NotClaimable(bytes32 escrowId);

  function isClaimable(bytes32 escrowId) external view returns (bool) {
    return escrows[escrowId].lastUpdateTime != 0 && escrows[escrowId].balance > 0;
  }

  function getClaimableAmount(bytes32 escrowId) external view returns (uint256) {
    return _getClaimableAmount(escrows[escrowId]);
  }

  /**
   * @notice Claim rewards for multiple escrows.
   * @param escrowIds Array of escrow ids.
   * @dev Uses the `vaultIds` at the specified indices of `userEscrows`.
   * @dev Prevention for gas overflow should be handled in the frontend
   */
  function claimRewards(bytes32[] memory escrowIds) external {
    for (uint256 i = 0; i < escrowIds.length; i++) {
      bytes32 escrowId = escrowIds[i];
      Escrow memory escrow = escrows[escrowId];

      uint256 claimable = _getClaimableAmount(escrow);
      if (claimable == 0) revert NotClaimable(escrowId);

      escrows[escrowId].balance -= claimable;
      escrows[escrowId].lastUpdateTime = block.timestamp.safeCastTo32();

      escrow.token.safeTransfer(escrow.account, claimable);
      emit RewardsClaimed(escrow.token, escrow.account, claimable);
    }
  }

  function _getClaimableAmount(Escrow memory escrow) internal view returns (uint256) {
    if (
      escrow.lastUpdateTime == 0 ||
      escrow.end == 0 ||
      escrow.balance == 0 ||
      block.timestamp.safeCastTo32() < escrow.start
    ) {
      return 0;
    }
    return
      Math.min(
        (escrow.balance * (block.timestamp - uint256(escrow.lastUpdateTime))) /
          (uint256(escrow.end) - uint256(escrow.lastUpdateTime)),
        escrow.balance
      );
  }

  /*//////////////////////////////////////////////////////////////
                            FEE LOGIC
    //////////////////////////////////////////////////////////////*/

  address public feeRecipient;

  // escrowToken => feeAmount
  mapping(IERC20 => Fee) public fees;

  event FeeSet(IERC20 indexed token, uint256 amount);

  error ArraysNotMatching(uint256 length1, uint256 length2);
  error DontGetGreedy(uint256 fee);
  error NoFee(IERC20 token);

  /**
   * @notice Set fees for multiple tokens. Caller must be the owner.
   * @param tokens Array of tokens.
   * @param tokenFees Array of fees for `tokens` in 1e18. (1e18 = 100%, 1e14 = 1 BPS)
   */
  function setFees(IERC20[] memory tokens, uint256[] memory tokenFees) external onlyOwner {
    if (tokens.length != tokenFees.length) revert ArraysNotMatching(tokens.length, tokenFees.length);

    for (uint256 i = 0; i < tokens.length; i++) {
      if (tokenFees[i] >= 1e17) revert DontGetGreedy(tokenFees[i]);

      fees[tokens[i]].feePerc = tokenFees[i];
      emit FeeSet(tokens[i], tokenFees[i]);
    }
  }
}