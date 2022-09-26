// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

interface IFibswap {
  // ============= Structs =============
  /**
   * @notice Contains the external call information
   * @dev Used to create a hash to pass the external call information through the bridge
   * @param to - The address that should receive the funds on the destination domain if no call is
   * specified, or the fallback if an external call fails
   * @param callData - The data to execute on the receiving chain
   */
  struct ExternalCall {
    address to;
    bytes data;
  }

  /**
   * @notice These are the call parameters that will remain constant between the
   * two chains. They are supplied on `xcall` and should be asserted on `execute`
   * @property to - The account that receives funds, in the event of a crosschain call,
   * will receive funds if the call fails.
   * @param to - The address you are sending funds (and potentially data) to
   * @param callData - The data to execute on the receiving chain. If no crosschain call is needed, then leave empty.
   * @param origin - The originating chainId (i.e. where `xcall` is called).
   * @param destination - The final chainId (i.e. where `execute` is called).
   */
  struct CallParams {
    address router;
    ExternalCall orgParam;
    ExternalCall dstParam;
    address recovery;
    uint32 origin;
    uint32 destination;
    address orgLocalAsset;
    address dstLocalAsset;
    bool isEth;
  }

  /**
   * @notice The arguments you supply to the `xcall` function called by user on origin domain
   * @param params - The CallParams. These are consistent across sending and receiving chains
   * @param transactingAssetId - The asset the caller sent with the transfer. Can be the adopted, canonical,
   * or the representational asset
   * @param amount - The amount of transferring asset the tx called xcall with
   */
  struct XCallArgs {
    CallParams params;
    address transactingAssetId; // Could be any token or native
    uint256 amount;
    uint256 localAmount;
    uint256 relayerFee;
    bool isExactInput;
  }

  /**
   * @notice
   * @param params - The CallParams. These are consistent across sending and receiving chains
   * @param local - The local asset for the transfer, will be swapped to the adopted asset if
   * appropriate
   * @param router - The router who you are sending the funds on behalf of
   * @param amount - The amount of liquidity the router provided or the bridge forwarded, depending on
   * if fast liquidity was used
   * @param feePercentage - The amount over the BASEFEE to tip the relayer
   */
  struct ExecuteArgs {
    CallParams params;
    address transactingAssetId;
    uint256 amount;
    uint256 nonce;
    bytes routerSignature;
    address originSender;
  }
  // ============ Events ============

  event NewExecutor(address executor, address caller);

  event NewFeePercent(uint256 feePercent, address caller);

  event NewMaxAllowSlippage(uint256 percent, address caller);
  /**
   * @notice Emitted when a new swap AMM is added
   * @param swapRouter - The address of the AMM
   * @param approved - approved or removed
   * @param caller - The account that called the function
   */
  event SwapRouterUpdated(address swapRouter, bool approved, address caller);

  /**
   * @notice Emitted when a new asset is added
   * @param localAsset - The address of the local asset (USDC, USDT, WETH)
   * @param caller - The account that called the function
   */
  event AssetAdded(address localAsset, address caller);

  /**
   * @notice Emitted when an asset is removed from whitelists
   * @param localAsset - The address of the local asset (USDC, USDT, WETH)
   * @param caller - The account that called the function
   */
  event AssetRemoved(address localAsset, address caller);

  /**
   * @notice Emitted when a router withdraws liquidity from the contract
   * @param router - The router you are removing liquidity from
   * @param to - The address the funds were withdrawn to
   * @param local - The address of the token withdrawn
   * @param amount - The amount of liquidity withdrawn
   * @param caller - The account that called the function
   */
  event LiquidityRemoved(address indexed router, address to, address local, uint256 amount, address caller);

  /**
   * @notice Emitted when a router adds liquidity to the contract
   * @param router - The address of the router the funds were credited to
   * @param local - The address of the token added (all liquidity held in local asset)
   * @param amount - The amount of liquidity added
   * @param caller - The account that called the function
   */
  event LiquidityAdded(address indexed router, address local, uint256 amount, address caller);

  /**
   * @notice Emitted when `xcall` is called on the origin domain
   * @param transferId - The unique identifier of the crosschain transfer
   * @param params - The CallParams provided to the function
   * @param transactingAsset - The asset the caller sent with the transfer. Can be the adopted, canonical,
   * or the representational asset
   * @param transactingAmount - The amount of transferring asset the tx xcalled with
   * @param localAmount - The amount sent over the bridge
   * @param underlyingAmount - The amount sent over the bridge (initialAmount with slippage) // underlying amount = localAmount * 10 ** (36 - decimals)
   * @param nonce - The nonce of the origin domain contract. Used to create the unique identifier
   * for the transfer
   * @param caller - The account that called the function
   */
  event XCalled(
    bytes32 indexed transferId,
    CallParams params,
    address transactingAsset,
    uint256 transactingAmount,
    uint256 localAmount,
    uint256 underlyingAmount,
    uint256 nonce,
    uint256 relayerFee,
    address caller
  );

  /**
   * @notice Emitted when `execute` is called on the destination chain
   * @dev `execute` may be called when providing fast liquidity *or* when processing a reconciled transfer
   * @param transferId - The unique identifier of the crosschain transfer
   * @param params - The CallParams provided to the function
   * @param transactingAsset - The asset the to gets or the external call is executed with. Should be the
   * adopted asset on that chain.
   * @param localAmount - The amount that was provided by the bridge
   * @param transactingAmount - The amount of transferring asset the to address receives or the external call is
   * executed with
   * @param caller - The account that called the function
   */
  event Executed(
    bytes32 indexed transferId,
    CallParams params,
    address transactingAsset,
    uint256 localAmount,
    uint256 transactingAmount,
    bytes routerSignature,
    address originSender,
    uint256 nonce,
    address caller
  );

  // ============ Admin Functions ============

  function initialize(
    uint256 chainId,
    address owner,
    address wrapper
  ) external;

  function setupRouter(
    address router,
    address owner,
    address recipient
  ) external;

  function removeRouter(address router) external;

  function removeAssetId(address localAsset) external;

  // ============ Public Functions ===========

  function addLiquidityFor(
    uint256 amount,
    address local,
    address router
  ) external payable;

  function addLiquidity(uint256 amount, address local) external payable;

  function removeLiquidity(uint256 amount, address local) external;

  function xcall(XCallArgs calldata _args) external payable returns (bytes32);

  function execute(ExecuteArgs calldata _args) external returns (bytes32);
}