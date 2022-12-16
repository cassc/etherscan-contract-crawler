// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@prb/math/contracts/PRBMathUD60x18.sol";
import "../interfaces/IDonationsRouter.sol";
import "../interfaces/IStakingRewards.sol";
import "../interfaces/IThinWallet.sol";
import "./Queue.sol";

contract DonationsRouter is IDonationsRouter, Ownable, Queue {
  using PRBMathUD60x18 for uint256;

  ERC20 public immutable override baseToken;
  IStakingRewards public immutable override stakingContract;

  address public immutable override walletImplementation;

  uint256 public override causeId;
  uint256 public override platformFee;

  /// Cause ID => Cause record
  mapping(uint256 => CauseRecord) public override causeRecords;

  /// Token => CauseID
  mapping(address => uint256) public override tokenCauseIds;

  /// Thin wallet salt => thin wallet address
  mapping(bytes32 => address) public override deployedWallets;
  // keccak(owner, token) => is registered
  mapping(bytes32 => bool) public isRegistered;

  constructor(
    address _baseToken,
    address _stakingContract,
    address _owner,
    address _walletImplementation
  ) {
    require(_baseToken != address(0), "invalid base token");
    require(_stakingContract != address(0), "invalid staking contract");
    require(_owner != address(0), "invalid owner");
    require(_walletImplementation != address(0), "invalid implementation");

    baseToken = ERC20(_baseToken);
    stakingContract = IStakingRewards(_stakingContract);
    walletImplementation = _walletImplementation;

    _transferOwnership(_owner);
  }

  function setPlatformFee(uint256 _fee) external override onlyOwner {
    emit UpdateFee(platformFee, _fee);
    platformFee = _fee;
  }

  function registerCause(CauseRegistrationRequest calldata _cause)
    external
    override
  {
    require(_cause.owner != address(0), "invalid owner");
    require(_cause.daoToken != address(0), "invalid token");

    bytes32 causeRegistrationHash = keccak256(
      abi.encode(_cause.owner, _cause.daoToken)
    );
    require(!isRegistered[causeRegistrationHash], "cause exists");
    isRegistered[causeRegistrationHash] = true;

    uint256 id = ++causeId; // Increments then returns, thus causeId starts at 1

    CauseRecord memory cause = CauseRecord({
      owner: _cause.owner,
      rewardPercentage: _cause.rewardPercentage,
      daoToken: _cause.daoToken,
      defaultWallet: calculateThinWallet(
        ThinWalletID({ causeId: id, thinWalletId: abi.encode(id) })
      )
    });

    causeRecords[id] = cause;

    emit RegisterCause(_cause.owner, _cause.daoToken, id);

    tokenCauseIds[_cause.daoToken] = id;
    address[] memory owners = new address[](1);
    owners[0] = _cause.owner;
    _deployWallet(
      _getSalt(ThinWalletID({ causeId: id, thinWalletId: abi.encode(id) })),
      owners
    );

    ERC20(_cause.daoToken).approve(address(stakingContract), type(uint256).max);
  }

  function updateCause(uint256 _causeId, CauseUpdateRequest calldata _cause)
    external
    override
  {
    require(_causeId <= causeId, "invalid cause");
    CauseRecord memory cause = causeRecords[_causeId];
    require(msg.sender == cause.owner, "not authorized");
    require(_cause.owner != address(0), "invalid owner");

    cause.owner = _cause.owner;
    cause.rewardPercentage = _cause.rewardPercentage;

    causeRecords[_causeId] = cause;

    emit UpdateCause(cause);
  }

  function calculateThinWallet(ThinWalletID memory _walletId)
    public
    view
    override
    returns (address wallet)
  {
    wallet = Clones.predictDeterministicAddress(
      walletImplementation,
      _getSalt(_walletId)
    );
  }

  function registerThinWallet(
    ThinWalletID calldata _walletId,
    address[] calldata _owners
  ) external override {
    bytes32 salt = _getSalt(_walletId);
    require(deployedWallets[salt] == address(0), "already deployed");
    require(_owners.length >= 1, "invalid owners");
    CauseRecord memory cause = causeRecords[_walletId.causeId];

    require(_walletId.causeId <= causeId, "invalid cause");
    require(msg.sender == cause.owner, "unauthorized");

    address wallet = calculateThinWallet(_walletId);

    emit RegisterWallet(wallet, _walletId);

    _deployWallet(salt, _owners);
  }

  function withdrawFromThinWallet(
    ThinWalletID calldata _walletId,
    WithdrawalRequest calldata _withdrawal,
    bytes32 _proposalId
  ) external override {
    require(_walletId.causeId <= causeId, "invalid cause");
    CauseRecord memory cause = causeRecords[_walletId.causeId];

    require(msg.sender == cause.owner, "unauthorized");
    require(_proposalId != "", "invalid proposal id");
    uint128 queueToWithdraw = getFront(_walletId.causeId);
    QueueItem memory item = getQueueItem(_walletId.causeId, queueToWithdraw);
    if (
      item.isUnclaimed &&
      item.id == keccak256(abi.encode(_walletId.causeId, _proposalId))
    ) {
      dequeue(_walletId.causeId);
    } else {
      revert("not head of queue");
    }

    bytes32 salt = _getSalt(_walletId);
    IThinWallet wallet = IThinWallet(deployedWallets[salt]);

    if (address(wallet) == address(0)) {
      address[] memory owners = new address[](1);
      owners[0] = cause.owner;
      wallet = IThinWallet(_deployWallet(salt, owners));

      emit RegisterWallet(address(wallet), _walletId);
    }

    emit WithdrawFromWallet(_walletId, _withdrawal);

    address rewardToken = address(baseToken);

    if (_withdrawal.token == rewardToken) {
      uint256 rewardAmount = _withdrawal.amount.mul(cause.rewardPercentage);
      uint256 feeAmount = _withdrawal.amount.mul(platformFee);

      IThinWallet.TokenMovement[]
        memory transfers = new IThinWallet.TokenMovement[](3);
      transfers[0] = IThinWallet.TokenMovement({
        token: rewardToken,
        recipient: owner(),
        amount: feeAmount
      });
      transfers[1] = IThinWallet.TokenMovement({
        token: rewardToken,
        recipient: _withdrawal.recipient,
        amount: _withdrawal.amount - (feeAmount + rewardAmount)
      });
      transfers[2] = IThinWallet.TokenMovement({
        token: rewardToken,
        recipient: address(this),
        amount: rewardAmount
      });

      wallet.transferERC20(transfers);

      (stakingContract.rewardToken()).increaseAllowance(
        address(stakingContract),
        rewardAmount
      );
      stakingContract.distributeRewards(cause.daoToken, rewardAmount);
    } else {
      IThinWallet.TokenMovement[]
        memory transfers = new IThinWallet.TokenMovement[](1);
      transfers[0] = IThinWallet.TokenMovement({
        token: rewardToken,
        recipient: _withdrawal.recipient,
        amount: _withdrawal.amount
      });
      wallet.transferERC20(transfers);
    }
  }

  function addToQueue(uint256 _causeId, bytes32 _proposalId) external {
    require(_proposalId != bytes32(0), "invalid proposal id");
    CauseRecord memory cause = causeRecords[_causeId];
    require(msg.sender == cause.owner, "unauthorized");
    bytes32 queueId = keccak256(abi.encode(_causeId, _proposalId));
    enqueue(_causeId, queueId);
  }

  function removeFromQueue(
    uint256 _causeId,
    bytes32 _proposalId,
    uint128 _index
  ) external {
    CauseRecord memory cause = causeRecords[_causeId];
    require(msg.sender == cause.owner, "unauthorized");

    bytes32 queueId = keccak256(abi.encode(_causeId, _proposalId));
    QueueItem memory item = getQueueItem(_causeId, _index);
    require(item.id == queueId, "id does not match index item");

    dequeue(_causeId, _index);
  }

  function getQueueAtIndex(uint256 _causeId, uint128 _index)
    external
    view
    returns (QueuedItem memory item)
  {
    QueueItem memory retrievedItem = getQueueItem(_causeId, _index);
    item = QueuedItem({
      next: retrievedItem.next,
      previous: retrievedItem.previous,
      id: retrievedItem.id,
      isUnclaimed: retrievedItem.isUnclaimed
    });
  }

  function getFirstInQueue(uint256 _causeId)
    external
    view
    returns (uint128 queueFront)
  {
    queueFront = getFront(_causeId);
  }

  function getLastInQueue(uint256 _causeId)
    external
    view
    returns (uint128 queueBack)
  {
    queueBack = getBack(_causeId);
  }

  /// ### Internal functions
  function _getSalt(ThinWalletID memory _walletId)
    internal
    pure
    returns (bytes32 salt)
  {
    salt = keccak256(abi.encode(_walletId));
  }

  function _deployWallet(bytes32 salt, address[] memory owners)
    internal
    returns (address wallet)
  {
    wallet = Clones.cloneDeterministic(walletImplementation, salt);

    deployedWallets[salt] = wallet;

    IThinWallet(wallet).initialize(address(this), owners);
  }
}