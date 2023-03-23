// SPDX-License-Identifier: MIT

//** Decubate Liquidity Locking Contract */
//** Author: Aceson 2022.7 */

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721EnumerableUpgradeable.sol";
import "./interfaces/IStaking.sol";

contract DCBLiqLocker is Initializable, OwnableUpgradeable, IStaking {
  using SafeMathUpgradeable for uint256;
  using SafeMathUpgradeable for uint32;

  IUniswapV2Router02 public router;

  Multiplier[] public multis;
  Pool[] public pools;
  mapping(uint256 => mapping(address => User)) public users;

  event Lock(uint8 poolId, address indexed user, uint256 lpAmount, uint256 time);
  event Unlock(uint256 poolId, address indexed user, uint256 lpAmount, uint256 time);
  event LPAdded(address indexed user, uint256 token0, uint256 token1, uint256 lpAmount);
  event LPRemoved(address indexed user, uint256 lpAmount, uint256 token0, uint256 token1);

  // solhint-disable-next-line
  receive() external payable {}

  /**
   *
   * @dev Transfer dust token out of contract (Also a Fail safe)
   *
   * @param _token Address of token
   *
   * @return status of transfer
   *
   */
  function transferToken(address _token) external onlyOwner returns (bool) {
    if (_token == address(0x0)) {
      payable(owner()).transfer(address(this).balance);
      return true;
    }

    IERC20Upgradeable token = IERC20Upgradeable(_token);
    uint256 balance = token.balanceOf(address(this));
    token.transfer(owner(), balance);

    return true;
  }

  /**
   *
   * @dev add new period to the pool, only available for owner
   *
   */
  function add(
    bool _isWithdrawLocked,
    uint128 _rewardRate,
    uint16 _lockPeriodInDays,
    uint32 _endDate,
    uint256, //_hardCap, To comply with common staking interface
    address _inputToken,
    address _rewardToken
  ) external override onlyOwner {
    pools.push(
      Pool({
        isWithdrawLocked: _isWithdrawLocked,
        rewardRate: _rewardRate,
        lockPeriodInDays: _lockPeriodInDays,
        totalInvestors: 0,
        totalInvested: 0,
        hardCap: type(uint256).max,
        startDate: uint32(block.timestamp),
        endDate: _endDate,
        input: _inputToken,
        reward: _rewardToken
      })
    );

    //Init nft struct with dummy data
    multis.push(
      Multiplier({ active: false, name: "", contractAdd: address(0), start: 0, end: 0, multi: 100 })
    );

    IUniswapV2Pair pair = IUniswapV2Pair(_inputToken);
    pair.approve(address(router), type(uint256).max);

    require(_rewardToken == pair.token0() || _rewardToken == pair.token1(), "Invalid reward");

    IERC20Upgradeable(pair.token0()).approve(address(router), type(uint256).max);
    IERC20Upgradeable(pair.token1()).approve(address(router), type(uint256).max);
  }

  /**
   *
   * @dev update the given pool's Info
   *
   */
  function set(
    uint16 _pid,
    bool _isWithdrawLocked,
    uint128 _rewardRate,
    uint16 _lockPeriodInDays,
    uint32 _endDate,
    uint256, //_hardCap, To comply with common staking interface
    address, //_input, To comply with common staking interface
    address //_reward To comply with common staking interface
  ) external override onlyOwner {
    require(_pid < pools.length, "Invalid pool Id");

    Pool storage pool = pools[_pid];

    pool.rewardRate = _rewardRate;
    pool.isWithdrawLocked = _isWithdrawLocked;
    pool.lockPeriodInDays = _lockPeriodInDays;
    pool.endDate = _endDate;
  }

  /**
   *
   * @dev update the given pool's nft info
   *
   */
  function setMultiplier(
    uint16 _pid,
    string calldata _name,
    address _contractAdd,
    bool _isUsed,
    uint16 _multi,
    uint128 _start,
    uint128 _end
  ) external override onlyOwner {
    Multiplier storage nft = multis[_pid];

    nft.name = _name;
    nft.contractAdd = _contractAdd;
    nft.active = _isUsed;
    nft.multi = _multi;
    nft.start = _start;
    nft.end = _end;
  }

  function transferStuckToken(address _token) external onlyOwner returns (bool) {
    IERC20Upgradeable token = IERC20Upgradeable(_token);
    uint256 balance = token.balanceOf(address(this));
    token.transfer(owner(), balance);

    return true;
  }

  function transferStuckNFT(address _nft, uint256 _id) external onlyOwner returns (bool) {
    IERC721Upgradeable nft = IERC721Upgradeable(_nft);
    nft.safeTransferFrom(address(this), owner(), _id);

    return true;
  }

  /**
   *
   * @dev Adds liquidity and locks lp token
   *
   * @param _pid  id of the pool
   * @param _token0Amt Amount of token0 added to liquidity
   * @param _token1Amt Amount of token1 added to liquidity
   *
   * @return status of addition
   *
   */
  function addLiquidityAndLock(
    uint8 _pid,
    uint256 _token0Amt,
    uint256 _token1Amt
  ) external payable returns (bool) {
    uint256 _lpAmount;

    _claim(_pid, msg.sender);

    IUniswapV2Pair pair = IUniswapV2Pair(pools[_pid].input);
    uint8 pos = isWrappedNative(pair);

    if (pos != 2) {
      if (pos == 0) {
        _lpAmount = _addLiquidityETH(pair.token1(), msg.value, _token1Amt);
      } else {
        _lpAmount = _addLiquidityETH(pair.token0(), msg.value, _token0Amt);
      }
    } else {
      _lpAmount = _addLiquidity(pair, _token0Amt, _token1Amt);
    }
    if (_lpAmount > 0) {
      _lockLp(_pid, msg.sender, _lpAmount);
    }
    return true;
  }

  /**
   * Unlock LP tokens
   *
   * @param _pid id of the pool
   * @param _amount amount to be unlocked
   *
   * @return bool Status of unlock
   *
   */
  function unlockAndRemoveLP(uint16 _pid, uint256 _amount) external returns (bool) {
    User storage user = users[_pid][msg.sender];
    Pool storage pool = pools[_pid];

    require(user.totalInvested >= _amount, "You don't have enough locked");

    if (pool.isWithdrawLocked) {
      require(canClaim(_pid, msg.sender), "Stake still in locked state");
    }

    _claim(_pid, msg.sender);

    //Removing LP
    uint256 token0;
    uint256 token1;
    IUniswapV2Pair pair = IUniswapV2Pair(pools[_pid].input);
    uint8 pos = isWrappedNative(pair);
    if (pos != 2) {
      if (pos == 0) {
        (token0, token1) = _removeLiquidityETH(pair.token1(), msg.sender, _amount);
      } else {
        (token0, token1) = _removeLiquidityETH(pair.token0(), msg.sender, _amount);
      }
    } else {
      (token0, token1) = _removeLiquidity(_pid, msg.sender, _amount);
    }

    emit Unlock(_pid, msg.sender, _amount, block.timestamp);

    pool.totalInvested = pool.totalInvested.sub(_amount);

    user.totalWithdrawn = user.totalWithdrawn.add(_amount);
    user.totalInvested = user.totalInvested.sub(_amount);
    user.lastPayout = uint32(block.timestamp);

    unchecked {
      if (user.totalInvested == 0) {
        pool.totalInvestors--;
      }
    }

    return true;
  }

  /**
   *
   * @dev Unlock lp tokens and claim reward
   *
   * @param _pid  id of the pool
   *
   * @return status of unlock
   *
   */
  function claim(uint16 _pid) external override returns (bool) {
    bool status = _claim(_pid, msg.sender);

    require(status, "Claim failed");

    return true;
  }

  /**
   *
   * @dev claim accumulated TOKEN reward from all pools
   *
   * Beware of gas fee!
   *
   */
  function claimAll() external override returns (bool) {
    uint256 len = pools.length;

    for (uint16 pid = 0; pid < len; ) {
      _claim(pid, msg.sender);
      unchecked {
        ++pid;
      }
    }

    return true;
  }

  /**
   *
   * @dev get length of the pools
   *
   * @return {uint256} length of the pools
   *
   */
  function poolLength() external view override returns (uint256) {
    return pools.length;
  }

  /**
   *
   * @dev get all pools info
   *
   * @return {Pool[]} length of the pools
   *
   */

  function getPools() external view returns (Pool[] memory) {
    return pools;
  }

  /**
   *
   * @dev Constructor for proxy
   *
   * @param _router Address of router (Pancake)
   *
   */
  function initialize(address _router) public initializer {
    __Ownable_init();

    router = IUniswapV2Router02(_router);
  }

  function payout(uint16 _pid, address _addr) public view override returns (uint256 rewardAmount) {
    Pool memory pool = pools[_pid];
    User memory user = users[_pid][_addr];

    uint256 from = user.lastPayout >= user.depositTime ? user.lastPayout : user.depositTime;

    uint256 usersLastTime = user.depositTime.add(pool.lockPeriodInDays * 1 days);
    uint256 to = block.timestamp >= usersLastTime ? usersLastTime : block.timestamp;

    if (to > from) {
      uint256 reward = (to.sub(from)).mul(user.totalInvested).mul(pool.rewardRate).div(1000).div(
        365 days
      );
      uint256 multiplier = calcMultiplier(_pid, _addr);
      reward = reward.mul(multiplier).div(100);
      IUniswapV2Pair pair = IUniswapV2Pair(pools[_pid].input);
      (uint256 amt0, uint256 amt1) = getTokenAmounts(reward, pair);
      rewardAmount = pair.token0() == pool.reward ? amt0 : amt1;
      rewardAmount = rewardAmount * 2; //Both tokens in pair
    }
  }

  /**
   *
   * @dev check whether user can Unlock or not
   *
   * @param {_pid}  id of the pool
   * @param {_did} id of the deposit
   * @param {_addr} address of the user
   *
   * @return {bool} Status of Unstake
   *
   */
  function canClaim(uint16 _pid, address _addr) public view override returns (bool) {
    User memory user = users[_pid][_addr];
    Pool memory pool = pools[_pid];

    return (block.timestamp >= user.depositTime.add(pool.lockPeriodInDays * 1 days));
  }

  /**
   *
   * @dev Check whether user owns correct NFT for boost
   *
   */
  function ownsCorrectMulti(uint16 _pid, address _addr) public view override returns (bool) {
    Multiplier memory nft = multis[_pid];

    uint256[] memory ids = _walletOfOwner(nft.contractAdd, _addr);
    for (uint256 i = 0; i < ids.length; ) {
      if (ids[i] >= nft.start && ids[i] <= nft.end) {
        return true;
      }
      unchecked {
        i++;
      }
    }
    return false;
  }

  /**
   *
   * @dev check whether user have NFT multiplier
   *
   * @param _pid  id of the pool
   * @param _addr address of the user
   *
   * @return multi Value of multiplier
   *
   */

  function calcMultiplier(uint16 _pid, address _addr) public view override returns (uint16 multi) {
    Multiplier memory nft = multis[_pid];

    if (nft.active && ownsCorrectMulti(_pid, _addr)) {
      multi = nft.multi;
    } else {
      multi = 100;
    }
  }

  /**
   *
   * @dev check whether the pool is made of native coin
   *
   * @param _pair address of pair contract
   *
   * @return pos whether it is token0 or token1
   *
   */
  function isWrappedNative(IUniswapV2Pair _pair) public view returns (uint8 pos) {
    if (_pair.token0() == router.WETH()) {
      pos = 0;
    } else if (_pair.token1() == router.WETH()) {
      pos = 1;
    } else {
      pos = 2;
    }
  }

  function getTokenAmounts(
    uint256 _amount,
    IUniswapV2Pair _pair
  ) public view returns (uint256 amount0, uint256 amount1) {
    (uint256 reserve0, uint256 reserve1, ) = _pair.getReserves();

    amount0 = _amount.mul(reserve0).div(_pair.totalSupply());
    amount1 = _amount.mul(reserve1).div(_pair.totalSupply());
  }

  function _addLiquidity(
    IUniswapV2Pair _pair,
    uint256 _token0Amt,
    uint256 _token1Amt
  ) internal returns (uint256 lpTokens) {
    IERC20Upgradeable(_pair.token0()).transferFrom(msg.sender, address(this), _token0Amt);
    IERC20Upgradeable(_pair.token1()).transferFrom(msg.sender, address(this), _token1Amt);

    (, , lpTokens) = router.addLiquidity(
      _pair.token0(),
      _pair.token1(),
      _token0Amt,
      _token1Amt,
      _token0Amt.mul(95).div(100), //5% slippage
      _token1Amt.mul(95).div(100), //5% slippage
      address(this),
      block.timestamp + 100
    );

    emit LPAdded(msg.sender, _token0Amt, _token1Amt, lpTokens);
  }

  function _addLiquidityETH(
    address _token,
    uint256 _nativeValue,
    uint256 _tokenValue
  ) internal returns (uint256 lpTokens) {
    IERC20Upgradeable(_token).transferFrom(msg.sender, address(this), _tokenValue);

    (, , lpTokens) = router.addLiquidityETH{ value: _nativeValue }(
      _token,
      _tokenValue,
      _tokenValue.mul(95).div(100),
      _nativeValue.mul(95).div(100),
      address(this),
      block.timestamp + 100
    );

    emit LPAdded(msg.sender, _nativeValue, _tokenValue, lpTokens);
  }

  function _removeLiquidity(
    uint16 _pid,
    address _user,
    uint256 _amount
  ) internal returns (uint256 _amount0, uint256 _amount1) {
    IUniswapV2Pair pair = IUniswapV2Pair(pools[_pid].input);

    (_amount0, _amount1) = router.removeLiquidity(
      pair.token0(),
      pair.token1(),
      _amount,
      0,
      0,
      _user,
      block.timestamp + 100
    );

    emit LPRemoved(msg.sender, _amount, _amount0, _amount1);
  }

  function _removeLiquidityETH(
    address _token,
    address _user,
    uint256 _amount
  ) internal returns (uint256 _amount0, uint256 _amount1) {
    (_amount0, _amount1) = router.removeLiquidityETH(
      _token,
      _amount,
      0,
      0,
      _user,
      block.timestamp + 100
    );

    emit LPRemoved(msg.sender, _amount, _amount0, _amount1);
  }

  function _claim(uint16 _pid, address _user) internal returns (bool) {
    Pool storage pool = pools[_pid];
    User storage user = users[_pid][_user];

    if (!pool.isWithdrawLocked && !canClaim(_pid, _user)) {
      return false;
    }

    uint256 amount = payout(_pid, _user);

    if (amount > 0) {
      _safeTOKENTransfer(pool.reward, _user, amount);

      user.totalClaimed = user.totalClaimed.add(amount);
    }

    user.lastPayout = uint32(block.timestamp);

    emit Claim(_pid, _user, amount, block.timestamp);

    return true;
  }

  function _lockLp(uint8 _pid, address _sender, uint256 _lpAmount) internal {
    Pool storage pool = pools[_pid];
    User storage user = users[_pid][_sender];

    uint256 stopDepo = pool.endDate.sub(pool.lockPeriodInDays * 1 days);
    require(block.timestamp <= stopDepo, "Locking is disabled for this pool");

    if (user.totalInvested == 0) {
      unchecked {
        pool.totalInvestors++;
      }
    }

    user.totalInvested = user.totalInvested.add(_lpAmount);
    pool.totalInvested = pool.totalInvested.add(_lpAmount);

    user.depositTime = uint32(block.timestamp);
    user.lastPayout = uint32(block.timestamp);

    emit Lock(_pid, _sender, _lpAmount, block.timestamp);
  }

  function _safeTOKENTransfer(address _token, address _to, uint256 _amount) internal {
    IERC20Upgradeable token = IERC20Upgradeable(_token);
    uint256 bal = token.balanceOf(address(this));
    require(bal >= _amount, "Not enough funds in treasury");

    if (_amount > 0) {
      token.transfer(_to, _amount);
    }
  }

  /**
   *
   * @dev Fetching nfts owned by a user
   *
   */
  function _walletOfOwner(
    address _contract,
    address _owner
  ) internal view returns (uint256[] memory) {
    IERC721EnumerableUpgradeable nft = IERC721EnumerableUpgradeable(_contract);
    uint256 tokenCount = nft.balanceOf(_owner);

    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; ) {
      tokensId[i] = nft.tokenOfOwnerByIndex(_owner, i);
      unchecked {
        i++;
      }
    }
    return tokensId;
  }
}