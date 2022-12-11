// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

/// interfaces
import {IERC20} from './interfaces/IERC20.sol';
import {IPlugRouterUpgradeable} from './interfaces/IPlugRouterUpgradeable.sol';
import {IBridgeAdapter} from './interfaces/IBridgeAdapter.sol';

// libraries
import {TransferHelpers} from './libraries/TransferHelpers.sol';

// contracts
import {Initializable} from './proxy/Initializable.sol';
import {OwnableUpgradeable} from './access/OwnableUpgradeable.sol';
import {ReentrancyGuardUpgradeable} from './security/ReentrancyGuardUpgradeable.sol';
import {PausableUpgradeable} from './security/PausableUpgradeable.sol';

/**
 * @title The PlugRouter Upgradeable Contract
 * @author Plug Exchange
 * @notice Performing swap,bridge deposit and crosschain Swap
 */
contract PlugRouterUpgradeable is
  IPlugRouterUpgradeable,
  Initializable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  PausableUpgradeable
{
  /// @notice Receive ETH
  receive() external payable {}

  /// @dev The swap fee configuration
  struct SwapFeeConfig {
    // swap fee percentage
    uint256 swapFeePercentage;
    // swap fee collector
    address swapFeeCollector;
  }

  /// @notice The swap fee config
  SwapFeeConfig public swapFeeConfig;

  /// @notice The fee denominator
  uint256 public constant FEE_DENOMINATER = 100000000;

  /// @notice The native token address
  address public constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  /// @notice The crosschain swap magic value
  bytes4 public constant CROSS_CHAIN_SWAP_MV = bytes4(keccak256(('crossChainSwap')));

  /// @notice The swap magic value
  bytes4 public constant SWAP_MV = bytes4(keccak256(('swap')));

  /// @notice The deposit magic value
  bytes4 public constant DEPOSIT_MV = bytes4(keccak256(('deposit')));

  /// @notice The map to lock specific user action
  mapping(bytes4 => bool) public lock;

  /// @notice The fee tokens config
  mapping(address => bool) public feeTokens;

  /// @notice The exchanges and bridges map
  mapping(bytes4 => address) public aggregatorsAndBridgesMap;

  /**
   * @notice Initialization of plug router
   * @param _swapFeePercentage The swap fee percentage
   * @param _swapFeeCollector The swap fee collector address
   * @param _trustedForwarder The trusted forwarder address
   */
  function __PlugRouterUpgradeable_init(
    uint256 _swapFeePercentage,
    address _swapFeeCollector,
    address _trustedForwarder
  ) external initializer {
    __Ownable_init(_trustedForwarder);
    __PlugRouterUpgradeable_init_unchained(_swapFeePercentage, _swapFeeCollector);
  }

  /**
   * @notice Sets fee config of plug router
   * @param _swapFeePercentage The swap fee percentage
   * @param _swapFeeCollector The swap fee collector address
   */
  function __PlugRouterUpgradeable_init_unchained(uint256 _swapFeePercentage, address _swapFeeCollector) internal {
    _setSwapFeeConfig(_swapFeePercentage, _swapFeeCollector);
  }

  /**
   * @inheritdoc IPlugRouterUpgradeable
   */
  function swap(
    address affiliateAddr,
    address fromToken,
    uint256 amount,
    bytes4 exchangeId,
    bytes calldata swapCallData
  ) external payable nonReentrant {
    require(!lock[SWAP_MV], 'SWAP_PAUSED');
    // swap
    (address outToken, uint256 swapedAmount) = _swap(fromToken, amount, exchangeId, swapCallData, true);
    // send tokens to user
    _transfers(outToken, _msgSender(), swapedAmount);

    emit SwapPerformed(affiliateAddr, _msgSender(), fromToken, outToken, amount, swapedAmount, exchangeId);
  }

  /**
   * @inheritdoc IPlugRouterUpgradeable
   */
  function crossChainSwap(
    address affiliateAddr,
    address fromToken,
    uint256 amount,
    bytes4 exchangeId,
    bytes4 bridgeId,
    bytes calldata swapCallData,
    bytes calldata bridgeCallData
  ) external payable nonReentrant {
    require(!lock[CROSS_CHAIN_SWAP_MV], 'CROSS_CHAIN_SWAP_PAUSED');
    // swap
    (address toToken, uint256 swapedAmount) = _swap(fromToken, amount, exchangeId, swapCallData, false);
    // deposit
    {
      if (toToken != NATIVE_TOKEN_ADDRESS) {
        TransferHelpers.safeTransfer(toToken, aggregatorsAndBridgesMap[bridgeId], swapedAmount);
      }

      uint256 toChainId = _deposit(
        _msgSender(),
        toToken,
        aggregatorsAndBridgesMap[bridgeId],
        swapedAmount,
        bridgeCallData
      );
      _logCrossChainSwap(affiliateAddr, fromToken, toToken, amount, swapedAmount, toChainId, exchangeId, bridgeId);
    }
  }

  /**
   * @inheritdoc IPlugRouterUpgradeable
   */
  function deposit(
    address affiliateAddr,
    address token,
    uint256 amount,
    bytes4 bridgeId,
    bytes calldata bridgeCallData
  ) external payable nonReentrant {
    require(!lock[DEPOSIT_MV], 'DEPOSIT_PAUSED');

    address bridgeAdapter = aggregatorsAndBridgesMap[bridgeId];
    require(bridgeAdapter != address(0), 'BRIDGE_ADAPTER_NOT_EXIST');

    pullTokens(token, bridgeAdapter, amount);
    // deposit
    uint256 toChainId = _deposit(_msgSender(), token, bridgeAdapter, amount, bridgeCallData);

    emit Deposit(affiliateAddr, _msgSender(), token, amount, toChainId, bridgeId);
  }

  /**
   * @inheritdoc IPlugRouterUpgradeable
   */
  function updateSwapFeeConfig(uint256 _swapFeePercentage, address _swapFeeCollector) external onlyOwner {
    _setSwapFeeConfig(_swapFeePercentage, _swapFeeCollector);
  }

  /**
   * @inheritdoc IPlugRouterUpgradeable
   */
  function addFeeTokens(address[] memory tokens, bool[] memory flags) external onlyOwner {
    uint256 len = tokens.length;
    require(len == flags.length, 'INVALID_ARRAY_LENGTH');

    for (uint256 k = 0; k < len; k++) {
      require(tokens[k] != address(0), 'INVALID_FEE_TOKEN');
      feeTokens[tokens[k]] = flags[k];
    }

    emit FeeTokens(tokens, flags);
  }

  /**
   * @inheritdoc IPlugRouterUpgradeable
   */
  function rescueTokens(
    address withdrawableAddress,
    address[] memory tokens,
    uint256[] memory amounts
  ) external onlyOwner {
    require(withdrawableAddress != address(0), 'ZERO_ADDRESS_NOT_ALLOWED');
    require(tokens.length == amounts.length, 'RESCUE_TOKEN_FAILED');

    uint8 len = uint8(tokens.length);
    uint8 i = 0;
    while (i < len) {
      TransferHelpers.safeTransfer(tokens[i], withdrawableAddress, amounts[i]);
      i++;
    }
  }

  /**
   * @inheritdoc IPlugRouterUpgradeable
   */
  function resuceEth(address withdrawableAddress, uint256 amount) external onlyOwner {
    require(withdrawableAddress != address(0), 'ZERO_ADDRESS_NOT_ALLOWED');
    TransferHelpers.safeTransferETH(withdrawableAddress, amount);
  }

  /**
   * @inheritdoc IPlugRouterUpgradeable
   */
  function setAggregatorsAndBridgeMap(bytes4[] memory ids, address[] memory routers) external onlyOwner {
    require(ids.length == routers.length, 'INVALID_LENGTH');
    uint8 len = uint8(ids.length);
    // iterate loop
    for (uint8 k = 0; k < len; k++) {
      require(ids[k] != bytes8(0), 'INVALID_ID');
      require(routers[k] != address(0), 'INVALID_ROUTER');
      aggregatorsAndBridgesMap[ids[k]] = routers[k];
    }

    emit SupportedAggregatorsAndBridges(ids, routers);
  }

  /**
   * @inheritdoc IPlugRouterUpgradeable
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @inheritdoc IPlugRouterUpgradeable
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @inheritdoc IPlugRouterUpgradeable
   */
  function startOrStopParticularUserAction(bytes4 action, bool lockStatus) external onlyOwner {
    lock[action] = lockStatus;
    emit LockedAction(action, lockStatus);
  }

  /**
   * @notice Set swap fee configuration
   * @param _swapFeePercentage The swap fee percentage
   * @param _swapFeeCollector The swap fee collector address
   */
  function _setSwapFeeConfig(uint256 _swapFeePercentage, address _swapFeeCollector) internal {
    require(_swapFeePercentage > 0, 'INVALID_SWAP_FEE_PERCENTAGE');
    require(_swapFeeCollector != address(0), 'INVALID_SWAP_FEE_COLLECTOR');
    swapFeeConfig = SwapFeeConfig({swapFeePercentage: _swapFeePercentage, swapFeeCollector: _swapFeeCollector});
    emit SwapFeeConfigAdded(_swapFeePercentage);
  }

  /**
   * @notice Approve spender to spend tokens for specific user action
   * @param token The token address to spend
   */
  function _approve(address spender, address token) internal {
    if (token != NATIVE_TOKEN_ADDRESS) {
      uint256 allowance = IERC20(token).allowance(address(this), spender);
      if (allowance == 0) {
        TransferHelpers.safeApprove(token, spender, type(uint256).max);
      }
    }
  }

  /**
   * @notice Derive the swap fee token
   * @param _fromToken The from token contract address
   * @param _toToken The to token contract address
   * @return feeToken The fee token address
   */
  function _getSwapFeeToken(address _fromToken, address _toToken) internal view returns (address feeToken) {
    bool hasFromToken = feeTokens[_fromToken];
    bool hasToToken = feeTokens[_toToken];

    if (hasFromToken && !hasToToken) {
      feeToken = _fromToken;
    } else if (hasToToken && !hasFromToken) {
      feeToken = _toToken;
    } else if (hasFromToken && hasToToken) {
      feeToken = _fromToken;
    } else {
      feeToken = _fromToken;
    }
  }

  /**
   * @notice Transfers tokens from plug router to recipient
   * @param token The token address which needs to transfer
   * @param recipient The receiver Wallet address
   * @param amount The amount to transfer
   */
  function _transfers(
    address token,
    address recipient,
    uint256 amount
  ) internal {
    if (token == NATIVE_TOKEN_ADDRESS) {
      TransferHelpers.safeTransferETH(recipient, amount);
    } else {
      TransferHelpers.safeTransfer(token, recipient, amount);
    }
  }

  /**
   * @notice Take fee function transfers fee tokens to swap fee collector
   * @param _swapFeeCollector The swap fee collector
   * @param _feeToken The fee token address
   * @param _amount The amount
   * @param _swapFeePercentage The swap fee percentage
   */
  function _takeFee(
    address _swapFeeCollector,
    address _feeToken,
    uint256 _amount,
    uint256 _swapFeePercentage
  ) internal returns (uint256 amount) {
    uint256 feeAmount = (_amount * _swapFeePercentage) / FEE_DENOMINATER;
    amount = _amount - feeAmount;
    _transfers(_feeToken, _swapFeeCollector, feeAmount);
  }

  /**
   * @notice Performing swap
   * @param _fromToken The from token contract address
   * @param _amount The amount to swap
   * @param _exchangeId The exchange Id
   * @param _swapCallData The call data for swap
   * @param _feeFlag The indicator for swap fee
   */
  function _swap(
    address _fromToken,
    uint256 _amount,
    bytes4 _exchangeId,
    bytes calldata _swapCallData,
    bool _feeFlag
  ) internal whenNotPaused returns (address outToken, uint256 swapedAmount) {
    require(_amount > 0, 'INSUFFICIENT_INPUT_AMOUNT');

    pullTokens(_fromToken, address(this), _amount);

    address exchangeRouter = aggregatorsAndBridgesMap[_exchangeId];
    require(exchangeRouter != address(0), 'EXCHANGE_NOT_SUPPORTED');

    // approve
    _approve(exchangeRouter, _fromToken);

    uint256 sClen = _swapCallData.length;
    bytes memory byteAddress = _swapCallData[(sClen - 20):sClen];

    // solhint-disable-next-line
    assembly {
      outToken := mload(add(byteAddress, 20))
    }
    // slice swap call data
    _swapCallData = _swapCallData[:sClen - 20];

    address feeToken = _getSwapFeeToken(_fromToken, outToken);
    address swapFeeCollector = swapFeeConfig.swapFeeCollector;
    // fee calculation
    uint256 swapFeePercentage = swapFeeConfig.swapFeePercentage;

    // check if some one send extra eth
    if (_fromToken == NATIVE_TOKEN_ADDRESS) {
      require(_amount == msg.value, 'INVALID_VALUE');
    }

    if (_feeFlag) {
      if (_fromToken == feeToken) {
        _amount = _takeFee(swapFeeCollector, feeToken, _amount, swapFeePercentage);
      }
    }

    // init swap
    uint256 value = _fromToken == NATIVE_TOKEN_ADDRESS ? _amount : msg.value;
    (bool success, ) = exchangeRouter.call{value: value}(_swapCallData);
    require(success, 'SWAP_FAILED');

    swapedAmount = outToken == NATIVE_TOKEN_ADDRESS ? address(this).balance : IERC20(outToken).balanceOf(address(this));
    require(swapedAmount > 0, 'INSUFFICIENT_OUPUT_AMOUNT');
    // after swap fee calculation
    if (_feeFlag) {
      if (outToken == feeToken) {
        swapedAmount = _takeFee(swapFeeCollector, feeToken, swapedAmount, swapFeePercentage);
      }
    }
  }

  /**
   * @notice Deposit tokens to bridge contract
   * @param recipient The receiver wallet address
   * @param token The token contract address
   * @param bridgeAdapter The bridge Adapter
   * @param amount The amount to bridge
   * @param bridgeCallData The bridge calldata
   */
  function _deposit(
    address recipient,
    address token,
    address bridgeAdapter,
    uint256 amount,
    bytes calldata bridgeCallData
  ) internal whenNotPaused returns (uint256 toChainId) {
    // bridge deposit call
    uint256 value = token == NATIVE_TOKEN_ADDRESS ? msg.value : 0;

    (toChainId) = IBridgeAdapter(bridgeAdapter).deposit{value: value}(amount, recipient, token, bridgeCallData);
  }

  /**
   * @notice Pull ERC20 tokens from user wallet address
   * @dev Also make sure you have provided proper token apporval to plug router
   * @param token The token contract address
   * @param amount The transferable amount
   */
  function pullTokens(
    address token,
    address receiver,
    uint256 amount
  ) internal {
    if (token != NATIVE_TOKEN_ADDRESS) {
      TransferHelpers.safeTransferFrom(token, _msgSender(), receiver, amount);
    }
  }

  /**
   * @notice Log on cross chain swap
   * @param affiliateAddr The affliate wallet address
   * @param fromToken The from token contract address
   * @param toToken The toToken token contract address
   * @param amount The swap input amount
   * @param swapedAmount The swap output amount
   * @param toChainId The destination ChainId
   * @param exchangeId The exchange Id
   * @param bridgeId The bridge Id
   */
  function _logCrossChainSwap(
    address affiliateAddr,
    address fromToken,
    address toToken,
    uint256 amount,
    uint256 swapedAmount,
    uint256 toChainId,
    bytes4 exchangeId,
    bytes4 bridgeId
  ) internal {
    emit CrossChainSwapPerformed(
      affiliateAddr,
      _msgSender(),
      fromToken,
      toToken,
      amount,
      swapedAmount,
      toChainId,
      exchangeId,
      bridgeId
    );
  }

  /** @dev This empty reserved space is put in place to allow future versions to add new
   variables without shifting down storage in the inheritance chain.
   See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
  */
  uint256[49] private __gap;
}