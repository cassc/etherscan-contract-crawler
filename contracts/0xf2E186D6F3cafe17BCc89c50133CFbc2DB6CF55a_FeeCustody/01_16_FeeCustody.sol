// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IFeeDistributor.sol";
import "../interfaces/IChainlink.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IWSTETH.sol";
import "../interfaces/ICRV.sol";
import "../interfaces/IYVUSDC.sol";
import "../interfaces/ISwapRouter.sol";

import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

/** @title FeeCustody
    @notice Custody Contract for Ribbon Vault Management / Performance Fees
 */

contract FeeCustody is Ownable {
  using SafeERC20 for IERC20;

  address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
  address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
  address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address public yvUSDC = 0xa354F35829Ae975e850e23e9615b11Da1B3dC4DE;

  // WETH Distribution Token
  IERC20 public distributionToken = IERC20(WETH);
  // Protocol revenue recipient
  address public protocolRevenueRecipient;
  // Address of fee distributor contract for RBN lockers to claim
  IFeeDistributor public feeDistributor;

  // % allocation (0 - 100%) from protocol revenue to allocate to RBN lockers.
  // 2 decimals. ex: 10% = 1000
  uint256 public pctAllocationForRBNLockers;

  uint256 public constant TOTAL_PCT = 10000; // Equals 100%
  ISwapRouter public constant UNIV3_SWAP_ROUTER =
    ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
  ICRV public constant STETH_ETH_CRV_POOL =
    ICRV(0xDC24316b9AE028F1497c275EB9192a3Ea0f67022);

  // Intermediary path asset for univ3 swaps.
  // Empty if direct pool swap between asset and distribution asset
  mapping(address => bytes) public intermediaryPath;

  // Oracle between asset/usd pair for total
  // reward approximation across all assets earned
  mapping(address => address) public oracles;

  address[] public assets;

  // Keeper for weekly distributions
  address public keeper;

  // Events
  event NewAsset(address asset, bytes intermediaryPath);
  event RecoveredAsset(address asset);
  event NewFeeDistributor(address feeDistributor);
  event NewYVUSDC(address yvUSDC);
  event NewRBNLockerAllocation(uint256 pctAllocationForRBNLockers);
  event NewDistributionToken(address distributionToken);
  event NewProtocolRevenueRecipient(address protocolRevenueRecipient);
  event NewKeeper(address keeper);

  /**
   * @notice
   * Constructor
   * @param _pctAllocationForRBNLockers percent allocated for RBN lockers (100% = 10000)
   * @param _feeDistributor address of fee distributor where protocol revenue claimable
   * @param _protocolRevenueRecipient address of multisig
   * @param _admin admin
   * @param _keeper keeper
   */
  constructor(
    uint256 _pctAllocationForRBNLockers,
    address _feeDistributor,
    address _protocolRevenueRecipient,
    address _admin,
    address _keeper
  ) {
    require(_feeDistributor != address(0), "!_feeDistributor");
    require(
      _protocolRevenueRecipient != address(0),
      "!_protocolRevenueRecipient"
    );
    require(_admin != address(0), "!_admin");
    require(_keeper != address(0), "!_keeper");

    pctAllocationForRBNLockers = _pctAllocationForRBNLockers;
    feeDistributor = IFeeDistributor(_feeDistributor);
    protocolRevenueRecipient = _protocolRevenueRecipient;
    keeper = _keeper;
  }

  receive() external payable {}

  /**
   * @notice
   * Swaps RBN locker allocation of protocol revenu to distributionToken,
   * sends the rest to the multisig
   * @dev Can be called by keeper
   * @param _minAmountOut min amount out for every asset type swap.
   * will need to be in order of assets in assets[] array. should be
   * fine if we keep track.
   * @return toDistribute amount of distributionToken distributed to fee distributor
   */
  function distributeProtocolRevenue(uint256[] calldata _minAmountOut)
    external
    returns (uint256 toDistribute)
  {
    require(msg.sender == keeper, "!keeper");

    if (address(distributionToken) == WETH) {
      IWETH(address(distributionToken)).deposit{value: address(this).balance}();
    }

    uint256 len = assets.length;
    for (uint256 i; i < len; i++) {
      IERC20 asset = IERC20(assets[i]);
      uint256 assetBalance = asset.balanceOf(address(this));

      if (assetBalance == 0) {
        continue;
      }

      uint256 multiSigRevenue = (assetBalance *
        (TOTAL_PCT - pctAllocationForRBNLockers)) / TOTAL_PCT;

      // If we are holding the distributionToken itself,
      // do not swap
      if (address(asset) != address(distributionToken)) {
        // Calculate RBN allocation amount to swap for distributionToken
        uint256 amountIn = assetBalance - multiSigRevenue;
        _swap(address(asset), amountIn, _minAmountOut[i]);
      }

      // Transfer multisig allocation of protocol revenue to multisig
      asset.safeTransfer(protocolRevenueRecipient, multiSigRevenue);
    }

    toDistribute = distributionToken.balanceOf(address(this));
    distributionToken.safeApprove(address(feeDistributor), toDistribute);

    // Tranfer RBN locker allocation of protocol revenue to fee distributor
    feeDistributor.burn(address(distributionToken), toDistribute);
  }

  /**
   * @notice
   * Amount of _asset allocated to RBN lockers from current balance
   * @return amount allocated to RBN lockers
   */
  function claimableByRBNLockersOfAsset(address _asset)
    external
    view
    returns (uint256)
  {
    uint256 allocPCT = pctAllocationForRBNLockers;
    uint256 balance = _asset == address(0)
      ? address(this).balance
      : IERC20(_asset).balanceOf(address(this));
    return (balance * allocPCT) / TOTAL_PCT;
  }

  /**
   * @notice
   * Amount of _asset allocated to multisig from current balance
   * @return amount allocated to multisig
   */
  function claimableByProtocolOfAsset(address _asset)
    external
    view
    returns (uint256)
  {
    uint256 allocPCT = TOTAL_PCT - pctAllocationForRBNLockers;
    uint256 balance = _asset == address(0)
      ? address(this).balance
      : IERC20(_asset).balanceOf(address(this));
    return (balance * allocPCT) / TOTAL_PCT;
  }

  /**
   * @notice
   * Total allocated to RBN lockers across all assets balances
   * @return total allocated (in USD)
   */
  function totalClaimableByRBNLockersInUSD() external view returns (uint256) {
    uint256 allocPCT = pctAllocationForRBNLockers;
    return _getTotalAssetValue(allocPCT);
  }

  /**
   * @notice
   * Total allocated to multisig across all assets balances
   * @return total allocated (in USD)
   */
  function totalClaimableByProtocolInUSD() external view returns (uint256) {
    uint256 allocPCT = TOTAL_PCT - pctAllocationForRBNLockers;
    return _getTotalAssetValue(allocPCT);
  }

  /**
   * @notice
   * Total claimable across all asset balances based on allocation PCT
   * @param _allocPCT allocation percentage
   * @return claimable total claimable (in USD)
   */
  function _getTotalAssetValue(uint256 _allocPCT)
    internal
    view
    returns (uint256 claimable)
  {
    uint256 len = assets.length;
    for (uint256 i; i < len; i++) {
      IChainlink oracle = IChainlink(oracles[assets[i]]);

      ERC20 asset = ERC20(assets[i]);

      uint256 bal = asset.balanceOf(address(this));

      if (assets[i] == WSTETH) {
        bal = IWSTETH(assets[i]).getStETHByWstETH(bal);
      } else if (assets[i] == yvUSDC) {
        bal = (bal * IYVUSDC(assets[i]).pricePerShare()) / 10**6;
      }

      uint256 balance = bal * (10**(18 - asset.decimals()));

      if (assets[i] == WETH) {
        balance += address(this).balance;
      }

      // Approximate claimable by multiplying
      // current asset balance with current asset price in USD
      claimable +=
        (balance * uint256(oracle.latestAnswer()) * _allocPCT) /
        10**8 /
        TOTAL_PCT;
    }
  }

  /**
   * @notice
   * Swaps _amountIn of _asset into distributionToken
   * @param _asset asset to swap from
   * @param _amountIn amount to swap of asset
   * @param _minAmountOut min amount out for every asset type swap
   */
  function _swap(
    address _asset,
    uint256 _amountIn,
    uint256 _minAmountOut
  ) internal {
    if (_asset == WSTETH) {
      uint256 _stethAmountIn = IWSTETH(_asset).unwrap(_amountIn);
      TransferHelper.safeApprove(
        STETH,
        address(STETH_ETH_CRV_POOL),
        _stethAmountIn
      );

      STETH_ETH_CRV_POOL.exchange(1, 0, _stethAmountIn, _minAmountOut);

      IWETH(address(distributionToken)).deposit{value: address(this).balance}();
      return;
    }

    if (_asset == yvUSDC) {
      TransferHelper.safeApprove(_asset, yvUSDC, _amountIn);
      _amountIn = IYVUSDC(yvUSDC).withdraw(_amountIn);
    }

    TransferHelper.safeApprove(
      _asset != yvUSDC ? _asset : USDC,
      address(UNIV3_SWAP_ROUTER),
      _amountIn
    );

    ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
      path: intermediaryPath[_asset],
      recipient: address(this),
      amountIn: _amountIn,
      amountOutMinimum: _minAmountOut
    });

    // Executes the swap.
    UNIV3_SWAP_ROUTER.exactInput(params);
  }

  /**
     * @notice
     * add asset
     * @dev Can be called by admin
     * @param _asset new asset
     * @param _oracle ASSET/USD ORACLE.
     * @param _intermediaryPath path for univ3 swap.
     * @param _poolFees fees for asset / distributionToken.

     * If intermediary path then pool fee between both pairs
     * (ex: AAVE / ETH , ETH / USDC)
     * NOTE: if intermediaryPath empty then single hop swap
     * NOTE: MUST BE ASSET / USD ORACLE
     * NOTE: 3000 = 0.3% fee for pool fees
     */
  function setAsset(
    address _asset,
    address _oracle,
    address[] calldata _intermediaryPath,
    uint24[] calldata _poolFees
  ) external onlyOwner {
    require(_asset != address(0), "!_asset");
    uint256 _pathLen = _intermediaryPath.length;
    uint256 _swapFeeLen = _poolFees.length;

    // We must be setting new valid oracle, or want to keep as is if one exists
    require(IChainlink(_oracle).decimals() == 8, "!ASSET/USD");
    require(_pathLen < 2, "invalid intermediary path");
    require(_swapFeeLen == _pathLen + 1, "invalid pool fees array length");

    // If not set asset
    if (oracles[_asset] == address(0)) {
      assets.push(_asset);
    }

    // Set oracle for asset
    oracles[_asset] = _oracle;

    // Multiple pool swaps are encoded through bytes called a `path`.
    // A path is a sequence of token addresses and poolFees that define the pools used in the swaps.
    // The format for pool encoding is (tokenIn, fee, tokenOut/tokenIn, fee, tokenOut)
    // where tokenIn/tokenOut parameter is the shared token across the pools.
    if (_pathLen > 0) {
      intermediaryPath[_asset] = abi.encodePacked(
        _asset != yvUSDC ? _asset : USDC,
        _poolFees[0],
        _intermediaryPath[0],
        _poolFees[1],
        address(distributionToken)
      );
    } else {
      intermediaryPath[_asset] = abi.encodePacked(
        _asset != yvUSDC ? _asset : USDC,
        _poolFees[0],
        address(distributionToken)
      );
    }

    emit NewAsset(_asset, intermediaryPath[_asset]);
  }

  /**
   * @notice
   * recover all assets
   * @dev Can be called by admin
   */
  function recoverAllAssets() external onlyOwner {
    // For all added assets, send to protocol revenue recipient
    uint256 len = assets.length;
    for (uint256 i = 0; i < len; i++) {
      _recoverAsset(assets[i]);
    }
  }

  /**
   * @notice
   * recover specific asset
   * @dev Can be called by admin
   * @param _asset asset to recover
   */
  function recoverAsset(address _asset) external onlyOwner {
    require(_asset != address(0), "!asset");
    _recoverAsset(_asset);
  }

  /**
   * @notice
   * recovers asset logic
   * @param _asset asset to recover
   */
  function _recoverAsset(address _asset) internal {
    IERC20 asset = IERC20(_asset);
    uint256 bal = asset.balanceOf(address(this));
    if (bal > 0) {
      asset.safeTransfer(protocolRevenueRecipient, bal);
      emit RecoveredAsset(_asset);
    }

    // Recover ETH as well
    if (_asset == WETH) {
      uint256 ethBal = address(this).balance;
      if (ethBal > 0) {
        payable(protocolRevenueRecipient).transfer(ethBal);
      }
    }
  }

  /**
   * @notice
   * set fee distributor
   * @dev Can be called by admin
   * @param _feeDistributor new fee distributor
   */
  function setFeeDistributor(address _feeDistributor) external onlyOwner {
    require(_feeDistributor != address(0), "!_feeDistributor");
    feeDistributor = IFeeDistributor(_feeDistributor);
    emit NewFeeDistributor(_feeDistributor);
  }

  /**
   * @notice
   * set yvusdc
   * @dev Can be called by admin
   * @param _yvUSDC new yvusdc address for new version
   */
  function setYVUSDC(address _yvUSDC) external onlyOwner {
    require(_yvUSDC != address(0), "!_yvUSDC");
    yvUSDC = _yvUSDC;
    emit NewYVUSDC(_yvUSDC);
  }

  /**
   * @notice
   * set rbn locker allocation pct
   * @dev Can be called by admin
   * @param _pctAllocationForRBNLockers new allocation for rbn lockers
   */
  function setRBNLockerAllocPCT(uint256 _pctAllocationForRBNLockers)
    external
    onlyOwner
  {
    require(
      _pctAllocationForRBNLockers <= TOTAL_PCT,
      "!_pctAllocationForRBNLockers"
    );
    pctAllocationForRBNLockers = _pctAllocationForRBNLockers;
    emit NewRBNLockerAllocation(_pctAllocationForRBNLockers);
  }

  /**
   * @notice
   * set new distribution asset
   * @dev Can be called by admin
   * @param _distributionToken new distribution token
   */
  function setDistributionToken(address _distributionToken) external onlyOwner {
    require(_distributionToken != address(0), "!_distributionToken");
    distributionToken = IERC20(_distributionToken);
    emit NewDistributionToken(_distributionToken);
  }

  /**
   * @notice
   * set protocol revenue recipient
   * @dev Can be called by admin
   * @param _protocolRevenueRecipient new protocol revenue recipient
   */
  function setProtocolRevenueRecipient(address _protocolRevenueRecipient)
    external
    onlyOwner
  {
    require(
      _protocolRevenueRecipient != address(0),
      "!_protocolRevenueRecipient"
    );
    protocolRevenueRecipient = _protocolRevenueRecipient;
    emit NewProtocolRevenueRecipient(_protocolRevenueRecipient);
  }

  /**
   * @notice
   * set keeper for weekly distributions
   * @dev Can be called by admin
   * @param _keeper new keeper
   */
  function setKeeper(address _keeper) external onlyOwner {
    require(_keeper != address(0), "!_keeper");
    keeper = _keeper;
    emit NewKeeper(_keeper);
  }
}