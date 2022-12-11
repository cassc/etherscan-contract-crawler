// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

/**
 * @title IPlugRouterUpgradeable Interface
 * @author Plug
 * @notice performing swap,bridge deposit and crosschain Swap
 */
interface IPlugRouterUpgradeable {
  /**
   * @notice Perform swaps
   * @param affiliateAddr The affliate wallet address
   * @param fromToken The from token contract address
   * @param amount The amount to swap
   * @param exchangeId The exchange Id
   * @param swapCallData The call data for swap
   */
  function swap(
    address affiliateAddr,
    address fromToken,
    uint256 amount,
    bytes4 exchangeId,
    bytes memory swapCallData
  ) external payable;

  /**
   * @notice Perform cross chain swaps
   * @param affiliateAddr The affliate wallet address
   * @param fromToken The From token contract address
   * @param amount The amount to swap
   * @param exchangeId The Whitelisted exchange Id
   * @param bridgeId The Registered bridge Id
   * @param swapCallData The call data for swap action
   * @param bridgeCallData The call data for bridge action
   */
  function crossChainSwap(
    address affiliateAddr,
    address fromToken,
    uint256 amount,
    bytes4 exchangeId,
    bytes4 bridgeId,
    bytes calldata swapCallData,
    bytes calldata bridgeCallData
  ) external payable;

  /**
   * @notice Deposit tokens to bridge contract thorugh bridgeApdater
   * @param affiliateAddr The Affliate wallet address
   * @param token The Token contract address
   * @param amount The amount to bridge
   * @param bridgeId The bridge Id
   * @param bridgeCallData The call data for bridge action
   */
  function deposit(
    address affiliateAddr,
    address token,
    uint256 amount,
    bytes4 bridgeId,
    bytes calldata bridgeCallData
  ) external payable;

  /**
   * @notice Update swap fee config
   * @dev Call by current owner
   * @param _swapFeePercentage The swap fee percentage
   * @param _swapFeeCollector The swap fee collector address
   */
  function updateSwapFeeConfig(uint256 _swapFeePercentage, address _swapFeeCollector) external;

  /**
   * @notice Add specfic fee tokens
   * @dev Call by current owner
   * @param tokens The list of Fee tokens
   * @param flags The list of fee tokens status
   */
  function addFeeTokens(address[] memory tokens, bool[] memory flags) external;

  /**
   * @notice Rescue stuck tokens of plug router
   * @dev Call by current owner
   * @param withdrawableAddress The Address to withdraw this tokens
   * @param tokens The list of tokens
   * @param amounts The list of amounts
   */
  function rescueTokens(
    address withdrawableAddress,
    address[] memory tokens,
    uint256[] memory amounts
  ) external;

  /**
   * @notice Rescue stuck ETH of plug router
   * @dev Call by current owner
   * @param withdrawableAddress The Withdrawable Address
   * @param amount The value to withdraw
   */
  function resuceEth(address withdrawableAddress, uint256 amount) external;

  /**
   * @notice Whitelist aggregators and bridges
   * @dev Call by current owner
   * @param ids The bridges or aggregators ids
   * @param routers Their routers respectively
   */
  function setAggregatorsAndBridgeMap(bytes4[] memory ids, address[] memory routers) external;

  /**
   * @notice Pause Whole contract
   * @dev Call by current owner
   */
  function pause() external;

  /**
   * @notice Unpause Whole contract
   * @dev Call by current owner
   */
  function unpause() external;

  /**
   * @notice Start and Stop Particular User Action
   * @dev call by current owner
   * @param action The action magic value
   * @param lockStatus The lock status
   */
  function startOrStopParticularUserAction(bytes4 action, bool lockStatus) external;

  /**
   * @notice Emits when plug exchange owner sets the fee config
   * @param swapFeePercentage The swap fee percentage
   */
  event SwapFeeConfigAdded(uint256 swapFeePercentage);

  /**
   * @notice Emits when plug exchange owner add the fee tokens
   * @param feeTokens The list of Fee tokens
   * @param flags The list of fee tokens status
   */
  event FeeTokens(address[] feeTokens, bool[] flags);

  /**
   * @notice Emits when plug exchange owner whitelist the supported aggregators &
   * bridges
   * @param ids The bridges or aggregators ids
   * @param routers Their routers respectively
   */
  event SupportedAggregatorsAndBridges(bytes4[] ids, address[] routers);

  /**
   * @notice Emits when plug owner sets the locked for particular plug
   * exchange action
   * @param action The action magic value
   * @param lockStatus The lock status
   */
  event LockedAction(bytes4 action, bool lockStatus);

  /**
   * @notice Emits when plug users do swap with the plug router
   * @param affiliateAddr The affliate wallet address
   * @param user The recipient wallet address
   * @param fromToken The From token contract address
   * @param toToken The toToken token contract address
   * @param amount The Swap Input Amount
   * @param swapedAmount The Swap Output Amount
   * @param exchangeId The Exchange Id
   */
  event SwapPerformed(
    address affiliateAddr,
    address user,
    address fromToken,
    address toToken,
    uint256 amount,
    uint256 swapedAmount,
    bytes4 exchangeId
  );

  /**
   * @notice Emits when plug users do crosschain swap with the plug router
   * @param affiliateAddr The affliate wallet address
   * @param user The recipient wallet address
   * @param fromToken The From token contract address
   * @param toToken The toToken token contract address
   * @param amount The Swap Input Amount
   * @param swapedAmount The Swap Output Amount
   * @param toChainId The Destination ChainId
   * @param exchangeId The Exchange Id
   * @param bridgeId The Bridge Id
   */
  event CrossChainSwapPerformed(
    address affiliateAddr,
    address user,
    address fromToken,
    address toToken,
    uint256 amount,
    uint256 swapedAmount,
    uint256 toChainId,
    bytes4 exchangeId,
    bytes4 bridgeId
  );

  /**
   * @notice Emits when plug users deposit the token with the plug router
   * @param affiliateAddr The affliate wallet address
   * @param recipient The recipient wallet address
   * @param token The Token to bridge
   * @param amount The Swap Input Amount
   * @param toChainId The Destination ChainId
   * @param bridgeId The Bridge Id
   */
  event Deposit(
    address affiliateAddr,
    address recipient,
    address token,
    uint256 amount,
    uint256 toChainId,
    bytes4 bridgeId
  );
}