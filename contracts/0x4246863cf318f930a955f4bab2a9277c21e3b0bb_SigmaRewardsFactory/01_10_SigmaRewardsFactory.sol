// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/* ==========  External Interfaces  ========== */
import "@indexed-finance/proxies/contracts/interfaces/IDelegateCallProxyManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* ==========  External Libraries  ========== */
import "@indexed-finance/proxies/contracts/SaltyLib.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/* ==========  External Inheritance  ========== */
import "@openzeppelin/contracts/access/Ownable.sol";

/* ==========  Internal Inheritance  ========== */
import "../interfaces/ISigmaRewardsFactory.sol";


contract SigmaRewardsFactory is Ownable, ISigmaRewardsFactory {
  using SafeMath for uint256;

/* ==========  Constants  ========== */

  /**
   * @dev Used to identify the implementation for staking rewards proxies.
   */
  bytes32 public override constant STAKING_REWARDS_IMPLEMENTATION_ID = keccak256(
    "SigmaStakingRewardsV1.sol"
  );

/* ==========  Immutables  ========== */

  /**
   * @dev Address of the pool factory - used to verify staking token eligibility.
   */
  address public override immutable poolFactory;

  /**
   * @dev The address of the proxy manager - used to deploy staking pools.
   */
  address public override immutable proxyManager;

  /**
   * @dev The address of the token to distribute.
   */
  address public override immutable rewardsToken;

  /**
   * @dev The address of the Uniswap factory - used to compute the addresses
   * of Uniswap pairs eligible for distribution.
   */
  address public override immutable uniswapFactory;

  /**
   * @dev The address of the wrapped ether token - used to identify
   * Uniswap pairs eligible for distribution.
   */
  address public override immutable weth;

  /**
   * @dev Timestamp at which staking begins.
   */
  uint256 public override immutable stakingRewardsGenesis;

/* ==========  Events  ========== */

  event UniswapStakingRewardsAdded(
    address indexPool,
    address stakingToken,
    address stakingRewards
  );

/* ==========  Structs  ========== */

  struct StakingRewardsInfo {
    address stakingRewards;
    uint88 rewardAmount;
  }

/* ==========  Storage  ========== */

  /**
   * @dev The staking tokens for which a rewards contract has been deployed.
   */
  address[] public override stakingTokens;

  /**
   * @dev Rewards info by staking token.
   */
  mapping(address => StakingRewardsInfo) public stakingRewardsInfoByStakingToken;

/* ==========  Constructor  ========== */

  constructor(
    address rewardsToken_,
    uint256 stakingRewardsGenesis_,
    address proxyManager_,
    address poolFactory_,
    address uniswapFactory_,
    address weth_
  ) public Ownable() {
    rewardsToken = rewardsToken_;
    require(
      stakingRewardsGenesis_ >= block.timestamp,
      "SigmaRewardsFactory::constructor: genesis too soon"
    );
    stakingRewardsGenesis = stakingRewardsGenesis_;
    proxyManager = proxyManager_;
    poolFactory = poolFactory_;
    uniswapFactory = uniswapFactory_;
    weth = weth_;
  }

/* ==========  Pool Deployment (Permissioned)  ========== */

  /**
   * @dev Deploys staking rewards for the LP token of the Uniswap pair between an
   * index pool token and WETH.
   *
   * Verifies that the LP token is the address of a pool deployed by the
   * Indexed pool factory, then uses the address of the Uniswap pair between
   * it and WETH as the staking token.
   */
  function deployStakingRewardsForPoolUniswapPair(
    address indexPool,
    uint88 rewardAmount,
    uint256 rewardsDuration
  )
    external
    override
    onlyOwner
  {
    require(
      IPoolFactory(poolFactory).isRecognizedPool(indexPool),
      "SigmaRewardsFactory::deployStakingRewardsForPoolUniswapPair: Not an index pool."
    );

    address pairAddress = UniswapV2AddressLibrary.pairFor(
      address(uniswapFactory),
      indexPool,
      weth
    );

    StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[pairAddress];
    require(
      info.stakingRewards == address(0),
      "SigmaRewardsFactory::deployStakingRewardsForPoolUniswapPair: Already deployed"
    );

    bytes32 stakingRewardsSalt = keccak256(abi.encodePacked(pairAddress));
    address stakingRewards = IDelegateCallProxyManager(proxyManager).deployProxyManyToOne(
      STAKING_REWARDS_IMPLEMENTATION_ID,
      stakingRewardsSalt
    );

    IStakingRewards(stakingRewards).initialize(pairAddress, rewardsDuration);
    info.stakingRewards = stakingRewards;
    info.rewardAmount = rewardAmount;
    stakingTokens.push(pairAddress);
    emit UniswapStakingRewardsAdded(indexPool, pairAddress, stakingRewards);
  }

/* ==========  Rewards Distribution  ========== */

  /**
   * @dev Notifies all tokens of their pending rewards.
   */
  function notifyRewardAmounts() public override {
    require(
      stakingTokens.length > 0,
      "SigmaRewardsFactory::notifyRewardAmounts: called before any deploys"
    );
    for (uint i = 0; i < stakingTokens.length; i++) {
      notifyRewardAmount(stakingTokens[i]);
    }
  }

  /**
   * @dev Notifies the staking pool for the token `stakingToken` of its pending rewards.
   */
  function notifyRewardAmount(address stakingToken) public override {
    require(
      block.timestamp >= stakingRewardsGenesis,
      "SigmaRewardsFactory::notifyRewardAmount: Not ready"
    );

    StakingRewardsInfo storage info = _getRewards(stakingToken);

    if (info.rewardAmount > 0) {
      uint256 rewardAmount = info.rewardAmount;
      info.rewardAmount = 0;

      require(
        IERC20(rewardsToken).transfer(info.stakingRewards, rewardAmount),
        "SigmaRewardsFactory::notifyRewardAmount: Transfer failed"
      );
      IStakingRewards(info.stakingRewards).notifyRewardAmount(rewardAmount);
    }
  }

  /**
   * @dev Increases the staking rewards on the staking pool for `stakingToken`
   * and notify the pool of the new rewards.
   * Only allowed when the current rewards are zero and the staking pool has
   * finished its last rewards period.
   */
  function increaseStakingRewards(address stakingToken, uint88 rewardAmount) external override onlyOwner {
    require(rewardAmount > 0, "SigmaRewardsFactory::increaseStakingRewards: Can not add 0 rewards.");
    StakingRewardsInfo storage info = _getRewards(stakingToken);
    require(
      info.rewardAmount == 0,
      "SigmaRewardsFactory::increaseStakingRewards: Can not add rewards while pool still has pending rewards."
    );
    IStakingRewards pool = IStakingRewards(info.stakingRewards);
    require(
      block.timestamp >= pool.periodFinish(),
      "SigmaRewardsFactory::increaseStakingRewards: Previous rewards period must be complete to add rewards."
    );
    require(
      IERC20(rewardsToken).transfer(address(pool), rewardAmount),
      "SigmaRewardsFactory::increaseStakingRewards: Transfer failed"
    );
    pool.notifyRewardAmount(rewardAmount);
  }

  /**
   * @dev Updates the rewards duration on the staking pool for the token `stakingToken`.
   */
  function setRewardsDuration(address stakingToken, uint256 newDuration) external override onlyOwner {
    StakingRewardsInfo storage info = _getRewards(stakingToken);
    IStakingRewards(info.stakingRewards).setRewardsDuration(newDuration);
  }

/* ==========  Token Recovery  ========== */

  /**
   * @dev Recovers the balance of `tokenAddress` on the staking pool for the token `stakingToken`.
   * The token to recover must not be the staking token or the rewards token for that pool.
   * The balance in `tokenAddress` owned by the pool will be sent to the owner of the rewards factory.
   * @param stakingToken Address of the staking token whose staking pool the tokens will be recovered from.
   * @param tokenAddress Address of the token to recover from the staking pool.
   */
  function recoverERC20(address stakingToken, address tokenAddress) external override {
    StakingRewardsInfo storage info = _getRewards(stakingToken);
    IStakingRewards(info.stakingRewards).recoverERC20(tokenAddress, owner());
  }

/* ==========  Queries  ========== */

  function getStakingTokens() external override view returns (address[] memory) {
    return stakingTokens;
  }

  function getStakingRewards(address stakingToken) external override view returns (address) {
    StakingRewardsInfo storage info = _getRewards(stakingToken);
    return info.stakingRewards;
  }

  function computeStakingRewardsAddress(address stakingToken) external override view returns (address) {
    bytes32 stakingRewardsSalt = keccak256(abi.encodePacked(stakingToken));
    return SaltyLib.computeProxyAddressManyToOne(
      proxyManager,
      address(this),
      STAKING_REWARDS_IMPLEMENTATION_ID,
      stakingRewardsSalt
    );
  }

  /* ==========  Internal  ========== */
  function _getRewards(address stakingToken) internal view returns (StakingRewardsInfo storage) {
    StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
    require(
      info.stakingRewards != address(0),
      "SigmaRewardsFactory::_getRewards: Not deployed"
    );
    return info;
  }
}


library UniswapV2AddressLibrary {
  // returns sorted token addresses, used to handle return values from pairs sorted in this order
  function sortTokens(address tokenA, address tokenB)
    internal
    pure
    returns (address token0, address token1)
  {
    require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
    (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
    require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
  }

  function calculatePair(
    address factory,
    address token0,
    address token1
  ) internal pure returns (address pair) {
    pair = address(
      uint256(
        keccak256(
          abi.encodePacked(
            hex"ff",
            factory,
            keccak256(abi.encodePacked(token0, token1)),
            hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
          )
        )
      )
    );
  }

  // calculates the CREATE2 address for a pair without making any external calls
  function pairFor(
    address factory,
    address tokenA,
    address tokenB
  ) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenA, tokenB);
    pair = calculatePair(factory, token0, token1);
  }
}


interface IPoolFactory {
  function isRecognizedPool(address pool) external view returns (bool);
}


interface IStakingRewards {
  function initialize(address stakingToken, uint256 rewardsDuration) external;

  function recoverERC20(address tokenAddress, address recipient) external;

  function notifyRewardAmount(uint256 reward) external;

  function setRewardsDuration(uint256 rewardsDuration) external;

  function periodFinish() external view returns (uint256);
}