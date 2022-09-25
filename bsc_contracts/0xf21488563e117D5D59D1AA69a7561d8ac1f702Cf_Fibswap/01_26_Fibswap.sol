// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import "./interfaces/IWrapped.sol";
import "./interfaces/IFibswap.sol";
import "./interfaces/IERC20Extended.sol";

import {IExecutor, Executor} from "./interpreters/Executor.sol";
import {RouterPermissionsManager} from "./RouterPermissionsManager.sol";
import {OwnerPausableUpgradeable} from "./OwnerPausableUpgradeable.sol";

import {FibswapUtils} from "./lib/Fibswap/FibswapUtils.sol";

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract Fibswap is
  UUPSUpgradeable,
  OwnerPausableUpgradeable,
  ReentrancyGuardUpgradeable,
  RouterPermissionsManager,
  IFibswap
{
  // ========== Custom Errors ===========

  error Fibswap__removeAssetId_notAdded();
  error Fibswap__removeLiquidity_recipientEmpty();
  error Fibswap__removeLiquidity_amountIsZero();
  error Fibswap__removeLiquidity_insufficientFunds();
  error Fibswap__xcall_notSupportedAsset();
  error Fibswap__xcall_wrongDomain();
  error Fibswap__xcall_emptyToOrRecovery();
  error Fibswap__xcall_notGasFee();
  error Fibswap__xcall_notApprovedRouter();
  error Fibswap__xcall_invalidSwapRouer();
  error Fibswap__xcall_tooSmallLocalAmount();
  error Fibswap__xcall_tooBigSlippage();
  error Fibswap__execute_unapprovedRouter();
  error Fibswap__execute_invalidRouterSignature();
  error Fibswap__execute_alreadyExecuted();
  error Fibswap__execute_incorrectDestination();
  error Fibswap__addLiquidityForRouter_routerEmpty();
  error Fibswap__addLiquidityForRouter_amountIsZero();
  error Fibswap__addLiquidityForRouter_badRouter();
  error Fibswap__addLiquidityForRouter_badAsset();
  error Fibswap__addAssetId_alreadyAdded();
  error Fibswap__addAssetIds_invalidArgs();
  error Fibswap__decrementLiquidity_notEmpty();
  error Fibswap__addSwapRouter_invalidArgs();
  error Fibswap__addSwapRouter_invalidSwapRouterAddress();
  error Fibswap__addSwapRouter_alreadyApproved();
  error Fibswap__removeSwapRouter_invalidArgs();
  error Fibswap__removeSwapRouter_alreadyRemoved();

  // ============ Constants =============

  bytes32 internal constant EMPTY = hex"c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470";

  /// @dev Normal Service Fee percent
  uint256 public constant PERCENTS_DIVIDER = 10000;

  // ============ Properties ============

  uint256 public chainId;
  uint256 public nonce;
  uint256 public feePercent;

  // max allowed slippage
  uint256 public maxAllowSlippage;

  IWrapped public wrapper;
  IExecutor public executor;

  // swap router address => approved?
  mapping(address => bool) public swapRouters;
  // local assetId => approved?
  mapping(address => bool) public approvedAssets;
  // rotuer address => local assetId => balance
  mapping(address => mapping(address => uint256)) public routerBalances;
  // transferId => processed?
  mapping(bytes32 => bool) public processed;

  // ============ Modifiers ============

  // ========== Initializer ============

  function initialize(
    uint256 _chainId,
    address _owner,
    address _wrapper
  ) public override initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    __RouterPermissionsManager_init();
    __OwnerPausable_init();

    transferOwnership(_owner);

    nonce = 0;
    chainId = _chainId;
    wrapper = IWrapped(_wrapper);

    feePercent = 250; // 2.5%
    maxAllowSlippage = 30; // 0.3%
  }

  function _authorizeUpgrade(address) internal override onlyOwner {}

  // ============ Owner Functions ============
  /**
   * @notice Owner can set  normal fee percent
   * @param _percent normal fee percentage
   **/
  function setFeePercent(uint256 _percent) external onlyOwner {
    require(_percent < PERCENTS_DIVIDER / 5, "too big fee");

    feePercent = _percent;

    // Emit event
    emit NewFeePercent(_percent, msg.sender);
  }

  /**
   * @notice Owner can set max allowed slippage
   * @param _percent percentage
   **/
  function setMaxAllowSlippage(uint256 _percent) external onlyOwner {
    require(_percent < PERCENTS_DIVIDER / 5, "too big");

    maxAllowSlippage = _percent;

    // Emit event
    emit NewMaxAllowSlippage(_percent, msg.sender);
  }

  /**
   * @notice Owner can set  executor
   * @param _executor new executor address
   **/
  function setExecutor(address _executor) external onlyOwner {
    require(AddressUpgradeable.isContract(_executor), "!contract");

    executor = IExecutor(_executor);

    // Emit event
    emit NewExecutor(_executor, msg.sender);
  }

  /**
   * @notice Used to set router initial properties
   * @param router Router address to setup
   * @param owner Initial Owner of router
   * @param recipient Initial Recipient of router
   */
  function setupRouter(
    address router,
    address owner,
    address recipient
  ) external onlyOwner {
    _setupRouter(router, owner, recipient);
  }

  /**
   * @notice Used to remove routers that can transact crosschain
   * @param router Router address to remove
   */
  function removeRouter(address router) external override onlyOwner {
    _removeRouter(router);
  }

  /**
   * @notice set swap routers
   */
  function addSwapRouter(address[] memory routers) external onlyOwner {
    if (routers.length == 0) revert Fibswap__addSwapRouter_invalidArgs();
    for (uint256 i; i < routers.length; ) {
      _addSwapRouter(routers[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice remove swap router
   */
  function removeSwapRouter(address _swapRouter) external onlyOwner {
    if (_swapRouter == address(0)) revert Fibswap__removeSwapRouter_invalidArgs();
    if (!swapRouters[_swapRouter]) revert Fibswap__removeSwapRouter_alreadyRemoved();

    swapRouters[_swapRouter] = false;

    emit SwapRouterUpdated(_swapRouter, false, msg.sender);
  }

  /**
   * @notice Used to add supported assets. This is an admin only function
   * @param localAssets - The assets to add
   */
  function addAssetIds(address[] memory localAssets) external onlyOwner {
    if (localAssets.length == 0) revert Fibswap__addAssetIds_invalidArgs();
    for (uint256 i; i < localAssets.length; ) {
      _addAssetId(localAssets[i]);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Used to remove assets from the whitelist
   * @param localAssetId - Corresponding local asset to remove
   */
  function removeAssetId(address localAssetId) external override onlyOwner {
    // Sanity check: already approval
    if (!approvedAssets[localAssetId]) revert Fibswap__removeAssetId_notAdded();

    // Update mapping
    delete approvedAssets[localAssetId];

    // Emit event
    emit AssetRemoved(localAssetId, msg.sender);
  }

  /**
   * @notice Used to update wapped token address
   * @param _wrapped - Wrapped asset address
   */
  function setWrapped(address _wrapped) external onlyOwner {
    if (!AddressUpgradeable.isContract(_wrapped)) revert();

    wrapper = IWrapped(_wrapped);
  }

  // ============ Public Functions ============

  /**
   * @notice This is used by anyone to increase a router's available liquidity for a given asset.
   * @param amount - The amount of liquidity to add for the router
   * @param local - The address of the asset you're adding liquidity for. If adding liquidity of the
   * native asset, routers may use `address(0)` or the wrapped asset
   * @param router The router you are adding liquidity on behalf of
   */
  function addLiquidityFor(
    uint256 amount,
    address local,
    address router
  ) external payable override nonReentrant whenNotPaused {
    _addLiquidityForRouter(amount, local, router);
  }

  /**
   * @notice This is used by any router to increase their available liquidity for a given asset.
   * @param amount - The amount of liquidity to add for the router
   * @param local - The address of the asset you're adding liquidity for. If adding liquidity of the
   * native asset, routers may use `address(0)` or the wrapped asset
   */
  function addLiquidity(uint256 amount, address local) external payable override nonReentrant whenNotPaused {
    _addLiquidityForRouter(amount, local, msg.sender);
  }

  /**
   * @notice This is used by any router to decrease their available liquidity for a given asset.
   * @param amount - The amount of liquidity to remove for the router
   * @param local - The address of the asset you're removing liquidity from. If removing liquidity of the
   * native asset, routers may use `address(0)` or the wrapped asset
   */
  function removeLiquidity(uint256 amount, address local) external override nonReentrant whenNotPaused {
    // transfer to specicfied recipient IF recipient not set
    address _recipient = routerRecipients(msg.sender);

    // Sanity check: to is sensible
    if (_recipient == address(0)) revert Fibswap__removeLiquidity_recipientEmpty();

    // Sanity check: nonzero amounts
    if (amount == 0) revert Fibswap__removeLiquidity_amountIsZero();

    uint256 routerBalance = routerBalances[msg.sender][local];
    // Sanity check: amount can be deducted for the router
    if (routerBalance < amount) revert Fibswap__removeLiquidity_insufficientFunds();

    // Update router balances
    unchecked {
      routerBalances[msg.sender][local] = routerBalance - amount;
    }

    // Transfer from contract to specified to
    FibswapUtils.transferAssetFromContract(local, _recipient, amount, false, wrapper);

    // Emit event
    emit LiquidityRemoved(msg.sender, _recipient, local, amount, msg.sender);
  }

  /**
   * @notice This function is called by a user who is looking to bridge funds
   * @dev This contract must have approval to transfer the transacting assets. They are then swapped to
   * the local assets via the configured AMM and sent over the bridge router.
   * @param _args - The XCallArgs
   * @return The transfer id of the crosschain transfer
   */
  function xcall(XCallArgs calldata _args) external payable override whenNotPaused returns (bytes32) {
    _xcallSanityChecks(_args);

    // Transfer funds to the contract
    (address _transactingAssetId, uint256 _amount) = FibswapUtils.handleIncomingAsset(
      _args.transactingAssetId,
      _args.amount,
      _args.relayerFee,
      _args.params.router,
      wrapper
    );

    // Swap to the local asset from the adopted
    address localAsset = _args.params.orgLocalAsset;
    if (localAsset != _transactingAssetId) {
      if (!swapRouters[_args.params.orgParam.to]) {
        revert Fibswap__xcall_invalidSwapRouer();
      }

      _amount = FibswapUtils.swapToLocalAssetIfNeeded(localAsset, _transactingAssetId, _amount, _args.params.orgParam);
    }

    // check min Local Amount without Fee
    uint256 localAmount = _args.localAmount;
    uint256 underlyingAmount = _handleIncomingAsset(_amount, localAmount, localAsset);

    // send fee
    FibswapUtils.transferAssetFromContract(
      localAsset,
      routerRecipients(_args.params.router),
      _amount - localAmount,
      true,
      wrapper
    );

    // increase router balance
    routerBalances[_args.params.router][localAsset] += localAmount;

    // Compute the transfer id
    bytes32 _transferId = FibswapUtils.getTransferId(nonce, msg.sender, _args.params, underlyingAmount);

    // Emit event
    emit XCalled(
      _transferId,
      _args.params,
      _transactingAssetId,
      _args.amount,
      localAmount,
      underlyingAmount,
      nonce,
      _args.relayerFee,
      msg.sender
    );

    // Update nonce
    nonce++;

    // Return the transfer id
    return _transferId;
  }

  /**
   * @notice This function is called on the destination chain when the bridged asset should be swapped
   * into the adopted asset and the external call executed. Can be used before reconcile (when providing
   * fast liquidity) or after reconcile (when using liquidity from the bridge)
   * @dev Will store the `ExecutedTransfer` if fast liquidity is provided, or assert the hash of the
   * `ReconciledTransfer` when using bridge liquidity
   * @param _args - The `ExecuteArgs` for the transfer
   * @return bytes32 The transfer id of the crosschain transfer
   */
  function execute(ExecuteArgs calldata _args) external override whenNotPaused returns (bytes32) {
    // Calculate the transfer id
    (bytes32 _transferId, address localAsset, uint256 localAmount) = _executeSanityChecks(_args);

    processed[_transferId] = true;

    // Handle liquidity as needed
    _decrementLiquidity(localAmount, localAsset, _args.params.router);

    address transactingAsset = localAsset;
    if (keccak256(_args.params.dstParam.data) == EMPTY) {
      // Send funds to the user
      transactingAsset = FibswapUtils.transferAssetFromContract(
        localAsset,
        _args.params.dstParam.to,
        localAmount,
        _args.params.isEth,
        wrapper
      );
    } else {
      // Send funds to executor
      transactingAsset = FibswapUtils.transferAssetFromContract(
        localAsset,
        address(executor),
        localAmount,
        _args.params.isEth,
        wrapper
      );
      executor.execute(
        _transferId,
        localAmount,
        payable(_args.params.dstParam.to),
        payable(_args.params.recovery),
        transactingAsset,
        _args.params.dstParam.data
      );
    }

    // Emit event
    emit Executed(
      _transferId,
      _args.params,
      transactingAsset,
      localAmount,
      _args.amount,
      _args.routerSignature,
      _args.originSender,
      _args.nonce,
      msg.sender
    );

    return _transferId;
  }

  // ============ Private functions ============

  /**
   * @notice Contains the logic to verify + increment a given routers liquidity
   * @dev The liquidity will be held in the local asset
   * @param _amount - The amount of liquidity to add for the router
   * @param _local - The address of the local asset
   * @param _router - The router you are adding liquidity on behalf of
   */
  function _addLiquidityForRouter(
    uint256 _amount,
    address _local,
    address _router
  ) internal {
    // Sanity check: router is sensible
    if (_router == address(0)) revert Fibswap__addLiquidityForRouter_routerEmpty();

    // Sanity check: nonzero amounts
    if (_amount == 0) revert Fibswap__addLiquidityForRouter_amountIsZero();

    // Router is approved
    if (!approvedRouters(_router)) revert Fibswap__addLiquidityForRouter_badRouter();

    // Transfer funds to coethWithErcTransferact
    (address _assetId, uint256 _received) = FibswapUtils.handleIncomingAsset(_local, _amount, 0, _router, wrapper);

    // Asset is approved
    if (!approvedAssets[_assetId]) revert Fibswap__addLiquidityForRouter_badAsset();

    // Update the router balances. Happens after pulling funds to account for
    // the fee on transfer tokens
    routerBalances[_router][_assetId] += _received;

    // Emit event
    emit LiquidityAdded(_router, _assetId, _received, msg.sender);
  }

  /**
   * @notice Used to add assets on same chain as contract that can be transferred.
   * @param _localAsset - The used asset id (i.e. USDC, USDT, WETH, ETH)
   */
  function _addAssetId(address _localAsset) internal {
    // Sanity check: needs approval
    if (approvedAssets[_localAsset]) revert Fibswap__addAssetId_alreadyAdded();

    // Update approved assets mapping
    approvedAssets[_localAsset] = true;

    // Emit event
    emit AssetAdded(_localAsset, msg.sender);
  }

  /**
   * @notice Used to add an AMM for assets
   * @param _swapRouter - The address of the amm to add
   */
  function _addSwapRouter(address _swapRouter) internal {
    if (!AddressUpgradeable.isContract(_swapRouter)) revert Fibswap__addSwapRouter_invalidSwapRouterAddress();
    if (swapRouters[_swapRouter]) revert Fibswap__addSwapRouter_alreadyApproved();

    swapRouters[_swapRouter] = true;

    emit SwapRouterUpdated(_swapRouter, true, msg.sender);
  }

  /**
   * @notice Calculates transfer amount without Fee.
   * @param _amount Transfer amount
   * @param _liquidityFeeNum Liquidity fee numerator
   * @param _liquidityFeeDen Liquidity fee denominator
   */
  function _getTransferAmountWithoutFee(
    uint256 _amount,
    uint256 _liquidityFeeNum,
    uint256 _liquidityFeeDen
  ) private pure returns (uint256) {
    return (_amount * _liquidityFeeNum) / _liquidityFeeDen;
  }

  function _handleIncomingAsset(
    uint256 _amount,
    uint256 _localAmount,
    address _localAsset
  ) internal view returns (uint256) {
    uint256 bridgedAmount = _getTransferAmountWithoutFee(_amount, PERCENTS_DIVIDER - feePercent, PERCENTS_DIVIDER);
    if (bridgedAmount < _localAmount) revert Fibswap__xcall_tooSmallLocalAmount();
    if (bridgedAmount >= (_localAmount * (maxAllowSlippage + PERCENTS_DIVIDER)) / PERCENTS_DIVIDER)
      revert Fibswap__xcall_tooBigSlippage();

    // underlying amount = localAmount * 10 ^ (36 - decimal of local asset)
    uint256 decimals = _localAsset == address(0) ? 18 : IERC20Extended(_localAsset).decimals();
    return _localAmount * (10**(36 - decimals));
  }

  /**
   * @notice Decrements router liquidity for the fast-liquidity case.
   * @dev Stores the router that supplied liquidity to credit on reconcile
   */
  function _decrementLiquidity(
    uint256 _amount,
    address _local,
    address _router
  ) internal {
    // Decrement liquidity
    routerBalances[_router][_local] -= _amount;
  }

  /**
   * @notice Performs some sanity checks for `xcall`
   * @dev Need this to prevent stack too deep
   */
  function _xcallSanityChecks(XCallArgs calldata _args) private view {
    if (!approvedRouters(_args.params.router)) revert Fibswap__xcall_notApprovedRouter();

    // ensure this is the right domain
    uint256 _chainId = getChainId();
    if (_args.params.origin != _chainId || _args.params.origin == _args.params.destination) {
      revert Fibswap__xcall_wrongDomain();
    }

    // ensure theres a recipient defined
    if (_args.params.dstParam.to == address(0) || _args.params.recovery == address(0)) {
      revert Fibswap__xcall_emptyToOrRecovery();
    }

    if (!approvedAssets[_args.params.orgLocalAsset]) revert Fibswap__xcall_notSupportedAsset();

    if (_args.relayerFee == 0 || msg.value < _args.relayerFee) revert Fibswap__xcall_notGasFee();
  }

  /**
   * @notice Performs some sanity checks for `execute`
   * @dev Need this to prevent stack too deep
   */
  function _executeSanityChecks(ExecuteArgs calldata _args)
    private
    returns (
      bytes32,
      address,
      uint256
    )
  {
    // If the sender is not approved router, revert()
    if (!approvedRouters(msg.sender) || msg.sender != _args.params.router) {
      revert Fibswap__execute_unapprovedRouter();
    }

    if (_args.params.destination != getChainId()) revert Fibswap__execute_incorrectDestination();
    // get transfer id
    bytes32 transferId = FibswapUtils.getTransferId(_args.nonce, _args.originSender, _args.params, _args.amount);

    // get the payload the router should have signed
    bytes32 routerHash = keccak256(abi.encode(transferId));

    if (_args.params.router != _recoverSignature(routerHash, _args.routerSignature)) {
      revert Fibswap__execute_invalidRouterSignature();
    }

    // require this transfer has not already been executed
    if (processed[transferId]) {
      revert Fibswap__execute_alreadyExecuted();
    }

    address localAsset = _args.params.dstLocalAsset;
    uint256 decimals = (localAsset == address(0) ? 18 : IERC20Extended(localAsset).decimals());
    uint256 localAmount = _args.amount / (10**(36 - decimals));

    return (transferId, localAsset, localAmount);
  }

  /**
   * @notice Holds the logic to recover the signer from an encoded payload.
   * @dev Will hash and convert to an eth signed message.
   * @param _signed The hash that was signed
   * @param _sig The signature you are recovering the signer from
   */
  function _recoverSignature(bytes32 _signed, bytes calldata _sig) internal pure returns (address) {
    // Recover
    return ECDSAUpgradeable.recover(ECDSAUpgradeable.toEthSignedMessageHash(_signed), _sig);
  }

  /**
   * @notice Gets the chainId for this contract. If not specified during init
   *         will use the block.chainId
   */
  function getChainId() public view returns (uint256 _chainId) {
    // Hold in memory to reduce sload calls
    uint256 chain = chainId;
    if (chain == 0) {
      // If not provided, pull from block
      assembly {
        _chainId := chainid()
      }
    } else {
      // Use provided override
      _chainId = chain;
    }
  }

  receive() external payable {}

  /**
   * @dev This empty reserved space is put in place to allow future versions to add new
   * variables without shifting down storage in the inheritance chain.
   * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
   */
  uint256[49] private __gap;
}