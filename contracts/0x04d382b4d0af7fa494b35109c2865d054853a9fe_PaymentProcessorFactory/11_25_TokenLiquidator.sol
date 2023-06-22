// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

import '../abstract/JBOperatable.sol';
import '../interfaces/IJBDirectory.sol';
import '../interfaces/IJBOperatorStore.sol';
import '../interfaces/IJBProjects.sol';
import '../interfaces/IJBPaymentTerminal.sol';
import '../libraries/JBOperations.sol';
import '../libraries/JBTokens.sol';

interface IWETH9 is IERC20 {
  function deposit() external payable;

  function withdraw(uint256) external;
}

enum TokenLiquidatorError {
  NO_TERMINALS_FOUND,
  INPUT_TOKEN_BLOCKED,
  INPUT_TOKEN_TRANSFER_FAILED,
  INPUT_TOKEN_APPROVAL_FAILED,
  ETH_TRANSFER_FAILED
}

interface ITokenLiquidator {
  receive() external payable;

  function liquidateTokens(
    IERC20 _token,
    uint256 _amount,
    uint256 _minValue,
    uint256 _jbxProjectId,
    address _beneficiary,
    string memory _memo,
    bytes memory _metadata
  ) external returns (uint256);

  function withdrawFees() external;

  function setProtocolFee(uint256 _feeBps) external;

  function setUniswapPoolFee(uint24 _uniswapPoolFee) external;

  function blockToken(IERC20 _token) external;

  function unblockToken(IERC20 _token) external;
}

