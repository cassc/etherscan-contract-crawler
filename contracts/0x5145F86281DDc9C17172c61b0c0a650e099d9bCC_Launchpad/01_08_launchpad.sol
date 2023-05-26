// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./interfaces/IWETH.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IRewards.sol";
import "./libraries/TransferHelper.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

interface IAsset {
  // solhint-disable-previous-line no-empty-blocks
}

enum SwapKind { GIVEN_IN, GIVEN_OUT }

struct SingleSwap {
  bytes32 poolId;
  SwapKind kind;
  IAsset assetIn;
  IAsset assetOut;
  uint256 amount;
  bytes userData;
}

struct FundManagement {
  address sender;
  bool fromInternalBalance;
  address payable recipient;
  bool toInternalBalance;
}

interface LBPFactory {
  function create(
    string memory name,
    string memory symbol,
    address[] memory tokens,
    uint256[] memory weights,
    uint256 swapFeePercentage,
    address owner,
    bool swapEnabledOnStart
  ) external returns (address);
}

interface Vault {
  struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  struct ExitPoolRequest {
    address[] assets;
    uint256[] minAmountsOut;
    bytes userData;
    bool toInternalBalance;
  }

  function joinPool(
    bytes32 poolId,
    address sender,
    address recipient,
    JoinPoolRequest memory request
  ) external;

  function exitPool(
    bytes32 poolId,
    address sender,
    address recipient,
    ExitPoolRequest memory request
  ) external;

  function getPoolTokens(bytes32 poolId)
  external
  view
  returns (
    address[] memory tokens,
    uint256[] memory balances,
    uint256 lastChangeBlock
  );

  function swap(
    SingleSwap memory singleSwap,
    FundManagement memory funds,
    uint256 limit,
    uint256 deadline
  )
  external
  payable
  returns (uint256 amountCalculated);
}

interface LBP {
  function updateWeightsGradually(
    uint256 startTime,
    uint256 endTime,
    uint256[] memory endWeights
  ) external;

  function setSwapEnabled(bool swapEnabled) external;

  function getPoolId() external returns (bytes32 poolID);
}

