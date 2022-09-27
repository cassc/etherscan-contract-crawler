// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@mean-finance/swappers/solidity/contracts/extensions/GetBalances.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../interfaces/IDCAHubSwapper.sol';
import './utils/DeadlineValidation.sol';

contract DCAHubSwapper is DeadlineValidation, AccessControl, GetBalances, IDCAHubSwapper {
  enum SwapPlan {
    // Used only for tests
    NONE,
    // Takes the necessary tokens from the caller
    SWAP_FOR_CALLER,
    // Executes swaps against DEXes
    SWAP_WITH_DEXES
  }
  struct SwapData {
    SwapPlan plan;
    bytes data;
  }
  /// @notice Data used for the callback
  struct SwapWithDexesCallbackData {
    // The different swappers involved in the swap
    address[] swappers;
    // The different swaps to execute
    SwapExecution[] executions;
    // A list of tokens to check for unspent balance
    address[] intermediateTokensToCheck;
    // The address that will receive the unspent tokens
    address leftoverRecipient;
    // This flag is just a way to make transactions cheaper. If Mean Finance is executing the swap, then it's the same for us
    // if the leftover tokens go to the hub, or to another address. But, it's cheaper in terms of gas to send them to the hub
    bool sendToProvideLeftoverToHub;
  }

  using SafeERC20 for IERC20;
  using Address for address;

  bytes32 public constant SUPER_ADMIN_ROLE = keccak256('SUPER_ADMIN_ROLE');
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
  bytes32 public constant SWAP_EXECUTION_ROLE = keccak256('SWAP_EXECUTION_ROLE');

  /// @notice Represents the lack of an executor. We are not using the zero address so that it's cheaper to modify
  address internal constant _NO_EXECUTOR = 0x000000000000000000000000000000000000dEaD;
  /// @notice The caller who initiated a swap execution
  address internal _swapExecutor = _NO_EXECUTOR;

  constructor(
    address _swapperRegistry,
    address _superAdmin,
    address[] memory _initialAdmins,
    address[] memory _initialSwapExecutors
  ) SwapAdapter(_swapperRegistry) {
    if (_superAdmin == address(0)) revert ZeroAddress();
    // We are setting the super admin role as its own admin so we can transfer it
    _setRoleAdmin(SUPER_ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setRoleAdmin(SWAP_EXECUTION_ROLE, SUPER_ADMIN_ROLE);
    _setupRole(SUPER_ADMIN_ROLE, _superAdmin);
    for (uint256 i = 0; i < _initialAdmins.length; i++) {
      _setupRole(ADMIN_ROLE, _initialAdmins[i]);
    }
    for (uint256 i = 0; i < _initialSwapExecutors.length; i++) {
      _setupRole(SWAP_EXECUTION_ROLE, _initialSwapExecutors[i]);
    }
  }

  /// @inheritdoc IDCAHubSwapper
  function swapForCaller(SwapForCallerParams calldata _parameters)
    external
    payable
    checkDeadline(_parameters.deadline)
    onlyRole(SWAP_EXECUTION_ROLE)
    returns (IDCAHub.SwapInfo memory _swapInfo)
  {
    // Set the swap's executor
    _swapExecutor = msg.sender;

    // Execute swap
    _swapInfo = _parameters.hub.swap(
      _parameters.tokens,
      _parameters.pairsToSwap,
      _parameters.recipient,
      address(this),
      new uint256[](_parameters.tokens.length),
      abi.encode(SwapData({plan: SwapPlan.SWAP_FOR_CALLER, data: ''})),
      _parameters.oracleData
    );

    // Check that limits were met
    for (uint256 i = 0; i < _swapInfo.tokens.length; ) {
      IDCAHub.TokenInSwap memory _tokenInSwap = _swapInfo.tokens[i];
      if (_tokenInSwap.reward < _parameters.minimumOutput[i]) {
        revert RewardNotEnough();
      } else if (_tokenInSwap.toProvide > _parameters.maximumInput[i]) {
        revert ToProvideIsTooMuch();
      }
      unchecked {
        i++;
      }
    }

    // Clear the swap executor
    _swapExecutor = _NO_EXECUTOR;
  }

  /// @inheritdoc IDCAHubSwapper
  function swapWithDexes(SwapWithDexesParams calldata _parameters)
    external
    payable
    onlyRole(SWAP_EXECUTION_ROLE)
    returns (IDCAHub.SwapInfo memory)
  {
    return _swapWithDexes(_parameters, false);
  }

  /// @inheritdoc IDCAHubSwapper
  function swapWithDexesForMean(SwapWithDexesParams calldata _parameters)
    external
    payable
    onlyRole(SWAP_EXECUTION_ROLE)
    returns (IDCAHub.SwapInfo memory)
  {
    return _swapWithDexes(_parameters, true);
  }

  /// @inheritdoc IDCAHubSwapper
  function optimizedSwap(OptimizedSwapParams calldata _parameters)
    external
    payable
    checkDeadline(_parameters.deadline)
    onlyRole(SWAP_EXECUTION_ROLE)
    returns (IDCAHub.SwapInfo memory)
  {
    // Approve whatever is necessary
    _approveAllowances(_parameters.allowanceTargets);

    // Execute swap
    return
      _parameters.hub.swap(
        _parameters.tokens,
        _parameters.pairsToSwap,
        address(this),
        address(this),
        new uint256[](_parameters.tokens.length),
        _parameters.callbackData,
        _parameters.oracleData
      );
  }

  /// @inheritdoc IDCAHubSwapper
  function revokeAllowances(RevokeAction[] calldata _revokeActions) external onlyRole(ADMIN_ROLE) {
    _revokeAllowances(_revokeActions);
  }

  /// @inheritdoc IDCAHubSwapper
  function sendDust(
    address _token,
    uint256 _amount,
    address _recipient
  ) external onlyRole(ADMIN_ROLE) {
    _sendToRecipient(_token, _amount, _recipient);
  }

  function _swapWithDexes(SwapWithDexesParams calldata _parameters, bool _sendToProvideLeftoverToHub)
    internal
    checkDeadline(_parameters.deadline)
    returns (IDCAHub.SwapInfo memory)
  {
    // Approve whatever is necessary
    _approveAllowances(_parameters.allowanceTargets);

    // Prepare data for callback
    SwapWithDexesCallbackData memory _callbackData = SwapWithDexesCallbackData({
      swappers: _parameters.swappers,
      executions: _parameters.executions,
      leftoverRecipient: _parameters.leftoverRecipient,
      sendToProvideLeftoverToHub: _sendToProvideLeftoverToHub,
      intermediateTokensToCheck: _parameters.intermediateTokensToCheck
    });

    // Execute swap
    return
      _parameters.hub.swap(
        _parameters.tokens,
        _parameters.pairsToSwap,
        address(this),
        address(this),
        new uint256[](_parameters.tokens.length),
        abi.encode(SwapData({plan: SwapPlan.SWAP_WITH_DEXES, data: abi.encode(_callbackData)})),
        _parameters.oracleData
      );
  }

  // solhint-disable-next-line func-name-mixedcase
  function DCAHubSwapCall(
    address,
    IDCAHub.TokenInSwap[] calldata _tokens,
    uint256[] calldata,
    bytes calldata _data
  ) external {
    SwapData memory _swapData = abi.decode(_data, (SwapData));
    if (_swapData.plan == SwapPlan.SWAP_WITH_DEXES) {
      _handleSwapWithDexesCallback(_tokens, _swapData.data);
    } else if (_swapData.plan == SwapPlan.SWAP_FOR_CALLER) {
      _handleSwapForCallerCallback(_tokens);
    } else {
      revert UnexpectedSwapPlan();
    }
  }

  function _handleSwapWithDexesCallback(IDCAHub.TokenInSwap[] calldata _tokens, bytes memory _data) internal {
    SwapWithDexesCallbackData memory _callbackData = abi.decode(_data, (SwapWithDexesCallbackData));

    // Validate that all swappers are allowlisted
    for (uint256 i = 0; i < _callbackData.swappers.length; ) {
      _assertSwapperIsAllowlisted(_callbackData.swappers[i]);
      unchecked {
        i++;
      }
    }

    // Execute swaps
    for (uint256 i = 0; i < _callbackData.executions.length; ) {
      SwapExecution memory _execution = _callbackData.executions[i];
      _callbackData.swappers[_execution.swapperIndex].functionCall(_execution.swapData, 'Call to swapper failed');
      unchecked {
        i++;
      }
    }

    // Send remaining tokens to either hub, or leftover recipient
    for (uint256 i = 0; i < _tokens.length; ) {
      IERC20 _token = IERC20(_tokens[i].token);
      uint256 _balance = _token.balanceOf(address(this));
      if (_balance > 0) {
        uint256 _toProvide = _tokens[i].toProvide;
        if (_toProvide > 0) {
          if (_callbackData.sendToProvideLeftoverToHub) {
            // Send everything to hub (we assume the hub is msg.sender)
            _token.safeTransfer(msg.sender, _balance);
          } else {
            // Send necessary to hub (we assume the hub is msg.sender)
            _token.safeTransfer(msg.sender, _toProvide);
            if (_balance > _toProvide) {
              // If there is some left, send to leftover recipient
              _token.safeTransfer(_callbackData.leftoverRecipient, _balance - _toProvide);
            }
          }
        } else {
          // Send reward to the leftover recipient
          _token.safeTransfer(_callbackData.leftoverRecipient, _balance);
        }
      }
      unchecked {
        i++;
      }
    }

    // Check intermediate tokens
    for (uint256 i = 0; i < _callbackData.intermediateTokensToCheck.length; ) {
      _sendBalanceOnContractToRecipient(_callbackData.intermediateTokensToCheck[i], _callbackData.leftoverRecipient);
      unchecked {
        i++;
      }
    }
  }

  function _handleSwapForCallerCallback(IDCAHub.TokenInSwap[] calldata _tokens) internal {
    // Load to mem to avoid reading storage multiple times
    address _swapExecutorMem = _swapExecutor;
    for (uint256 i = 0; i < _tokens.length; ) {
      IDCAHub.TokenInSwap memory _token = _tokens[i];
      if (_token.toProvide > 0) {
        // We assume that msg.sender is the DCAHub
        IERC20(_token.token).safeTransferFrom(_swapExecutorMem, msg.sender, _token.toProvide);
      }
      unchecked {
        i++;
      }
    }
  }

  function _approveAllowances(Allowance[] calldata _allowanceTargets) internal {
    for (uint256 i = 0; i < _allowanceTargets.length; ) {
      Allowance memory _allowance = _allowanceTargets[i];
      _maxApproveSpenderIfNeeded(_allowance.token, _allowance.allowanceTarget, false, _allowance.minAllowance);
      unchecked {
        i++;
      }
    }
  }
}