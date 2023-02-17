// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@mean-finance/swappers/solidity/contracts/extensions/GetBalances.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../interfaces/ICallerOnlyDCAHubSwapper.sol';
import './utils/DeadlineValidation.sol';

contract CallerOnlyDCAHubSwapper is DeadlineValidation, AccessControl, GetBalances, ICallerOnlyDCAHubSwapper {
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

  /// @inheritdoc ICallerOnlyDCAHubSwapper
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
      '',
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

  /// @inheritdoc ICallerOnlyDCAHubSwapper
  function revokeAllowances(RevokeAction[] calldata _revokeActions) external onlyRole(ADMIN_ROLE) {
    _revokeAllowances(_revokeActions);
  }

  /// @inheritdoc ICallerOnlyDCAHubSwapper
  function sendDust(
    address _token,
    uint256 _amount,
    address _recipient
  ) external onlyRole(ADMIN_ROLE) {
    _sendToRecipient(_token, _amount, _recipient);
  }

  // solhint-disable-next-line func-name-mixedcase
  function DCAHubSwapCall(
    address,
    IDCAHub.TokenInSwap[] calldata _tokens,
    uint256[] calldata,
    bytes calldata
  ) external {
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
}