// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IChefIncentivesController} from './interfaces/IChefIncentivesController.sol';
import {IUniswapV3PositionManager} from './interfaces/IUniswapV3PositionManager.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/utils/math/SafeMath.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {ERC721Holder} from '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';

contract MultiFeeDistributionUNIV3POS is ERC721Holder, Ownable {
  using SafeMath for uint;
  using SafeERC20 for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;
  using EnumerableSet for EnumerableSet.UintSet;

  event Locked(address indexed user, uint256 indexed nftId);
  event WithdrawnExpiredLocks(address indexed user, uint256 indexed nftId);

  event Mint(address indexed user, uint256 amount);
  event Exit(address indexed user, uint256 amount, uint256 penaltyAmount);
  event Withdrawn(address indexed user, uint256 indexed nftId);
  event RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);
  event PublicExit();
  event TeamRewardVaultUpdated(address indexed vault);
  event TeamRewardFeeUpdated(uint256 fee);
  event MintersUpdated(address[] minters);
  event IncentivesControllerUpdated(address indexed controller);
  event PositionConfigUpdated(address indexed token0, address indexed token1, uint24 fee, int24 tickLower, int24 tickUpper);
  event RewardAdded(address indexed token);
  event DelegateExitUpdated(address indexed user, address indexed delegatee);

  struct Reward {
    uint256 periodFinish;
    uint256 rewardRate;
    uint256 lastUpdateTime;
    uint256 rewardPerTokenStored;
    uint256 balance;
  }

  struct Balances {
    uint256 earned; // balance reward tokens earned
  }

  struct LockedBalance {
    uint256 amount;
    uint256 unlockTime;
  }

  struct LockedNFT {
    uint256 id;
    uint256 liquidity;
    uint256 unlockTime;
  }

  struct RewardData {
    address token;
    uint256 amount;
  }

  struct NftInfo {
    address owner;
    uint256 liquidity;
    uint256 unlockTime;
  }

  struct PositionConfig {
    address token0;
    address token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
  }

  uint256 public constant rewardsDuration = 86400 * 7; // reward interval 7 days;
  uint256 public constant rewardLookback = 86400;
  uint256 public constant lockDuration = rewardsDuration * 8; // 56 days
  uint256 public constant vestingDuration = rewardsDuration * 4; // 28 days

  // Addresses approved to call mint
  EnumerableSet.AddressSet private minters;
  uint256 internal constant PRECISION = 1e12;

  // user -> reward token -> amount
  mapping(address => mapping(address => uint)) public userRewardPerTokenPaid;
  mapping(address => mapping(address => uint)) public rewards;
  // nftId => Position info
  mapping(uint256 => NftInfo) public nfts;
  // user address => set of nft id which user locked
  mapping(address => EnumerableSet.UintSet) private lockedNFTs;
  // user address => user total liquidity (locked + unlockable)
  mapping(address => uint256) private liquidities;

  IChefIncentivesController public incentivesController;
  IERC721 public immutable nft;
  IERC20 public immutable rewardToken;
  address public immutable rewardTokenVault;
  address public teamRewardVault;
  uint256 public teamRewardFee = 2000; // 1% = 100
  address[] public rewardTokens;
  mapping(address => Reward) public rewardData;

  uint256 public liquiditySupply;
  bool public publicExitAreSet;

  // Private mappings for balance data
  mapping(address => Balances) private balances;
  mapping(address => LockedBalance[]) private userEarnings; // vesting UwU tokens
  mapping(address => address) public exitDelegatee;

  PositionConfig public posConfig;


  constructor(IERC721 _nft, PositionConfig memory _posConfig, IERC20 _rewardToken, address _rewardTokenVault) {
    require(address(_nft) != address(0), 'zero address');
    require(_posConfig.token0 != address(0), 'zero address');
    require(_posConfig.token1 != address(0), 'zero address');
    require(_posConfig.token0 != _posConfig.token1, 'same token');
    require(_posConfig.tickLower < _posConfig.tickUpper, 'invalid tick range');
    require(address(_rewardToken) != address(0), 'zero address');
    require(_rewardTokenVault != address(0), 'zero address');
    nft = _nft;
    posConfig = _posConfig;
    rewardToken = _rewardToken;
    rewardTokenVault = _rewardTokenVault;
    rewardTokens.push(address(_rewardToken));
    rewardData[address(_rewardToken)].lastUpdateTime = block.timestamp;
    rewardData[address(_rewardToken)].periodFinish = block.timestamp;
  }

  function setTeamRewardVault(address vault) external onlyOwner {
    require(vault != address(0), 'zero address');
    teamRewardVault = vault;
    emit TeamRewardVaultUpdated(vault);
  }

  function setTeamRewardFee(uint256 fee) external onlyOwner {
    require(fee <= 5000, 'fee too high'); // max 50%
    teamRewardFee = fee;
    emit TeamRewardFeeUpdated(fee);
  }

  function getMinters() external view returns(address[] memory){
    return minters.values();
  }

  function setMinters(address[] calldata _minters) external onlyOwner {
    uint256 length = minters.length();
    for (uint256 i = 0; i < length; i++) {
      require(minters.remove(minters.at(0)), 'Fail to remove minter');
    }
    for (uint256 i = 0; i < _minters.length; i++) {
      require(minters.add(_minters[i]), 'Fail to add minter');
    }
    emit MintersUpdated(_minters);
  }

  function setIncentivesController(IChefIncentivesController _controller) external onlyOwner {
    require(address(_controller) != address(0), 'zero address');
    incentivesController = _controller;
    emit IncentivesControllerUpdated(address(_controller));
  }

  function setPositionConfig(PositionConfig memory _posConfig) external onlyOwner {
    require(_posConfig.token0 != address(0), 'zero address');
    require(_posConfig.token1 != address(0), 'zero address');
    require(_posConfig.token0 != _posConfig.token1, 'same token');
    require(_posConfig.tickLower < _posConfig.tickUpper, 'invalid tick range');
    posConfig = _posConfig;
    emit PositionConfigUpdated(_posConfig.token0, _posConfig.token1, _posConfig.fee, _posConfig.tickLower, _posConfig.tickUpper);
  }

   // Add a new reward token to be distributed to stakers
  function addReward(address _rewardsToken) external onlyOwner {
    require(_rewardsToken != address(0), 'zero address');
    require(rewardData[_rewardsToken].lastUpdateTime == 0, 'reward token already added');
    rewardTokens.push(_rewardsToken);
    rewardData[_rewardsToken].lastUpdateTime = block.timestamp;
    rewardData[_rewardsToken].periodFinish = block.timestamp;
    emit RewardAdded(_rewardsToken);
  }

  function accountLiquidity(address account) external view returns(
    uint256 total,
    uint256 locked,
    uint256 unlockable
  ) {
    total = liquidities[account];
    uint256[] memory nftIds = lockedNFTs[account].values();
    for (uint i = 0; i < nftIds.length; i++) {
      uint256 nftId = nftIds[i];
      uint256 liquidity = nfts[nftId].liquidity;
      if (nfts[nftId].unlockTime > block.timestamp) {
        locked = locked.add(liquidity);
      } else {
        unlockable = unlockable.add(liquidity);
      }
    }
  }

  function accountAllNFTs(address account) external view returns(LockedNFT[] memory allData) {
    uint256[] memory nftIds = lockedNFTs[account].values();
    allData = new LockedNFT[](nftIds.length);
    for (uint i = 0; i < nftIds.length; i++) {
      uint256 nftId = nftIds[i];
      allData[i] = LockedNFT(nftId, nfts[nftId].liquidity, nfts[nftId].unlockTime);
    }
  }

  function accountLockedNFTs(address account) external view returns(
    LockedNFT[] memory lockedData
  ) {
    uint256 count;
    uint256[] memory nftIds = lockedNFTs[account].values();
    for (uint i = 0; i < nftIds.length; i++) {
      if (nfts[nftIds[i]].unlockTime > block.timestamp) {
        count++;
      }
    }
    lockedData = new LockedNFT[](count);
    uint256 idx;
    for (uint i = 0; i < nftIds.length; i++) {
      uint256 nftId = nftIds[i];
      uint256 unlockTime = nfts[nftId].unlockTime;
      if (unlockTime > block.timestamp) {
        lockedData[idx] = LockedNFT(nftId, nfts[nftId].liquidity, unlockTime);
        idx++;
      }
    }
  }

  function accountUnlockableNFTs(address account) external view returns(
    LockedNFT[] memory unlockableData
  ) {
    uint256 count;
    uint256[] memory nftIds = lockedNFTs[account].values();
    for (uint i = 0; i < nftIds.length; i++) {
      if (nfts[nftIds[i]].unlockTime <= block.timestamp) {
        count++;
      }
    }
    unlockableData = new LockedNFT[](count);
    uint256 idx;
    for (uint i = 0; i < nftIds.length; i++) {
      uint256 nftId = nftIds[i];
      uint256 unlockTime = nfts[nftId].unlockTime;
      if (unlockTime <= block.timestamp) {
        unlockableData[idx] = LockedNFT(nftId, nfts[nftId].liquidity, unlockTime);
        idx++;
      }
    }
  }

  // Information on the 'earned' balances of a user
  function earnedBalances(address user) view external returns (uint256 total, LockedBalance[] memory earningsData) {
    LockedBalance[] memory earnings = userEarnings[user];
    uint256 idx;
    for (uint256 i = 0; i < earnings.length; i++) {
      if (earnings[i].unlockTime > block.timestamp) {
        if (idx == 0) {
          earningsData = new LockedBalance[](earnings.length - i);
        }
        earningsData[idx] = earnings[i];
        idx++;
        total = total.add(earnings[i].amount);
      }
    }
    return (total, earningsData);
  }

  function withdrawableBalance(address user) view public returns (
    uint256 amount,
    uint256 penaltyAmount,
    uint256 amountWithoutPenalty
  ) {
    Balances memory bal = balances[user];
    uint256 earned = bal.earned;
    if (earned > 0) {
      uint256 length = userEarnings[user].length;
      for (uint256 i = 0; i < length; i++) {
        uint256 earnedAmount = userEarnings[user][i].amount;
        if (earnedAmount == 0) continue;
        if (userEarnings[user][i].unlockTime > block.timestamp) {
          break;
        }
        amountWithoutPenalty = amountWithoutPenalty.add(earnedAmount);
      }
      penaltyAmount = earned.sub(amountWithoutPenalty).div(2);
    }
    amount = earned.sub(penaltyAmount);
  }

  // Address and claimable amount of all reward tokens for the given account
  function claimableRewards(address account) external view returns (RewardData[] memory rewardDatas) {
    rewardDatas = new RewardData[](rewardTokens.length);
    for (uint256 i = 0; i < rewardDatas.length; i++) {
      rewardDatas[i].token = rewardTokens[i];
      rewardDatas[i].amount = _earned(account, rewardDatas[i].token, liquidities[account], _rewardPerToken(rewardTokens[i], liquiditySupply)).div(PRECISION);
    }
    return rewardDatas;
  }

  /**
   * @dev Lock NFTs info contract
   * @param nftIds List of NFT ids to lock
   */
  function lock(uint256[] calldata nftIds) external {
    address sender = msg.sender;
    _updateReward(sender);
    for (uint256 i = 0; i < nftIds.length; i++) {
      uint256 nftId = nftIds[i];
      ( , , address token0, address token1, uint24 fee, int24 tickLower, int24 tickUpper, uint128 liquidity, , , , ) = IUniswapV3PositionManager(address(nft)).positions(nftId);
      require(posConfig.tickLower <= tickLower, 'Exceeded lower tick range');
      require(posConfig.tickUpper >= tickUpper, 'Exceeded upper tick range');
      require(posConfig.fee == fee, 'Invalid fee');
      require(posConfig.token0 == token0, 'Invalid token0');
      require(posConfig.token1 == token1, 'Invalid token1');
      require(liquidity > 0, 'Invalid liquidity');
      require(lockedNFTs[sender].add(nftId), 'Fail to add lockedNFTs');
      nfts[nftId].owner = sender;
      nfts[nftId].liquidity = liquidity;
      nfts[nftId].unlockTime = block.timestamp.add(lockDuration);
      liquidities[sender] = liquidities[sender].add(liquidity);
      liquiditySupply = liquiditySupply.add(liquidity);
      nft.transferFrom(sender, address(this), nftId);
      emit Locked(sender, nftId);
    }
  }

  /**
   * @dev Withdraw NFTs with expired locks from contract
   */
  function withdrawExpiredLocks() external {
    address sender = msg.sender;
    _updateReward(sender);
    uint256[] memory nftIds = lockedNFTs[sender].values();
    for (uint256 i = 0; i < nftIds.length; i++) {
      uint256 nftId = nftIds[i];
      if (nfts[nftId].unlockTime <= block.timestamp || publicExitAreSet) {
        uint256 liquidity = nfts[nftId].liquidity;
        liquiditySupply = liquiditySupply.sub(liquidity);
        liquidities[sender] = liquidities[sender].sub(liquidity);
        require(lockedNFTs[sender].remove(nftId), 'Fail to remove lockedNFTs');
        delete nfts[nftId];
        nft.safeTransferFrom(address(this), sender, nftId);
        emit WithdrawnExpiredLocks(sender, nftId);
      }
    }
  }

  function mint(address user, uint256 amount) external {
    require(user != address(0), 'zero address');
    require(minters.contains(msg.sender), '!minter');
    if (amount == 0) return;
    _updateReward(user);
    rewardToken.safeTransferFrom(rewardTokenVault, address(this), amount);
    if (user == address(this)) {
      // minting to this contract adds the new tokens as incentives for lockers
      _notifyReward(address(rewardToken), amount);
      return;
    }
    Balances storage bal = balances[user];
    bal.earned = bal.earned.add(amount);
    uint256 unlockTime = block.timestamp.div(rewardsDuration).mul(rewardsDuration).add(vestingDuration);
    LockedBalance[] storage earnings = userEarnings[user];
    uint256 idx = earnings.length;
    if (idx == 0 || earnings[idx-1].unlockTime < unlockTime) {
      earnings.push(LockedBalance({amount: amount, unlockTime: unlockTime}));
    } else {
      earnings[idx-1].amount = earnings[idx-1].amount.add(amount);
    }
    emit Mint(user, amount);
  }

  // Delegate exit
  function delegateExit(address delegatee) external {
    exitDelegatee[msg.sender] = delegatee;
    emit DelegateExitUpdated(msg.sender, delegatee);
  }

  // Withdraw full unlocked balance
  function exit(address onBehalfOf) external {
    require(onBehalfOf == msg.sender || exitDelegatee[onBehalfOf] == msg.sender, 'Not authorized');
    _updateReward(onBehalfOf);
    (uint256 amount, uint256 penaltyAmount,) = withdrawableBalance(onBehalfOf);
    delete userEarnings[onBehalfOf];
    Balances storage bal = balances[onBehalfOf];
    bal.earned = 0;
    rewardToken.safeTransfer(onBehalfOf, amount);
    if (penaltyAmount > 0) {
      incentivesController.claim(address(this), new address[](0));
      _notifyReward(address(rewardToken), penaltyAmount);
    }
    emit Exit(onBehalfOf, amount, penaltyAmount);
  }

  // Withdraw staked tokens
  function withdraw() external {
    _updateReward(msg.sender);
    Balances storage bal = balances[msg.sender];
    if (bal.earned > 0) {
      uint256 amount;
      uint256 length = userEarnings[msg.sender].length;
      if (userEarnings[msg.sender][length - 1].unlockTime <= block.timestamp)  {
        amount = bal.earned;
        delete userEarnings[msg.sender];
      } else {
        for (uint256 i = 0; i < length; i++) {
          uint256 earnedAmount = userEarnings[msg.sender][i].amount;
          if (earnedAmount == 0) continue;
          if (userEarnings[msg.sender][i].unlockTime > block.timestamp) {
            break;
          }
          amount = amount.add(earnedAmount);
          delete userEarnings[msg.sender][i];
        }
      }
      if (amount > 0) {
        bal.earned = bal.earned.sub(amount);
        rewardToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
      }
    }
  }

  // Transfer rewards to wallet
  function getReward(address[] memory _rewardTokens) external {
    _updateReward(msg.sender);
    _getReward(_rewardTokens);
  }

  function lastTimeRewardApplicable(address _rewardsToken) public view returns (uint) {
    uint256 periodFinish = rewardData[_rewardsToken].periodFinish;
    return block.timestamp < periodFinish ? block.timestamp : periodFinish;
  }

  function _getReward(address[] memory _rewardTokens) internal {
    uint256 length = _rewardTokens.length;
    for (uint256 i; i < length; i++) {
      address token = _rewardTokens[i];
      uint256 reward = rewards[msg.sender][token].div(PRECISION);
      if (token != address(rewardToken)) {
        // for rewards other than rewardToken, every 24 hours we check if new
        // rewards were sent to the contract or accrued via uToken interest
        Reward storage r = rewardData[token];
        uint256 periodFinish = r.periodFinish;
        require(periodFinish != 0, 'Unknown reward token');
        uint256 balance = r.balance;
        if (periodFinish < block.timestamp.add(rewardsDuration - rewardLookback)) {
          uint256 unseen = IERC20(token).balanceOf(address(this)).sub(balance);
          if (unseen != 0) {
            uint256 adjustedAmount = _adjustReward(token, unseen);
            _notifyReward(token, adjustedAmount);
            balance = balance.add(adjustedAmount);
          }
        }
        r.balance = balance.sub(reward);
      }
      if (reward == 0) continue;
      rewards[msg.sender][token] = 0;
      IERC20(token).safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, token, reward);
    }
  }

  function _rewardPerToken(address _rewardsToken, uint256 _supply) internal view returns (uint) {
    if (_supply == 0) {
      return rewardData[_rewardsToken].rewardPerTokenStored;
    }
    return rewardData[_rewardsToken].rewardPerTokenStored.add(
      lastTimeRewardApplicable(_rewardsToken)
      .sub(rewardData[_rewardsToken].lastUpdateTime)
      .mul(rewardData[_rewardsToken].rewardRate)
      .mul(PRECISION).div(_supply)
    );
  }

  function _earned(
    address _user,
    address _rewardsToken,
    uint256 _balance,
    uint256 _currentRewardPerToken
  ) internal view returns (uint) {
    return _balance.mul(
      _currentRewardPerToken.sub(userRewardPerTokenPaid[_user][_rewardsToken])
    ).div(PRECISION).add(rewards[_user][_rewardsToken]);
  }

  function _notifyReward(address _rewardsToken, uint256 reward) internal {
    Reward storage r = rewardData[_rewardsToken];
    if (block.timestamp >= r.periodFinish) {
      r.rewardRate = reward.mul(PRECISION).div(rewardsDuration);
    } else {
      uint256 remaining = r.periodFinish.sub(block.timestamp);
      uint256 leftover = remaining.mul(r.rewardRate).div(PRECISION);
      r.rewardRate = reward.add(leftover).mul(PRECISION).div(rewardsDuration);
    }
    r.lastUpdateTime = block.timestamp;
    r.periodFinish = block.timestamp.add(rewardsDuration);
  }

  function _updateReward(address account) internal {
    uint256 length = rewardTokens.length;
    for (uint256 i = 0; i < length; i++) {
      address token = rewardTokens[i];
      Reward storage r = rewardData[token];
      uint256 rpt = _rewardPerToken(token, liquiditySupply);
      r.rewardPerTokenStored = rpt;
      r.lastUpdateTime = lastTimeRewardApplicable(token);
      if (account != address(this)) {
        rewards[account][token] = _earned(account, token, liquidities[account], rpt);
        userRewardPerTokenPaid[account][token] = rpt;
      }
    }
  }

  function _adjustReward(address _rewardsToken, uint256 reward) internal returns (uint256 adjustedAmount) {
    if (reward > 0 && teamRewardVault != address(0) && _rewardsToken != address(rewardToken)) {
      uint256 feeAmount = reward.mul(teamRewardFee).div(10000);
      adjustedAmount = reward.sub(feeAmount);
      if (feeAmount > 0) {
        IERC20(_rewardsToken).safeTransfer(teamRewardVault, feeAmount);
      }
    } else {
      adjustedAmount = reward;
    }
  }

  function publicExit() external onlyOwner {
    require(!publicExitAreSet, 'public exit are set');
    publicExitAreSet = true;
    emit PublicExit();
  }

}