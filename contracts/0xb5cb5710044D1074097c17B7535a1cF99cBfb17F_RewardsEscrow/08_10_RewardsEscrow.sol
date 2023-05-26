// SPDX-License-Identifier: GPL-3.0
// Docgen-SOLC: 0.8.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IStaking.sol";
import "../interfaces/IRewardsEscrow.sol";

contract RewardsEscrow is IRewardsEscrow, ReentrancyGuard, Ownable {
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */
  struct Escrow {
    uint256 start;
    uint256 lastUpdateTime;
    uint256 end;
    uint256 initialBalance;
    uint256 balance;
    address account;
  }

  IERC20 public immutable POP;

  // addresses that are authorized to create locks
  mapping(address => bool) public authorized;

  mapping(bytes32 => Escrow) public escrows;
  mapping(address => bytes32[]) public escrowIdsByAddress;
  uint256 internal nonce;

  /* ========== EVENTS ========== */
  event Locked(address indexed account, uint256 amount);
  event RewardsClaimed(address indexed account, uint256 amount);
  event TokenAdded(address token, uint256 index);
  event AddAuthorizedContract(address _contract);
  event RemoveAuthorizedContract(address _contract);

  /* ========== CONSTRUCTOR ========== */

  constructor(IERC20 _pop) {
    POP = _pop;
  }

  /* ========== VIEWS ========== */

  /**
   * @notice Returns whether the escrow is claimable
   * @param _escrowId Bytes32 escrow ID
   */
  function isClaimable(bytes32 _escrowId) external view returns (bool) {
    return escrows[_escrowId].lastUpdateTime != 0 && escrows[_escrowId].balance > 0;
  }

  /**
   * @notice Returns claimable amount for a given escrow
   * @param _escrowId Bytes32 escrow ID
   */
  function getClaimableAmount(bytes32 _escrowId) external view returns (uint256) {
    return _getClaimableAmount(escrows[_escrowId]);
  }

  /**
   * @notice Returns all escrowIdsByAddress which an account has/had claims in
   * @param _account address
   */
  function getEscrowIdsByUser(address _account) external view returns (bytes32[] memory) {
    return escrowIdsByAddress[_account];
  }

  /**
   * @notice Returns an array of Escrows
   * @param _escrowIds array of escrow ids
   * @dev there is no check to ensure that all escrows are owned by the same account. Make sure to account for this either by only sending ids for a specific account or by filtering the Escrows by account later on.
   */
  function getEscrows(bytes32[] calldata _escrowIds) external view returns (Escrow[] memory) {
    Escrow[] memory selectedEscrows = new Escrow[](_escrowIds.length);
    for (uint256 i = 0; i < _escrowIds.length; i++) {
      selectedEscrows[i] = escrows[_escrowIds[i]];
    }
    return selectedEscrows;
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
   * @notice Locks funds for escrow
   * @dev This creates a separate escrow structure which can later be iterated upon to unlock the escrowed funds
   */
  function lock(
    address _account,
    uint256 _amount,
    uint256 _duration
  ) external override nonReentrant {
    require(authorized[msg.sender], "unauthorized");
    require(_amount > 0, "amount must be greater than 0");
    require(POP.balanceOf(msg.sender) >= _amount, "insufficient balance");
    require(_duration > 0, "duration must be > 0");

    nonce++;
    bytes32 id = keccak256(abi.encodePacked(_account, _amount, block.timestamp, nonce));

    escrows[id] = Escrow({
      start: block.timestamp,
      lastUpdateTime: block.timestamp,
      end: block.timestamp + _duration,
      initialBalance: _amount,
      balance: _amount,
      account: _account
    });

    escrowIdsByAddress[_account].push(id);

    POP.safeTransferFrom(msg.sender, address(this), _amount);

    emit Locked(_account, _amount);
  }

  /**
   * @notice Claim vested funds in escrow
   * @dev Uses the escrowId at the specified index of escrowIdsByAddress.
   * @dev This function is used when a user only wants to claim a specific escrowVault or if they decide the gas cost of claimRewards is too high for now.
   * @dev (lower cost but also lower reward)
   */
  function claimReward(bytes32 _escrowId) external nonReentrant {
    Escrow memory escrow = escrows[_escrowId];
    require(msg.sender == escrow.account, "unauthorized");
    uint256 reward = _claimReward(_escrowId);
    require(reward > 0, "no rewards");

    POP.safeTransfer(msg.sender, reward);

    emit RewardsClaimed(msg.sender, reward);
  }

  /**
   * @notice Claim rewards for multiple escrows
   * @dev Uses the vaultIds at the specified indices of escrowIdsByAddress.
   * @dev This function is used when a user wants to claim multiple escrowVaults at once (probably most of the time)
   * @dev prevention for gas overflow should be handled in the frontend
   */
  function claimRewards(bytes32[] calldata _escrowIdsByAddress) external nonReentrant {
    uint256 total;

    for (uint256 i = 0; i < _escrowIdsByAddress.length; i++) {
      bytes32 _escrowId = _escrowIdsByAddress[i];
      Escrow memory escrow = escrows[_escrowId];
      require(msg.sender == escrow.account, "unauthorized");
      uint256 reward = _claimReward(_escrowId);
      total += reward;
    }
    require(total > 0, "no rewards");

    POP.safeTransfer(msg.sender, total);

    emit RewardsClaimed(msg.sender, total);
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  function addAuthorizedContract(address _staking) external onlyOwner {
    authorized[_staking] = true;
    emit AddAuthorizedContract(_staking);
  }

  function removeAuthorizedContract(address _staking) external onlyOwner {
    delete authorized[_staking];
    emit RemoveAuthorizedContract(_staking);
  }

  /**
   * @notice Underlying function to calculate the rewards that a user gets
   * @dev We don't want it to error when a vault is empty for the user as this would terminate the entire loop when used in claimRewards()
   */
  function _claimReward(bytes32 _escrowId) internal returns (uint256) {
    Escrow storage escrow = escrows[_escrowId];
    if (escrow.lastUpdateTime <= block.timestamp) {
      uint256 claimable = _getClaimableAmount(escrow);
      escrow.balance -= claimable;
      escrow.lastUpdateTime = block.timestamp;
      return claimable;
    }
    return 0;
  }

  function _getClaimableAmount(Escrow memory _escrow) internal view returns (uint256) {
    if (_escrow.lastUpdateTime == 0 || _escrow.end == 0 || _escrow.balance == 0) {
      return 0;
    }
    return
      Math.min(
        (_escrow.balance * (block.timestamp - _escrow.lastUpdateTime)) / (_escrow.end - _escrow.lastUpdateTime),
        _escrow.balance
      );
  }
}