/// @title Launchpad
/// @notice This contract allows for simplified creation and management of Balancer LBPs
/// It currently supports:
/// - LBPs with 2 tokens
/// - Withdrawl of the full liquidity at once
/// - Distributing fees to single and double sided staking contracts
contract Launchpad is Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  struct PoolData {
    address owner;
    bool isCorrectOrder;
    uint256 fundTokenInputAmount;
    string ipfsDetails;
  }

  mapping(address => PoolData) private _poolData;
  EnumerableSet.AddressSet private _pools;
  mapping(address => uint256) private _feeRecipientsBPS;

  IWETH public WETH;

  address public constant VAULT = address(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
  uint256 private constant _TEN_THOUSAND_BPS = 10_000;
  address public immutable LBPFactoryAddress;
  uint256 public immutable platformAccessFeeBPS;
  address public immutable lpStakingAddress;
  address public immutable stakingAddress;

  constructor(
    uint256 _platformAccessFeeBPS,
    address _LBPFactoryAddress,
    address _stakingAddress,
    address _lpStakingAddress,
    address _wethAddress
  ) {
    stakingAddress = _stakingAddress;
    lpStakingAddress = _lpStakingAddress;
    LBPFactoryAddress = _LBPFactoryAddress;
    platformAccessFeeBPS = _platformAccessFeeBPS;

    _feeRecipientsBPS[owner()] = _TEN_THOUSAND_BPS;
    WETH = IWETH(_wethAddress);
  }

  // Events
  event PoolCreated(
    address indexed pool,
    bytes32 poolId,
    string  name,
    string  symbol,
    address[]  tokens,
    uint256[]  weights,
    uint256 swapFeePercentage,
    address owner,
    bool swapEnabledOnStart
  );

  event JoinedPool(address indexed pool, address[] tokens, uint256[] amounts, bytes userData);

  event GradualWeightUpdateScheduled(address indexed pool, uint256 startTime, uint256 endTime, uint256[] endWeights);

  event SwapEnabledSet(address indexed pool, bool swapEnabled);

  event IpfsUpdated(address indexed pool, string hash);

  event TransferredPoolOwnership(address indexed pool, address previousOwner, address newOwner);

  event TransferredFee(address indexed pool, address token, address feeRecipient, uint256 feeAmount);

  event TransferredToken(address indexed pool, address token, address to, uint256 amount);

  event RecipientsUpdated(address[] recipients, uint256[] recipientShareBPS);

  event Skimmed(address token, address to, uint256 balance);

  // Pool access control
  modifier onlyPoolOwner(address pool) {
    require(msg.sender == _poolData[pool].owner, "!owner");
    _;
  }

  /**
  * @dev Checks if the pool address was created in this smart contract
  */
  function isPool(address pool) external view returns (bool valid) {
    return _pools.contains(pool);
  }

  /**
  * @dev Returns the total amount of pools created in the contract
  */
  function poolCount() external view returns (uint256 count) {
    return _pools.length();
  }

  /**
  * @dev Returns a pool for a specific index
  */
  function getPoolAt(uint256 index) external view returns (address pool) {
    return _pools.at(index);
  }

  /**
  * @dev Returns all the pool values
  */
  function getPools() external view returns (address[] memory pools) {
    return _pools.values();
  }

  /**
  * @dev Returns the pool's data saved during creation
  */
  function getPoolData(address pool) external view returns (PoolData memory poolData) {
    return _poolData[pool];
  }

  /**
  * @dev Returns the total amount of LBP Tokens for a pool. These tokens are burned when exit
  */
  function getBPTTokenBalance(address pool) external view returns (uint256 bptBalance) {
    return IERC20(pool).balanceOf(address(this));
  }

  struct PoolConfig {
    string name;
    string symbol;
    address[] tokens;
    uint256[] amounts;
    uint256[] weights;
    uint256[] endWeights;
    bool isCorrectOrder;
    uint256 swapFeePercentage;
    uint256 startTime;
    uint256 endTime;
    string ipfsDetails;
  }

  function fundTokens() public view returns (address[] memory) {
    return IRewards(stakingAddress).getRewardTokens();
  }

  function getFundTokensAndSymbols() public view returns (string[] memory, address[] memory) {
    address[] memory addresses = fundTokens();
    string[] memory symbols = new string[](addresses.length);

    for (uint16 i=0; i < addresses.length; i++)
      symbols[i] = IERC20(addresses[i]).symbol();

    return (symbols, addresses);
  }

  /**
  * @dev Creates a pool and return the contract address of the new pool
  */
  function createLBP(PoolConfig memory poolConfig) external payable returns (address) {
    // 1: deposit tokens and approve vault
    require(poolConfig.tokens.length == 2, "F9 LBPs must have exactly two tokens");
    require(poolConfig.tokens[0] != poolConfig.tokens[1], "LBP tokens must be unique");
    require(poolConfig.startTime > block.timestamp, "LBP start time must be in the future");
    require(poolConfig.endTime > poolConfig.startTime, "LBP end time must be greater than start time");

    uint8 fundTokenIndex = poolConfig.isCorrectOrder ? 0 : 1;
    uint8 mainTokenIndex = poolConfig.isCorrectOrder ? 1 : 0;

    TransferHelper.safeTransferFrom(poolConfig.tokens[mainTokenIndex], msg.sender, address(this), poolConfig.amounts[mainTokenIndex]);

    if (poolConfig.tokens[fundTokenIndex] == address(0)) {
      require(poolConfig.amounts[fundTokenIndex] == msg.value, "Incorrect fund token amount");
      poolConfig.tokens[fundTokenIndex] = address(WETH);
      WETH.deposit{value: msg.value}();
    } else {
      bool isValidFundToken = false;
      address[] memory _fundTokens = fundTokens();
      for (uint i=0; i < _fundTokens.length; i++)
        if (poolConfig.tokens[fundTokenIndex] == _fundTokens[i]) {
          isValidFundToken = true;
          break;
        }

      require(isValidFundToken, "fund token not approved");
      TransferHelper.safeTransferFrom(poolConfig.tokens[fundTokenIndex], msg.sender, address(this), poolConfig.amounts[fundTokenIndex]);
    }


    TransferHelper.safeApprove(poolConfig.tokens[0], VAULT, poolConfig.amounts[0]);
    TransferHelper.safeApprove(poolConfig.tokens[1], VAULT, poolConfig.amounts[1]);

    // 2: pool creation
    address pool = LBPFactory(LBPFactoryAddress).create(
      poolConfig.name,
      poolConfig.symbol,
      poolConfig.tokens,
      poolConfig.weights,
      poolConfig.swapFeePercentage,
      address(this), // owner set to this proxy
      false // swaps disabled on start
    );

    bytes32 poolId = LBP(pool).getPoolId();
    emit PoolCreated(
      pool,
      poolId,
      poolConfig.name,
      poolConfig.symbol,
      poolConfig.tokens,
      poolConfig.weights,
      poolConfig.swapFeePercentage,
      address(this),
      false    
    );

    // 3: store pool data
    _poolData[pool] = PoolData(
      msg.sender,
      poolConfig.isCorrectOrder,
      poolConfig.amounts[poolConfig.isCorrectOrder ? 0 : 1],
      poolConfig.ipfsDetails
    );
    require(_pools.add(pool), "exists already");

    bytes memory userData = abi.encode(0, poolConfig.amounts); // JOIN_KIND_INIT = 0
    // 4: deposit tokens into pool
    Vault(VAULT).joinPool(
      poolId,
      address(this), // sender
      address(this), // recipient
      Vault.JoinPoolRequest(
        poolConfig.tokens,
        poolConfig.amounts,
        userData,
        false)
    );
    emit JoinedPool(pool, poolConfig.tokens, poolConfig.amounts, userData);

    // 5: configure weights
    LBP(pool).updateWeightsGradually(poolConfig.startTime, poolConfig.endTime, poolConfig.endWeights);
    emit GradualWeightUpdateScheduled(pool, poolConfig.startTime, poolConfig.endTime, poolConfig.endWeights);

    return pool;
  }

  /**
  * @dev Enable or disables swaps.
  * Note: LBPs are created with trading disabled by default.
    */
  function setSwapEnabled(address pool, bool swapEnabled) external onlyPoolOwner(pool) {
    LBP(pool).setSwapEnabled(swapEnabled);
    emit SwapEnabledSet(pool, swapEnabled);
  }

  /**
  * @dev Enable or disables swaps.
  * Note: LBPs are created with trading disabled by default.
    */
  function updateIPFSDetails(address pool, string memory hash) external onlyPoolOwner(pool) {
    _poolData[pool].ipfsDetails = hash;
    emit IpfsUpdated(pool, hash);
  }

  /**
  * @dev Transfer ownership of the pool to a new owner
  */
  function transferPoolOwnership(address pool, address newOwner) external onlyPoolOwner(pool) {

    address previousOwner = _poolData[pool].owner;
    _poolData[pool].owner = newOwner;
    emit TransferredPoolOwnership(pool, previousOwner, newOwner);
  }

  enum ExitKind {
    EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
    EXACT_BPT_IN_FOR_TOKENS_OUT,
    BPT_IN_FOR_EXACT_TOKENS_OUT
  }

  /**
  * @dev calculate the amount of BPToken to burn.
  * - if maxBPTTokenOut is 0, everything will be burned
    * - else it will burn only the amount passed
      */
  function _calcBPTokenToBurn(address pool, uint256 maxBPTTokenOut) internal view returns(uint256) {
    uint256 bptBalance = IERC20(pool).balanceOf(address(this));
    require(maxBPTTokenOut <= bptBalance, "Specifed BPT out amount out exceeds owner balance");
    require(bptBalance > 0, "Pool owner BPT balance is less than zero");
    return maxBPTTokenOut == 0 ? bptBalance : maxBPTTokenOut;
  }

  /**
  * @dev Exit a pool, burn the BPT token and transfer back the tokens.
  * - If maxBPTTokenOut is passed as 0, the function will use the total balance available for the BPT token.
      * - If maxBPTTokenOut is between 0 and the total of BPT available, that will be the amount used to burn.
        * maxBPTTokenOut must be greater than or equal to 0
  * as false, and the fee will stay in the contract and later on distributed manualy to mitigate errors
  */
  function exitPool(address pool, uint256 maxBPTTokenOut) external onlyPoolOwner(pool) {
    uint256[]  memory minAmountsOut = new uint256[](2);
    minAmountsOut[0] = uint256(0);
    minAmountsOut[1] = uint256(0);

    // 1. Get pool data
    bytes32 poolId = LBP(pool).getPoolId();
    (address[] memory poolTokens, uint256[] memory balances, ) = Vault(VAULT).getPoolTokens(poolId);
    require(poolTokens.length == minAmountsOut.length, "invalid input length");
    PoolData memory poolData = _poolData[pool];

    // 2. Specify the exact BPT amount to burn
    uint256 bptToBurn = _calcBPTokenToBurn(pool, maxBPTTokenOut);

    // 3. Exit pool and keep tokens in contract
    Vault(VAULT).exitPool(
      poolId,
      address(this),
      payable(address(this)),
      Vault.ExitPoolRequest(
        poolTokens,
        minAmountsOut, 
        abi.encode(ExitKind.EXACT_BPT_IN_FOR_TOKENS_OUT, bptToBurn),
        false
      ) 
    );

    // 4. Get the amount of Fund token from the pool that was left behind after exit (dust)
    ( ,uint256[] memory balancesAfterExit, ) = Vault(VAULT).getPoolTokens(poolId);
    uint256 fundTokenIndex = poolData.isCorrectOrder ? 0 : 1;

    // 5. Distribute tokens and fees
    _distributeTokens(
      pool,
      poolTokens,
      poolData,
      balances[fundTokenIndex] - balancesAfterExit[fundTokenIndex]
    );
  }

  /**
  * @dev Distributes the tokens to the owner and the fee to the fee recipients
  */
  function _distributeTokens(
    address pool,
    address[] memory poolTokens,
    PoolData memory poolData,
    uint256 fundTokenFromPool) internal {

      address mainToken = poolTokens[poolData.isCorrectOrder ? 1 : 0];
      address fundToken = poolTokens[poolData.isCorrectOrder ? 0 : 1];
      uint256 mainTokenBalance = IERC20(mainToken).balanceOf(address(this));
      uint256 remainingFundBalance = fundTokenFromPool;

      // if the amount of fund token increased during the LBP
      if (fundTokenFromPool > poolData.fundTokenInputAmount) { 
        uint256 totalPlatformAccessFeeAmount = ((fundTokenFromPool - poolData.fundTokenInputAmount) * platformAccessFeeBPS) / _TEN_THOUSAND_BPS;
        // Fund amount after substracting the fee
        remainingFundBalance = fundTokenFromPool - totalPlatformAccessFeeAmount;

        _distributePlatformAccessFee(pool, fundToken, totalPlatformAccessFeeAmount);
      }

      // Transfer the balance of the main token
      _transferTokenToPoolOwner(pool, mainToken, mainTokenBalance);
      // Transfer the balanace of fund token excluding the platform access fee
      _transferTokenToPoolOwner(pool, fundToken, remainingFundBalance);
    }

    /**
    * @dev Transfer token to pool owner
    */
    function _transferTokenToPoolOwner(address pool, address token, uint256 amount) private {
      TransferHelper.safeTransfer(
        token,
        msg.sender,
        amount
      );
      emit TransferredToken(pool, token, msg.sender, amount);
    }

    /**
    * @dev Distribute fee between recipients
    */
    function _distributePlatformAccessFee(address pool, address fundToken, uint256 totalFeeAmount) private {
      uint256 splitFee = totalFeeAmount / 2;
      IERC20(fundToken).approve(stakingAddress, splitFee);
      IERC20(fundToken).approve(lpStakingAddress,splitFee);

      IRewards(stakingAddress).addRewards(fundToken, splitFee);
      IRewards(lpStakingAddress).addRewards(fundToken, splitFee);

      emit TransferredFee(pool, fundToken, stakingAddress, splitFee);
      emit TransferredFee(pool, fundToken, lpStakingAddress, splitFee);
    }
}