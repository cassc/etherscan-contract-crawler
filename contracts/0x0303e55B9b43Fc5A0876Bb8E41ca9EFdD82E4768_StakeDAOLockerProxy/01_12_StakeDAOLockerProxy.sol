// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";

import "./interfaces/IStakeDAOGauge.sol";
import "./interfaces/IStakeDAOLockerProxy.sol";
import "./interfaces/IStakeDAOMultiMerkleStash.sol";
import "../../interfaces/ISnapshotDelegateRegistry.sol";

/// @title StakeDaoLockerProxy
/// @notice This contract is the main entry for stake tokens in StakeDAO.
contract StakeDAOLockerProxy is OwnableUpgradeable, IStakeDAOLockerProxy {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice Emitted when the operator for gauge is updated.
  /// @param _gauge The address of gauge updated.
  /// @param _operator The address of operator updated.
  event UpdateOperator(address _gauge, address _operator);

  /// @notice Emitted when the status of executor is updated.
  /// @param _executor The address of executor updated.
  /// @param _status The status of executor updated.
  event UpdateExecutor(address _executor, bool _status);

  /// @notice Emitted when claimer for sdCRV bribe rewards is update.
  /// @param _claimer The address of claimer updated.
  event UpdateClaimer(address _claimer);

  /// @dev The address of StakeDAO MultiMerkleStash contract.
  address private constant MULTI_MERKLE_STASH = 0x03E34b085C52985F6a5D27243F20C84bDdc01Db4;

  /// @notice Mapping from gauge address to operator address.
  mapping(address => address) public operators;

  /// @notice Whether the address is an executor.
  mapping(address => bool) public executors;

  /// @notice The address of sdCRV bribe rewards claimer.
  address public claimer;

  /// @notice The sdCRV bribe claim status for token => merkleRoot mapping.
  mapping(address => mapping(bytes32 => bool)) public claimed;

  modifier onlyOperator(address _gauge) {
    require(operators[_gauge] == msg.sender, "not operator");
    _;
  }

  modifier onlyExecutor() {
    require(executors[msg.sender], "not executor");
    _;
  }

  /********************************** Constructor **********************************/

  function initialize() external initializer {
    OwnableUpgradeable.__Ownable_init();
  }

  /********************************** Mutated Functions **********************************/

  /// @inheritdoc IStakeDAOLockerProxy
  function deposit(address _gauge, address _token) external override onlyOperator(_gauge) returns (uint256 _amount) {
    _amount = IERC20Upgradeable(_token).balanceOf(address(this));
    if (_amount > 0) {
      IERC20Upgradeable(_token).safeApprove(_gauge, 0);
      IERC20Upgradeable(_token).safeApprove(_gauge, _amount);
      // deposit without claiming rewards
      IStakeDAOGauge(_gauge).deposit(_amount);
    }
  }

  /// @inheritdoc IStakeDAOLockerProxy
  function withdraw(
    address _gauge,
    address _token,
    uint256 _amount,
    address _recipient
  ) external override onlyOperator(_gauge) {
    uint256 _balance = IERC20Upgradeable(_token).balanceOf(address(this));
    if (_balance < _amount) {
      // withdraw without claiming rewards
      IStakeDAOGauge(_gauge).withdraw(_amount - _balance);
    }
    IERC20Upgradeable(_token).safeTransfer(_recipient, _amount);
  }

  /// @inheritdoc IStakeDAOLockerProxy
  function claimRewards(address _gauge, address[] calldata _tokens)
    external
    override
    onlyOperator(_gauge)
    returns (uint256[] memory _amounts)
  {
    uint256 _length = _tokens.length;
    _amounts = new uint256[](_length);
    // record balances before to make sure only claimed delta tokens will be transfered.
    for (uint256 i = 0; i < _length; i++) {
      _amounts[i] = IERC20Upgradeable(_tokens[i]).balanceOf(address(this));
    }
    // This will claim all rewards including SDT.
    IStakeDAOGauge(_gauge).claim_rewards();
    for (uint256 i = 0; i < _length; i++) {
      _amounts[i] = IERC20Upgradeable(_tokens[i]).balanceOf(address(this)) - _amounts[i];
      if (_amounts[i] > 0) {
        IERC20Upgradeable(_tokens[i]).safeTransfer(msg.sender, _amounts[i]);
      }
    }
  }

  /// @inheritdoc IStakeDAOLockerProxy
  function claimBribeRewards(IStakeDAOMultiMerkleStash.claimParam[] memory _claims, address _recipient)
    external
    override
  {
    require(msg.sender == claimer, "only bribe claimer");
    uint256 _length = _claims.length;
    // 1. claim bribe rewards from StakeDAOMultiMerkleStash
    for (uint256 i = 0; i < _length; i++) {
      // in case someone has claimed the reward for this contract, we can still call this function to process reward.
      if (!IStakeDAOMultiMerkleStash(MULTI_MERKLE_STASH).isClaimed(_claims[i].token, _claims[i].index)) {
        IStakeDAOMultiMerkleStash(MULTI_MERKLE_STASH).claim(
          _claims[i].token,
          _claims[i].index,
          address(this),
          _claims[i].amount,
          _claims[i].merkleProof
        );
      }
    }

    // 2. transfer bribe rewards to _recipient
    for (uint256 i = 0; i < _length; i++) {
      address _token = _claims[i].token;
      bytes32 _root = IStakeDAOMultiMerkleStash(MULTI_MERKLE_STASH).merkleRoot(_token);
      require(!claimed[_token][_root], "bribe rewards claimed");

      IERC20Upgradeable(_token).safeTransfer(_recipient, _claims[i].amount);
      claimed[_token][_root] = true;
    }
  }

  /// @notice External function to execute anycall.
  /// @param _to The address of target contract to call.
  /// @param _value The value passed to the target contract.
  /// @param _data The calldata pseed to the target contract.
  function execute(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external onlyExecutor returns (bool, bytes memory) {
    // solhint-disable avoid-low-level-calls
    (bool success, bytes memory result) = _to.call{ value: _value }(_data);
    return (success, result);
  }

  /********************************** Restricted Functions **********************************/

  /// @notice Update the operator for StakeDAO gauge.
  /// @param _gauge The address of gauge to update.
  /// @param _operator The address of operator to update.
  function updateOperator(address _gauge, address _operator) external onlyOwner {
    operators[_gauge] = _operator;

    emit UpdateOperator(_gauge, _operator);
  }

  /// @notice Update the executor.
  /// @param _executor The address of executor to update.
  /// @param _status The status of executor to update.
  function updateExecutor(address _executor, bool _status) external onlyOwner {
    executors[_executor] = _status;

    emit UpdateExecutor(_executor, _status);
  }

  /// @notice Update the claimer for StakeDAO sdCRV bribe rewards.
  /// @param _claimer The address of claimer to update.
  function updateClaimer(address _claimer) external onlyOwner {
    claimer = _claimer;

    emit UpdateClaimer(_claimer);
  }

  /// @dev delegate sdCRV voting power.
  /// @param _registry The address of Snapshot Delegate Registry.
  /// @param _id The id for which the delegate should be set.
  /// @param _delegate The address of the delegate.
  function delegate(
    address _registry,
    bytes32 _id,
    address _delegate
  ) external onlyOwner {
    ISnapshotDelegateRegistry(_registry).setDelegate(_id, _delegate);
  }
}