contract TokenLiquidator is ITokenLiquidator, JBOperatable {
  enum TokenLiquidatorPaymentType {
    ETH_TO_SENDER, // TODO
    ETH_TO_TERMINAL,
    WETH_TO_TERMINAL
  }

  error LIQUIDATION_FAILURE(TokenLiquidatorError _errorCode);

  event AllowTokenLiquidation(IERC20 token);
  event PreventLiquidation(IERC20 token);

  address public constant WETH9 = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  ISwapRouter public constant uniswapRouter =
    ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  uint256 internal constant FEE_CAP_BPS = 500; // 5%
  uint256 internal constant PROTOCOL_PROJECT_ID = 1;

  IJBDirectory public jbxDirectory;
  IJBProjects public jbxProjects;
  uint256 public feeBps;
  mapping(IERC20 => bool) blockedTokens;
  uint24 public uniswapPoolFee;

  IJBPaymentTerminal transientTerminal;
  uint256 transientProjectId;
  address transientBeneficiary;
  string transientMemo;
  bytes transientMetadata;
  address transientSender;

  /**
   * @param _jbxDirectory Juicebox directory for payment terminal lookup.
   * @param _feeBps Protocol swap fee.
   * @param  _uniswapPoolFee Uniswap pool fee.
   */
  constructor(
    IJBDirectory _jbxDirectory,
    IJBOperatorStore _jbxOperatorStore,
    IJBProjects _jbxProjects,
    uint256 _feeBps,
    uint24 _uniswapPoolFee
  ) {
    if (_feeBps > FEE_CAP_BPS) {
      revert();
    }

    operatorStore = _jbxOperatorStore;

    jbxDirectory = _jbxDirectory;
    jbxProjects = _jbxProjects;
    feeBps = _feeBps;
    uniswapPoolFee = _uniswapPoolFee;
  }

  receive() external payable override {}

  /**
   * @notice Swap incoming token for Ether/WETH and deposit the proceeeds into the appropriate Juicebox terminal.
   *
   * @dev If _minValue is specified, will call exactOutputSingle, otherwise exactInputSingle on uniswap v3.
   * @dev msg.sender here is expected to be an instance of PaymentProcessor which would retain the sale proceeds if they cannot be forwarded to the Ether or WETH terminal for the given project.
   *
   * @param _token Token to liquidate
   * @param _amount Token amount to liquidate.
   * @param _minValue Minimum required Ether/WETH value for the incoming token amount.
   * @param _jbxProjectId Juicebox project ID to pay into.
   * @param _beneficiary IJBPaymentTerminal beneficiary argument.
   * @param _memo IJBPaymentTerminal memo argument.
   * @param _metadata IJBPaymentTerminal metadata argument.
   */
  function liquidateTokens(
    IERC20 _token,
    uint256 _amount,
    uint256 _minValue,
    uint256 _jbxProjectId,
    address _beneficiary,
    string memory _memo,
    bytes memory _metadata
  ) external override returns (uint256 remainingAmount) {
    if (blockedTokens[_token]) {
      revert LIQUIDATION_FAILURE(TokenLiquidatorError.INPUT_TOKEN_BLOCKED);
    }

    if (!_token.transferFrom(msg.sender, address(this), _amount)) {
      revert LIQUIDATION_FAILURE(TokenLiquidatorError.INPUT_TOKEN_TRANSFER_FAILED);
    }

    TokenLiquidatorPaymentType paymentDestination;

    IJBPaymentTerminal ethTerminal = jbxDirectory.primaryTerminalOf(_jbxProjectId, JBTokens.ETH);

    if (ethTerminal != IJBPaymentTerminal(address(0))) {
      transientTerminal = ethTerminal;
      transientProjectId = _jbxProjectId;
      transientBeneficiary = _beneficiary;
      transientMemo = _memo;
      transientMetadata = _metadata;
      transientSender = msg.sender;

      paymentDestination = TokenLiquidatorPaymentType.ETH_TO_TERMINAL;
    } else {
      IJBPaymentTerminal wethTerminal = jbxDirectory.primaryTerminalOf(_jbxProjectId, WETH9);

      if (wethTerminal != IJBPaymentTerminal(address(0))) {
        transientTerminal = wethTerminal; // NOTE: transfers to a WETH terminal happen here, no need to set transient state
        paymentDestination = TokenLiquidatorPaymentType.WETH_TO_TERMINAL;
      }
    }

    if (transientTerminal == IJBPaymentTerminal(address(0))) {
      revert LIQUIDATION_FAILURE(TokenLiquidatorError.NO_TERMINALS_FOUND);
    }

    if (!_token.approve(address(uniswapRouter), _amount)) {
      revert LIQUIDATION_FAILURE(TokenLiquidatorError.INPUT_TOKEN_APPROVAL_FAILED);
    }

    uint256 swapProceeds;
    if (_minValue == 0) {
      ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
        tokenIn: address(_token),
        tokenOut: WETH9,
        fee: uniswapPoolFee,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: _amount,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      });

      swapProceeds = uniswapRouter.exactInputSingle(params);
    } else {
      ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
        tokenIn: address(_token),
        tokenOut: WETH9,
        fee: uniswapPoolFee,
        recipient: address(this),
        deadline: block.timestamp,
        amountOut: _minValue,
        amountInMaximum: _amount,
        sqrtPriceLimitX96: 0
      });

      uint256 amountSpent = uniswapRouter.exactOutputSingle(params); // NOTE: this will revert if _minValue is not received
      swapProceeds = _minValue;

      if (amountSpent < _amount) {
        remainingAmount = _amount - amountSpent;
        _token.transfer(msg.sender, remainingAmount);
      }
    }

    _token.approve(address(uniswapRouter), 0);

    uint256 fee = (swapProceeds * feeBps) / 10_000;
    uint256 projectProceeds = swapProceeds - fee;

    if (paymentDestination == TokenLiquidatorPaymentType.ETH_TO_TERMINAL) {
      IWETH9(WETH9).withdraw(projectProceeds); // NOTE: will end up in receive()
      transientTerminal.pay{value: projectProceeds}(
        transientProjectId,
        projectProceeds,
        JBTokens.ETH,
        transientBeneficiary,
        0,
        false,
        transientMemo,
        transientMetadata
      );
    } else if (paymentDestination == TokenLiquidatorPaymentType.WETH_TO_TERMINAL) {
      IERC20(WETH9).approve(address(transientTerminal), projectProceeds);

      transientTerminal.pay(
        _jbxProjectId,
        projectProceeds,
        WETH9,
        _beneficiary,
        0,
        false,
        _memo,
        _metadata
      );

      IERC20(WETH9).approve(address(transientTerminal), 0);
      transientTerminal = IJBPaymentTerminal(address(0));
    }
  }

  /**
   * @notice A trustless way for withdraw WETH and Ether balances from this contract into the platform (project 1) terminal.
   */
  function withdrawFees() external override {
    IJBPaymentTerminal protocolTerminal = jbxDirectory.primaryTerminalOf(
      PROTOCOL_PROJECT_ID,
      WETH9
    );

    uint256 wethBalance = IERC20(WETH9).balanceOf(address(this));
    IERC20(WETH9).approve(address(protocolTerminal), wethBalance);

    protocolTerminal.pay(
      PROTOCOL_PROJECT_ID,
      wethBalance,
      WETH9,
      address(0),
      0,
      false,
      'TokenLiquidator fees',
      ''
    );

    IERC20(WETH9).approve(address(protocolTerminal), 0);

    if (address(this).balance != 0) {
      protocolTerminal = jbxDirectory.primaryTerminalOf(PROTOCOL_PROJECT_ID, JBTokens.ETH);
      protocolTerminal.pay{value: address(this).balance}(
        transientProjectId,
        address(this).balance,
        JBTokens.ETH,
        address(0),
        0,
        false,
        'TokenLiquidator fees',
        ''
      );
    }
  }

  /**
   * @notice Set protocol liquidation fee. This share of the swap proceeds will be taken out and kept for the protocol. Expressed in basis points.
   */
  function setProtocolFee(
    uint256 _feeBps
  )
    external
    override
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(PROTOCOL_PROJECT_ID),
      PROTOCOL_PROJECT_ID,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(PROTOCOL_PROJECT_ID)))
    )
  {
    if (_feeBps > FEE_CAP_BPS) {
      revert();
    }

    feeBps = _feeBps;
  }

  /**
   * @notice Set Uniswap pool fee.
   */
  function setUniswapPoolFee(
    uint24 _uniswapPoolFee
  )
    external
    override
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(PROTOCOL_PROJECT_ID),
      PROTOCOL_PROJECT_ID,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(PROTOCOL_PROJECT_ID)))
    )
  {
    uniswapPoolFee = _uniswapPoolFee;
  }

  /**
   * @notice Prevent liquidation of a specific token through the contract.
   */
  function blockToken(
    IERC20 _token
  )
    external
    override
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(PROTOCOL_PROJECT_ID),
      PROTOCOL_PROJECT_ID,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(PROTOCOL_PROJECT_ID)))
    )
  {
    blockedTokens[_token] = true;
    emit PreventLiquidation(_token);
  }

  /**
   * @notice Remove a previously blocked token from the block list.
   */
  function unblockToken(
    IERC20 _token
  )
    external
    override
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(PROTOCOL_PROJECT_ID),
      PROTOCOL_PROJECT_ID,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(PROTOCOL_PROJECT_ID)))
    )
  {
    if (blockedTokens[_token]) {
      delete blockedTokens[_token];
      emit AllowTokenLiquidation(_token);
    }
  }
}