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
import './TokenLiquidator.sol';

/**
 * @notice Project payment collection contract.
 *
 * This contract is functionally similar to JBETHERC20ProjectPayer, but it adds several useful features. This contract can accept a token and liquidate it on Uniswap if an appropriate terminal doesn't exist. This contract can be configured accept and retain the payment if certain failures occur, like funding cycle misconfiguration. This contract expects to have access to a project terminal for Eth and WETH. WETH terminal will be used to submit liquidation proceeds.
 */
contract PaymentProcessor is JBOperatable, ReentrancyGuard {
  error PAYMENT_FAILURE();
  error INVALID_ADDRESS();
  error INVALID_AMOUNT();

  struct TokenSettings {
    bool accept;
    bool liquidate;
  }

  address public constant WETH9 = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
  ISwapRouter public constant uniswapRouter =
    ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  IJBDirectory jbxDirectory;
  IJBProjects jbxProjects;
  ITokenLiquidator liquidator;
  uint256 jbxProjectId;
  bool ignoreFailures;
  bool defaultLiquidation;

  mapping(IERC20 => TokenSettings) tokenPreferences;

  /**
   * @notice This contract serves as a proxy between the payer and the Juicebox platform. It allows payment acceptance in case of Juicebox project misconfiguration. It allows acceptance of ERC20 tokens via liquidation even if there is no corresponding Juicebox payment terminal.
   *
   * @param _jbxDirectory Juicebox directory.
   * @param _jbxOperatorStore Juicebox operator store.
   * @param _jbxProjects Juicebox project registry.
   * @param _liquidator Platform liquidator contract.
   * @param _jbxProjectId Juicebox project id to pay into.
   * @param _ignoreFailures If payment forwarding to the Juicebox terminal fails, Ether will be retained in this contract and ERC20 tokens will be processed per stored instructions. Setting this to false will `revert` failed payment operations.
   * @param _defaultLiquidation Setting this to true will automatically attempt to convert the incoming ERC20 tokens into WETH via Uniswap unless there are specific settings for the given token. Setting it to false will attempt to send the tokens to an appropriate Juicebox terminal, on failure, _ignoreFailures will be followed.
   */
  constructor(
    IJBDirectory _jbxDirectory,
    IJBOperatorStore _jbxOperatorStore,
    IJBProjects _jbxProjects,
    ITokenLiquidator _liquidator,
    uint256 _jbxProjectId,
    bool _ignoreFailures,
    bool _defaultLiquidation
  ) {
    operatorStore = _jbxOperatorStore;

    jbxDirectory = _jbxDirectory;
    jbxProjects = _jbxProjects;
    liquidator = _liquidator;
    jbxProjectId = _jbxProjectId;
    ignoreFailures = _ignoreFailures;
    defaultLiquidation = _defaultLiquidation;
  }

  //*********************************************************************//
  // ----------------------- public transactions ----------------------- //
  //*********************************************************************//

  /**
   * @notice Forwards incoming Ether to Juicebox terminal.
   */
  receive() external payable {
    _processPayment(jbxProjectId, '', new bytes(0));
  }

  /**
   * @notice Forwards incoming Ether to Juicebox terminal.
   *
   * @param _memo Memo for the payment, can be blank, will be forwarded to the Juicebox terminal for event publication.
   * @param _metadata Metadata for the payment, can be blank, will be forwarded to the Juicebox terminal for event publication.
   */
  function processPayment(
    string memory _memo,
    bytes memory _metadata
  ) external payable nonReentrant {
    _processPayment(jbxProjectId, _memo, _metadata);
  }

  /**
   * @notice Forwards incoming tokens to a Juicebox terminal, optionally liquidates them.
   *
   * @dev Tokens for the given amount must already be approved for this contract.
   *
   * @dev If the incoming token is explicitly listed via `setTokenPreferences`, `accept` setting will be applied. Otherwise, if `defaultLiquidation` is enabled, that will be used. Otherwise if ignoreFailures is enabled, token amount will be transferred and stored in this contract. If none of the previous conditions are met, the function will revert.
   *
   * @param _token ERC20 token.
   * @param _amount Token amount to withdraw from the sender.
   * @param _minValue Optional minimum Ether liquidation value.
   * @param _memo Memo for the payment, can be blank, will be forwarded to the Juicebox terminal for event publication.
   * @param _metadata Metadata for the payment, can be blank, will be forwarded to the Juicebox terminal for event publication.
   */
  function processPayment(
    IERC20 _token,
    uint256 _amount,
    uint256 _minValue,
    string memory _memo,
    bytes memory _metadata
  ) external nonReentrant {
    TokenSettings memory settings = tokenPreferences[_token];
    if (settings.accept) {
      _processPayment(
        _token,
        _amount,
        _minValue,
        jbxProjectId,
        _memo,
        _metadata,
        settings.liquidate
      );
    } else if (defaultLiquidation) {
      _processPayment(_token, _amount, _minValue, jbxProjectId, _memo, _metadata, true);
    } else if (ignoreFailures) {
      _token.transferFrom(msg.sender, address(this), _amount);
    } else {
      revert PAYMENT_FAILURE();
    }
  }

  function canProcess(IERC20 _token) external view returns (bool accept) {
    accept = tokenPreferences[_token].accept || defaultLiquidation;
  }

  //*********************************************************************//
  // --------------------- privileged transactions --------------------- //
  //*********************************************************************//

  /**
   * @notice Registers specific preferences for a given token. This feature is optional. If no tokens are explicitly set as "acceptable" and defaultLiquidate is set to false, token payments into this contract will be rejected.
   *
   * @param _token Token to accept.
   * @param _acceptToken Acceptance flag, setting it to false removes the associated record from the registry.
   * @param _liquidateToken Liquidation flag, it's possible to accept a token and forward it as is to a terminal, accept it and retain it in this contract or accept it and liduidate it for WETH via Uniswap.
   */
  function setTokenPreferences(
    IERC20 _token,
    bool _acceptToken,
    bool _liquidateToken
  )
    external
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(jbxProjectId),
      jbxProjectId,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(jbxProjectId)))
    )
  {
    if (!_acceptToken) {
      delete tokenPreferences[_token];
    } else {
      tokenPreferences[_token] = TokenSettings(_acceptToken, _liquidateToken);
    }
  }

  /**
   * @notice Allows the contract manager (an account with JBOperations.MANAGE_PAYMENTS permission for this project) to set operation parameters. The most-restrictive more is false-false, in which case only the tokens explicitly set as `accept` via setTokenPreferences will be processed.
   *
   * @param _ignoreFailures Ignore some payment failures, this results in processPayment() calls succeeding in more cases and the contract accumulating an Ether or token balance.
   * @param _defaultLiquidation If a given token doesn't have a specific configuration, the payment would still be accepted and liquidated into WETH as part of the payment transaction.
   */
  function setDefaults(
    bool _ignoreFailures,
    bool _defaultLiquidation
  )
    external
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(jbxProjectId),
      jbxProjectId,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(jbxProjectId)))
    )
  {
    ignoreFailures = _ignoreFailures;
    defaultLiquidation = _defaultLiquidation;
  }

  /**
   * @notice Allows a caller with JBOperations.MANAGE_PAYMENTS permission for the given project, or the project controller to transfer an Ether balance held in this contract.
   */
  function transferBalance(
    address payable _destination,
    uint256 _amount
  )
    external
    nonReentrant
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(jbxProjectId),
      jbxProjectId,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(jbxProjectId)))
    )
  {
    if (_destination == address(0)) {
      revert INVALID_ADDRESS();
    }

    if (_amount == 0 || _amount > (payable(address(this))).balance) {
      revert INVALID_AMOUNT();
    }

    _destination.transfer(_amount);
  }

  /**
   * @notice Allows a caller with JBOperations.MANAGE_PAYMENTS permission for the given project, or the project controller to transfer an ERC20 token balance associated with this contract.
   *
   * @param _destination Account to assign token balance to.
   * @param _token ERC20 token to operate on.
   * @param _amount Token amount to transfer.
   *
   * @return ERC20 transfer function result.
   */
  function transferTokens(
    address _destination,
    IERC20 _token,
    uint256 _amount
  )
    external
    nonReentrant
    requirePermissionAllowingOverride(
      jbxProjects.ownerOf(jbxProjectId),
      jbxProjectId,
      JBOperations.MANAGE_PAYMENTS,
      (msg.sender == address(jbxDirectory.controllerOf(jbxProjectId)))
    )
    returns (bool)
  {
    if (_destination == address(0)) {
      revert INVALID_ADDRESS();
    }

    return _token.transfer(_destination, _amount);
  }

  //*********************************************************************//
  // ---------------------- internal transactions ---------------------- //
  //*********************************************************************//

  /**
   * @notice Ether payment processing.
   */
  function _processPayment(
    uint256 _jbxProjectId,
    string memory _memo,
    bytes memory _metadata
  ) internal virtual {
    IJBPaymentTerminal terminal = jbxDirectory.primaryTerminalOf(_jbxProjectId, JBTokens.ETH);

    if (address(terminal) == address(0) && !ignoreFailures) {
      revert PAYMENT_FAILURE();
    }

    if (address(terminal) != address(0)) {
      (bool success, ) = address(terminal).call{value: msg.value}(
        abi.encodeWithSelector(
          terminal.pay.selector,
          _jbxProjectId,
          msg.value,
          JBTokens.ETH,
          msg.sender,
          0,
          false,
          _memo,
          _metadata
        )
      );

      if (!success) {
        revert PAYMENT_FAILURE();
      }
    }
  }

  /**
     * @notice Token payment processing that optionally liquidates incoming tokens for Ether.
     * 
     * @dev The result of this function depends on existence of a `tokenPreferences` record for the given token, `ignoreFailures` and
    `defaultLiquidation` global settings.
     *
     * @dev This function will still revert, regardless of `ignoreFailures`, if there is a liquidation event and the ether proceeds are below `_minValue`, unless that parameter is `0`.
     * 
     * @param _token ERC20 token to accept.
     * @param _amount Amount of token to expect.
     * @param _minValue Minimum required Ether value for token amount. Receiving less than this from Uniswap will cause a revert even is ignoreFailures is set.
     * @param _jbxProjectId Juicebox project id.
     * @param _memo IJBPaymentTerminal memo.
     * @param _metadata IJBPaymentTerminal metadata.
     * @param _liquidateToken Liquidation flag, if set the token will be converted into Ether and deposited into the project's Ether terminal.
     */
  function _processPayment(
    IERC20 _token,
    uint256 _amount,
    uint256 _minValue,
    uint256 _jbxProjectId,
    string memory _memo,
    bytes memory _metadata,
    bool _liquidateToken
  ) internal {
    if (_liquidateToken) {
      _liquidate(_token, _amount, _minValue, _jbxProjectId, _memo, _metadata);
      return;
    }

    IJBPaymentTerminal terminal = jbxDirectory.primaryTerminalOf(_jbxProjectId, address(_token));

    if (address(terminal) == address(0) && !ignoreFailures) {
      revert PAYMENT_FAILURE();
    }

    if (address(terminal) == address(0) && defaultLiquidation) {
      _liquidate(_token, _amount, _minValue, _jbxProjectId, _memo, _metadata);
      return;
    }

    if (!_token.transferFrom(msg.sender, address(this), _amount)) {
      revert PAYMENT_FAILURE();
    }

    _token.approve(address(terminal), _amount);

    (bool success, ) = address(terminal).call(
      abi.encodeWithSelector(
        terminal.pay.selector,
        jbxProjectId,
        _amount,
        address(_token),
        msg.sender,
        0,
        false,
        _memo,
        _metadata
      )
    );

    _token.approve(address(terminal), 0);

    if (success) {
      return;
    }

    if (!ignoreFailures) {
      revert PAYMENT_FAILURE();
    }

    if (ignoreFailures && defaultLiquidation) {
      _liquidate(_token, _amount, _minValue, _jbxProjectId, _memo, _metadata);

      return;
    }
  }

  /**
   * @dev Liquidates tokens for Eth or WETH from the transaction sender.
   */
  function _liquidate(
    IERC20 _token,
    uint256 _amount,
    uint256 _minValue,
    uint256 _jbxProjectId,
    string memory _memo,
    bytes memory _metadata
  ) internal {
    _token.transferFrom(msg.sender, address(this), _amount);
    _token.approve(address(liquidator), _amount);

    uint256 remainingAmount = liquidator.liquidateTokens(
      _token,
      _amount,
      _minValue,
      _jbxProjectId,
      msg.sender,
      _memo,
      _metadata
    );
    if (remainingAmount != 0) {
      _token.transfer(msg.sender, remainingAmount);
    }

    _token.approve(address(liquidator), 0);
  }
}