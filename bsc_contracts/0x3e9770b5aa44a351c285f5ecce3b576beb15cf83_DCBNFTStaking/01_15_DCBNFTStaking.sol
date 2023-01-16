//** Decubate NFT Staking Contract */
//** Author : Aceson */

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721EnumerableUpgradeable.sol";
import "./interfaces/IStaking.sol";

contract DCBNFTStaking is Initializable, OwnableUpgradeable, IStaking, IERC721ReceiverUpgradeable {
  using SafeMathUpgradeable for uint256;

  /**
   * Pool Struct
   */
  struct PoolExtended {
    Pool common;
    string name;
    string logo;
    string headerLogo;
    string collection;
    uint32 startIdx;
    uint32 endIdx;
    uint32 maxPerUser;
    uint32[] depositedIds;
    mapping(uint256 => uint256) idToArrayIdx;
  }

  struct PoolInfo {
    Pool common;
    string name;
    string logo;
    string headerLogo;
    string collection;
    uint32 startIdx;
    uint32 endIdx;
    uint32 maxPerUser;
    uint32[] depositedIds;
  }

  struct UserExtended {
    User common;
    uint32[] depositedIds;
    mapping(uint256 => uint256) idToArrayIdx;
  }

  PoolExtended[] public poolExt;
  Multiplier[] public multipliers;

  mapping(uint256 => mapping(address => UserExtended)) public userExt;

  event Stake(address indexed user, uint16 _pid, uint32[] indexed ids, uint256 time);
  event ReStake(uint16 _pid, address user, uint256 timestamp);
  event Unstake(address indexed user, uint16 _pid, uint32[] indexed ids, uint256 time);

  function initialize() external initializer {
    __Ownable_init();
  }

  function add(
    bool _isWithdrawLocked,
    uint128 _rewardRate,
    uint16 _lockPeriodInDays,
    uint32 _endDate,
    uint256 _hardCap,
    address _input,
    address _reward
  ) external onlyOwner {
    PoolExtended storage pool = poolExt.push();

    pool.common.isWithdrawLocked = _isWithdrawLocked;
    pool.common.rewardRate = _rewardRate;
    pool.common.lockPeriodInDays = _lockPeriodInDays;
    pool.common.startDate = uint32(block.timestamp);
    pool.common.endDate = _endDate;
    pool.common.hardCap = _hardCap;
    pool.common.input = _input;
    pool.common.reward = _reward;

    multipliers.push(
      Multiplier({ active: false, name: "", contractAdd: address(0), start: 0, end: 0, multi: 100 })
    );
  }

  function set(
    uint16 _pid,
    bool _isWithdrawLocked,
    uint128 _rewardRate,
    uint16 _lockPeriodInDays,
    uint32 _endDate,
    uint256 _hardCap,
    address _input,
    address _reward
  ) external onlyOwner {
    PoolExtended storage pool = poolExt[_pid];

    pool.common.isWithdrawLocked = _isWithdrawLocked;
    pool.common.rewardRate = _rewardRate;
    pool.common.lockPeriodInDays = _lockPeriodInDays;
    pool.common.endDate = _endDate;
    pool.common.hardCap = _hardCap;
    pool.common.input = _input;
    pool.common.reward = _reward;
  }

  function setMultiplier(
    uint16 _pid,
    string calldata _name,
    address _contractAdd,
    bool _isUsed,
    uint16 _multiplier,
    uint128 _start,
    uint128 _end
  ) external onlyOwner {
    Multiplier storage multiplier = multipliers[_pid];

    multiplier.name = _name;
    multiplier.contractAdd = _contractAdd;
    multiplier.active = _isUsed;
    multiplier.multi = _multiplier;
    multiplier.start = _start;
    multiplier.end = _end;
  }

  function setNFTInfo(
    uint16 _pid,
    string memory _name,
    string memory _logo,
    string memory _headerLogo,
    string memory _collection,
    uint32 _startIdx,
    uint32 _endIdx,
    uint32 _maxPerUser
  ) external onlyOwner {
    PoolExtended storage pool = poolExt[_pid];

    pool.name = _name;
    pool.logo = _logo;
    pool.headerLogo = _headerLogo;
    pool.collection = _collection;
    pool.startIdx = _startIdx;
    pool.endIdx = _endIdx;
    pool.maxPerUser = _maxPerUser;
  }

  function stake(uint16 _pid, uint32[] calldata _ids) external {
    PoolExtended storage pool = poolExt[_pid];
    UserExtended storage user = userExt[_pid][msg.sender];

    uint256 stopDepo = pool.common.endDate - (pool.common.lockPeriodInDays * 1 days);
    require(block.timestamp <= stopDepo, "DCB : Staking is disabled for this pool");
    uint256 len = _ids.length;
    require(user.common.totalInvested + len <= pool.maxPerUser, "DCB : Max per user exceeding");
    require(pool.common.totalInvested + len <= pool.common.hardCap, "DCB : Pool is full");

    _claim(_pid, msg.sender);

    IERC721Upgradeable nft = IERC721Upgradeable(pool.common.input);
    uint256 poolLen = pool.depositedIds.length;
    uint256 userLen = user.depositedIds.length;
    uint32 id;

    for (uint256 i = 0; i < len; ) {
      id = _ids[i];
      require(id >= pool.startIdx && id <= pool.endIdx, "DCB : Invalid NFT");
      nft.safeTransferFrom(msg.sender, address(this), id);
      pool.depositedIds.push(id);
      pool.idToArrayIdx[id] = poolLen + i;
      user.depositedIds.push(id);
      user.idToArrayIdx[id] = userLen + i;
      unchecked {
        i++;
      }
    }
    unchecked {
      if (user.common.totalInvested == 0) {
        pool.common.totalInvestors++;
      }
      user.common.totalInvested = user.common.totalInvested + len;
      pool.common.totalInvested = pool.common.totalInvested + len;
      user.common.lastPayout = uint32(block.timestamp);
      user.common.depositTime = uint32(block.timestamp);
    }

    emit Stake(msg.sender, _pid, _ids, block.timestamp);
  }

  function claim(uint16 _pid) external returns (bool) {
    bool status = _claim(_pid, msg.sender);

    require(status, "DCB : Claim not unlocked");

    return true;
  }

  function claimAll() external returns (bool) {
    uint256 len = poolExt.length;

    for (uint16 pid = 0; pid < len; ) {
      _claim(pid, msg.sender);
      unchecked {
        ++pid;
      }
    }

    return true;
  }

  function claimAndRestake(uint16 _pid) external {
    Pool memory pool = poolExt[_pid].common;
    User storage user = userExt[_pid][msg.sender].common;

    uint256 stopDepo = pool.endDate - (pool.lockPeriodInDays * 1 days);
    require(block.timestamp <= stopDepo, "DCB : Staking is disabled for this pool");

    bool status = _claim(_pid, msg.sender);
    require(status, "DCB : Claim still locked");

    user.lastPayout = uint32(block.timestamp);
    user.depositTime = uint32(block.timestamp);

    emit ReStake(_pid, msg.sender, block.timestamp);
  }

  function unStake(uint16 _pid, uint32[] calldata _ids) external {
    UserExtended storage user = userExt[_pid][msg.sender];
    PoolExtended storage pool = poolExt[_pid];

    if (pool.common.isWithdrawLocked) {
      require(canClaim(_pid, msg.sender), "DCB : Stake still in locked state");
    }

    uint256 len = _ids.length;
    uint256 poolLen = pool.depositedIds.length;
    uint256 userLen = user.depositedIds.length;

    require(userLen >= len, "DCB : Deposit/Withdraw Mismatch");

    _claim(_pid, msg.sender);

    IERC721Upgradeable nft = IERC721Upgradeable(pool.common.input);

    for (uint256 i = 0; i < len; ) {
      uint32 id = _ids[i];
      require(
        user.idToArrayIdx[id] != 0 || user.depositedIds[0] == id,
        "DCB : Not staked by caller"
      );
      nft.safeTransferFrom(address(this), msg.sender, id);

      uint256 idx = user.idToArrayIdx[id];
      uint32 last = user.depositedIds[userLen - i - 1];
      user.depositedIds[idx] = last;
      user.idToArrayIdx[last] = idx;
      user.depositedIds.pop();
      user.idToArrayIdx[id] = 0;

      idx = pool.idToArrayIdx[id];
      last = pool.depositedIds[poolLen - i - 1];
      pool.depositedIds[idx] = last;
      pool.idToArrayIdx[last] = idx;
      pool.depositedIds.pop();
      pool.idToArrayIdx[id] = 0;

      unchecked {
        i++;
      }
    }

    unchecked {
      user.common.totalWithdrawn = user.common.totalWithdrawn + len;
      user.common.totalInvested = user.common.totalInvested - len;
      pool.common.totalInvested = pool.common.totalInvested - len;
      if (user.common.totalInvested == 0) {
        pool.common.totalInvestors--;
      }
      user.common.lastPayout = uint32(block.timestamp);
    }

    emit Unstake(msg.sender, _pid, _ids, block.timestamp);
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

  function poolLength() external view override returns (uint256) {
    return poolExt.length;
  }

  function getPools() external view returns (PoolInfo[] memory pools) {
    pools = new PoolInfo[](poolExt.length);

    for (uint256 i = 0; i < poolExt.length; i++) {
      pools[i].common = poolExt[i].common;
      pools[i].name = poolExt[i].name;
      pools[i].logo = poolExt[i].logo;
      pools[i].headerLogo = poolExt[i].headerLogo;
      pools[i].collection = poolExt[i].collection;
      pools[i].startIdx = poolExt[i].startIdx;
      pools[i].endIdx = poolExt[i].endIdx;
      pools[i].maxPerUser = poolExt[i].maxPerUser;
      pools[i].depositedIds = poolExt[i].depositedIds;
    }
  }

  /**
   *
   *
   * @dev Fetching relevant nfts owned by a user
   *
   */
  function walletOfOwner(uint256 _pid, address _owner) external view returns (uint256[] memory) {
    PoolExtended storage pool = poolExt[_pid];
    IERC721EnumerableUpgradeable nft = IERC721EnumerableUpgradeable(pool.common.input);
    uint256 tokenCount = nft.balanceOf(_owner);
    uint256 id;

    uint256[] memory tokensId = new uint256[](tokenCount);
    uint256 count;
    for (uint256 i; i < tokenCount; i++) {
      id = nft.tokenOfOwnerByIndex(_owner, i);
      if (id >= pool.startIdx && id <= pool.endIdx) {
        tokensId[count] = id;
        count++;
      }
    }

    uint256[] memory validIds = new uint256[](count);
    for (uint256 i; i < count; i++) {
      validIds[i] = tokensId[i];
    }

    return validIds;
  }

  function getDepositedIdsOfPool(uint16 _pid) external view returns (uint32[] memory) {
    return poolExt[_pid].depositedIds;
  }

  function getDepositedIdsOfUser(uint16 _pid, address _user)
    external
    view
    returns (uint32[] memory)
  {
    return userExt[_pid][_user].depositedIds;
  }

  // function getIndexOfIdUser(
  //   uint16 _pid,
  //   address _user,
  //   uint256[] memory ids
  // ) external view returns (uint256[] memory idx) {
  //   UserExtended storage user = userExt[_pid][_user];
  //   idx = new uint256[](ids.length);
  //   for (uint256 i = 0; i < ids.length; i++) {
  //     idx[i] = user.idToArrayIdx[ids[i]];
  //   }
  // }

  // function getIndexOfIdPool(uint16 _pid, uint256[] memory ids)
  //   external
  //   view
  //   returns (uint256[] memory idx)
  // {
  //   idx = new uint256[](ids.length);
  //   for (uint256 i = 0; i < ids.length; i++) {
  //     idx[i] = poolExt[_pid].idToArrayIdx[ids[i]];
  //   }
  // }

  /** Always returns `IERC721Receiver.onERC721Received.selector`. */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  function canClaim(uint16 _pid, address _addr) public view returns (bool) {
    User memory user = userExt[_pid][_addr].common;
    Pool memory pool = poolExt[_pid].common;

    return (block.timestamp >= user.depositTime + (pool.lockPeriodInDays * 1 days));
  }

  function payout(uint16 _pid, address _addr) public view returns (uint256 value) {
    User memory user = userExt[_pid][_addr].common;
    Pool memory pool = poolExt[_pid].common;

    uint256 from = user.lastPayout > user.depositTime ? user.lastPayout : user.depositTime;
    uint256 userTime = block.timestamp > (user.depositTime + (pool.lockPeriodInDays * 1 days))
      ? (user.depositTime + (pool.lockPeriodInDays * 1 days))
      : block.timestamp;
    uint256 to = userTime > pool.endDate ? pool.endDate : userTime;

    if (to > from) {
      value = (to.sub(from)).mul(pool.rewardRate).mul(user.totalInvested).div(1 days);
      uint256 multiplier = calcMultiplier(_pid, _addr);
      value = value.mul(multiplier).div(100);
    }
  }

  /**
   *
   * @dev Return multiplier value for user
   *
   * @param _pid  id of the pool
   * @param _addr address of the user
   *
   * @return multi Value of multiplier
   *
   */

  function calcMultiplier(uint16 _pid, address _addr) public view override returns (uint16 multi) {
    Multiplier memory multiplier = multipliers[_pid];

    if (multiplier.active && ownsCorrectMulti(_pid, _addr)) {
      multi = multiplier.multi;
    } else {
      multi = 100;
    }
  }

  /**
   *
   * @dev check if user have multiplier
   *
   * @param _pid  id of the pool
   * @param _addr address of the user
   *
   * @return Status of multiplier
   *
   */
  function ownsCorrectMulti(uint16 _pid, address _addr) public view override returns (bool) {
    return
      IERC20Upgradeable(multipliers[_pid].contractAdd).balanceOf(_addr) >= multipliers[_pid].start;
  }

  function _claim(uint16 _pid, address _user) internal returns (bool) {
    Pool storage pool = poolExt[_pid].common;
    User storage user = userExt[_pid][_user].common;

    if (!canClaim(_pid, _user)) {
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

  function _safeTOKENTransfer(
    address _token,
    address _to,
    uint256 _amount
  ) internal {
    IERC20Upgradeable token = IERC20Upgradeable(_token);
    uint256 bal = token.balanceOf(address(this));
    require(bal >= _amount, "DCB : Not enough funds in treasury");
    token.transfer(_to, _amount);
  }
}