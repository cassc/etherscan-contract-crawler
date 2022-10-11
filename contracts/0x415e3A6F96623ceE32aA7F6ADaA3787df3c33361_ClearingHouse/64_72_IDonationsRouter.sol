// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "../interfaces/IStakingRewards.sol";

interface IDonationsRouter {
  /// ### Structs
  struct CauseRegistrationRequest {
    address owner;
    uint256 rewardPercentage;
    address daoToken;
  }
  struct CauseUpdateRequest {
    address owner;
    uint256 rewardPercentage;
  }

  struct CauseRecord {
    address owner;
    address defaultWallet; /// Default wallet is calculated with cause Id and thin wallet id being equal to each other
    address daoToken;
    uint256 rewardPercentage; /// A PRBMath 60.18 fixed point number. 1e16 == 1% and 1e18 == 100%
  }

  struct WithdrawalRequest {
    address token;
    address recipient;
    uint256 amount;
  }

  struct ThinWalletID {
    uint256 causeId;
    bytes thinWalletId;
  }

  struct QueuedItem {
    uint128 next; // The next item to be claimed in the queue. If this is the last item (at back of queue), next should be 0
    uint128 previous; // The previous item in the queue. If this is the first item (at the front of the queue), previous should be 0
    bytes32 id; // An unique identifier for the queue item. This will link the add to queue and withdrawal functions.
    bool isUnclaimed; // Set to true when enqueuing. We can delete the struct when dequeueing, saving some gas.
  }

  /// ### Events

  event RegisterCause(
    address indexed owner,
    address indexed daoToken,
    uint256 causeId
  );
  event RegisterWallet(address indexed walletAddress, ThinWalletID walletId);
  event WithdrawFromWallet(ThinWalletID wallet, WithdrawalRequest request);
  event UpdateCause(CauseRecord cause);
  event UpdateRewardAddress(
    address indexed oldRewardAddress,
    address indexed newAddress
  );
  event UpdateFee(uint256 oldFee, uint256 newFee);

  /// ### Functions

  /// @notice Creates a cause so that it can start using thin wallets that it controls
  /// @dev This should be an open function
  /// @param _cause  The cause to be registered
  function registerCause(CauseRegistrationRequest calldata _cause) external;

  /// @notice Updates a cause
  /// @dev Can only be called by the current owner of the cause
  /// @param _causeId  The cause to update
  /// @param _cause  The new details of the cause
  function updateCause(uint256 _causeId, CauseUpdateRequest calldata _cause)
    external;

  /// @notice Sets the address of the staking contract so rewards can be distributed
  /// @dev This should be secured
  /// @param _rewardContract  The new staking contract
  // function setRewardAddress(address _rewardContract) external;

  /// @notice Calculates the address that a given thin wallet is or will be deployed to
  /// @param _walletId  The wallet parameters to calculate the address from
  function calculateThinWallet(ThinWalletID calldata _walletId)
    external
    view
    returns (address wallet);

  /// @notice Deploys a thin wallet to the address derived from the parameters given
  /// @param _walletId  The wallet parameters
  /// @param _owners  The wallet owners to set. These accounts can transfer funds, so they should be limited
  function registerThinWallet(
    ThinWalletID calldata _walletId,
    address[] calldata _owners
  ) external;

  /// @notice Withdraws funds from the specified thin wallet
  /// @param _walletId  The wallet address parameters
  /// @param _withdrawal  An array of withdrawal requests for the wallet to process
  function withdrawFromThinWallet(
    ThinWalletID calldata _walletId,
    WithdrawalRequest calldata _withdrawal,
    bytes32 _proposalId
  ) external;

  /// @notice Allows the platform owner to set the platform fee
  /// @dev Only the platform owner should be able to call this
  /// @param _fee  The new platform fee
  function setPlatformFee(uint256 _fee) external;

  /// @notice Adds a queue which is linked to a unique identifier using the hash of combined causeID and proposalID
  /// @param _causeId The cause id
  /// @param _proposalId The proposal id
  function addToQueue(uint256 _causeId, bytes32 _proposalId) external;

  /// @notice Removes a queue arbitrarily at specified index
  /// @param _causeId The cause id
  /// @param _proposalId The proposal id
  /// @param _index The queue index
  function removeFromQueue(
    uint256 _causeId,
    bytes32 _proposalId,
    uint128 _index
  ) external;

  /// @notice Gets queue item at specific index
  /// @param _causeId The cause id
  /// @param _index The queue index
  function getQueueAtIndex(uint256 _causeId, uint128 _index)
    external
    view
    returns (QueuedItem memory item);

  /// @notice Gets first item in queue
  /// @param _causeId The cause id
  function getFirstInQueue(uint256 _causeId)
    external
    view
    returns (uint128 queueFront);

  /// @notice Gets last item in queue
  /// @param _causeId The cause id
  function getLastInQueue(uint256 _causeId)
    external
    view
    returns (uint128 queueBack);

  /// ### Autogenerated getters

  function baseToken() external view returns (ERC20 baseToken);

  function stakingContract()
    external
    view
    returns (IStakingRewards stakingContract);

  function causeId() external view returns (uint256 causeId);

  function tokenCauseIds(address token) external view returns (uint256 causeId);

  function causeRecords(uint256 causeId)
    external
    view
    returns (
      address owner,
      address defaultWallet,
      address daoToken,
      uint256 rewardPercentage
    );

  function platformFee() external view returns (uint256 fee);

  function deployedWallets(bytes32 _salt)
    external
    view
    returns (address wallet);

  function walletImplementation()
    external
    view
    returns (address walletImplementation);
}