// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./libraries/multicall.sol";
import "./libraries/Math.sol";
import "./libraries/FixedPoints.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

// import "hardhat/console.sol";

contract veiZi is Ownable, Multicall, ReentrancyGuard, ERC721Enumerable, IERC721Receiver {
    using SafeERC20 for IERC20;
    
    /// @dev Point of epochs
    /// for each epoch, y = bias - (t - timestamp) * slope
    struct Point {
        int256 bias;
        int256 slope;
        // start of segment
        uint256 timestamp;
    }

    /// @dev locked info of a nft
    struct LockedBalance {
        // amount of token locked
        int256 amount;
        // end block
        uint256 end;
    }

    int128 constant DEPOSIT_FOR_TYPE = 0;
    int128 constant CREATE_LOCK_TYPE = 1;
    int128 constant INCREASE_LOCK_AMOUNT = 2;
    int128 constant INCREASE_UNLOCK_TIME = 3;

    /// @notice emit if successfully deposit (calling increaseAmount, createLock, increaseUnlockTime)
    /// @param nftId id of nft, starts from 1
    /// @param value amount of token locked
    /// @param lockBlk end block
    /// @param depositType createLock / increaseAmount / increaseUnlockTime / depositFor
    /// @param timestamp start timestamp
    event Deposit(uint256 indexed nftId, uint256 value, uint256 indexed lockBlk, int128 depositType, uint256 timestamp);

    /// @notice emit if successfuly withdraw
    /// @param nftId id of nft, starts from 1
    /// @param value amount of token released
    /// @param timestamp block timestamp when calling withdraw(...)
    event Withdraw(uint256 indexed nftId, uint256 value, uint256 timestamp);

    /// @notice emit if an user successfully staked a nft
    /// @param nftId id of nft, starts from 1
    /// @param owner address of user
    event Stake(uint256 indexed nftId, address indexed owner);

    /// @notice emit if an user unstaked a staked nft
    /// @param nftId id of nft, starts from 1
    /// @param owner address of user
    event Unstake(uint256 indexed nftId, address indexed owner);

    /// @notice emit if the total amount of locked token changes
    /// @param preSupply total amount before change
    /// @param supply total amount after change
    event Supply(uint256 preSupply, uint256 supply);

    /// @notice number of block in a week (estimated)
    uint256 public WEEK;
    /// @notice number of block for 4 years
    uint256 public MAXTIME;
    /// @notice block delta 
    uint256 public secondsPerBlockX64;

    /// @notice erc-20 token to lock
    address public token;
    /// @notice total amount of locked token
    uint256 public supply;

    /// @notice num of nft generated
    uint256 public nftNum = 0;

    /// @notice locked info for each nft
    mapping(uint256 => LockedBalance) public nftLocked;

    uint256 public epoch;

    /// @notice weight-curve(veiZi amount) of total-weight for all nft
    mapping(uint256 => Point) public pointHistory;
    mapping(uint256 => int256) public slopeChanges;

    /// @notice weight-curve of each nft
    mapping(uint256 => mapping(uint256 => Point)) public nftPointHistory;
    mapping(uint256 => uint256) public nftPointEpoch;

    /// @notice total num of nft staked
    uint256 public stakeNum = 0; // +1 every time when calling stake(...)
    /// @notice total amount of staked iZi
    uint256 public stakeiZiAmount = 0;

    struct StakingStatus {
        uint256 stakingId;
        uint256 lockAmount;
        uint256 lastVeiZi;
        uint256 lastTouchBlock;
        uint256 lastTouchAccRewardPerShare;
    }
    
    /// @notice nftId to staking status
    mapping(uint256 => StakingStatus) public stakingStatus;
    /// @notice owner address of staked nft
    mapping(uint256 => address) public stakedNftOwners;
    /// @notice nftid the user staked, 0 for no staked. each user can stake at most 1 nft
    mapping(address => uint256) public stakedNft;

    string public baseTokenURI;

    mapping(uint256 => address) public delegateAddress;

    struct RewardInfo {
        /// @dev who provides reward
        address provider;
        /// @dev Accumulated Reward Tokens per share, times Q128.
        uint256 accRewardPerShare;
        /// @dev Reward amount for each block.
        uint256 rewardPerBlock;
        /// @dev Last block number that the accRewardRerShare is touched.
        uint256 lastTouchBlock;

        /// @dev The block number when NFT mining rewards starts/ends.
        uint256 startBlock;
        /// @dev The block number when NFT mining rewards starts/ends.
        uint256 endBlock;
    }

    /// @dev reward infos
    RewardInfo public rewardInfo;

    modifier checkAuth(uint256 nftId, bool allowStaked) {
        bool auth = _isApprovedOrOwner(msg.sender, nftId);
        if (allowStaked) {
            auth = auth || (stakedNft[msg.sender] == nftId);
        }
        require(auth, "Not Owner or Not exist!");
        _;
    }

    /// @notice constructor
    /// @param tokenAddr address of locked token
    /// @param _rewardInfo reward info
    constructor(address tokenAddr, RewardInfo memory _rewardInfo) ERC721("iZUMi DAO veNFT", "veiZi") {
        token = tokenAddr;
        pointHistory[0].timestamp = block.timestamp;

        WEEK = 7 * 24 * 3600;
        MAXTIME = (4 * 365 + 1) * 24 * 3600;

        rewardInfo = _rewardInfo;
        rewardInfo.accRewardPerShare = 0;
        rewardInfo.lastTouchBlock = Math.max(_rewardInfo.startBlock, block.number);

    }

    /// @notice Used for ERC721 safeTransferFrom
    function onERC721Received(address, address, uint256, bytes memory) 
        public 
        virtual 
        override 
        returns (bytes4) 
    {
        return this.onERC721Received.selector;
    }

    /// @notice get slope of last epoch of weight-curve of an nft
    /// @param nftId id of nft, starts from 1
    function getLastNftSlope(uint256 nftId) external view returns(int256) {
        uint256 uepoch = nftPointEpoch[nftId];
        return nftPointHistory[nftId][uepoch].slope;
    }

    struct CheckPointState {
        int256 oldDslope;
        int256 newDslope;
        uint256 _epoch;
    }

    function _checkPoint(uint256 nftId, LockedBalance memory oldLocked, LockedBalance memory newLocked) internal {

        Point memory uOld;
        Point memory uNew;
        CheckPointState memory cpState;
        cpState.oldDslope = 0;
        cpState.newDslope = 0;
        cpState._epoch = epoch;

        if (nftId != 0) {
            if (oldLocked.end > block.timestamp && oldLocked.amount > 0) {
                uOld.slope = oldLocked.amount / int256(MAXTIME);
                uOld.bias = uOld.slope * int256(oldLocked.end - block.timestamp);
            }
            if (newLocked.end > block.timestamp && newLocked.amount > 0) {
                uNew.slope = newLocked.amount / int256(MAXTIME);
                uNew.bias = uNew.slope * int256(newLocked.end - block.timestamp);
            }
            cpState.oldDslope = slopeChanges[oldLocked.end];
            if (newLocked.end != 0) {
                if (newLocked.end == oldLocked.end) {
                    cpState.newDslope = cpState.oldDslope;
                } else {
                    cpState.newDslope = slopeChanges[newLocked.end];
                }
            }
        }

        Point memory lastPoint = Point({bias: 0, slope: 0, timestamp: block.timestamp});
        if (cpState._epoch > 0) {
            lastPoint = pointHistory[cpState._epoch];
        }
        uint256 lastCheckPoint = lastPoint.timestamp;

        uint256 ti = (lastCheckPoint / WEEK) * WEEK;
        
        for (uint24 i = 0; i < 255; i ++) {
            ti += WEEK;
            int256 dSlope = 0;
            if (ti > block.timestamp) {
                ti = block.timestamp;
            } else {
                dSlope = slopeChanges[ti];
            }
            // ti >= lastCheckPoint
            
            lastPoint.bias -= lastPoint.slope * int256(ti - lastCheckPoint);
            lastPoint.slope += dSlope;
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            lastCheckPoint = ti;
            lastPoint.timestamp = ti;
            if (ti == block.timestamp) {
                cpState._epoch += 1;
                break;
            } else {
                if (dSlope != 0) {
                    // slope changes
                    cpState._epoch += 1;
                    pointHistory[cpState._epoch] = lastPoint;
                }
            }
        }

        epoch = cpState._epoch;

        if (nftId != 0) {
            lastPoint.slope += (uNew.slope - uOld.slope);
            lastPoint.bias += (uNew.bias - uOld.bias);
            if (lastPoint.slope < 0) {
                lastPoint.slope = 0;
            }
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }

        }

        pointHistory[cpState._epoch] = lastPoint;

        if (nftId != 0) {
            if (oldLocked.end > block.timestamp) {
                cpState.oldDslope += uOld.slope;
                if (newLocked.end == oldLocked.end) {
                    cpState.oldDslope -= uNew.slope;
                }
                slopeChanges[oldLocked.end] = cpState.oldDslope;
            }
            if (newLocked.end > block.timestamp) {
                if (newLocked.end > oldLocked.end) {
                    cpState.newDslope -= uNew.slope;
                    slopeChanges[newLocked.end] = cpState.newDslope;
                }
            }
            uint256 nftEpoch = nftPointEpoch[nftId] + 1;
            uNew.timestamp = block.timestamp;
            nftPointHistory[nftId][nftEpoch] = uNew;
            nftPointEpoch[nftId] = nftEpoch;
        }
        
    }

    function _depositFor(uint256 nftId, uint256 _value, uint256 unlockTime, LockedBalance memory lockedBalance, int128 depositType) internal {
        
        LockedBalance memory _locked = lockedBalance;
        uint256 supplyBefore = supply;

        supply = supplyBefore + _value;

        LockedBalance memory oldLocked = LockedBalance({amount: _locked.amount, end: _locked.end});

        _locked.amount += int256(_value);

        if (unlockTime != 0) {
            _locked.end = unlockTime;
        }
        _checkPoint(nftId, oldLocked, _locked);
        nftLocked[nftId] = _locked;
        if (_value != 0) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), _value);
        }
        emit Deposit(nftId, _value, _locked.end, depositType, block.timestamp);
        emit Supply(supplyBefore, supplyBefore + _value);
    }

    /// @notice update global curve status to current block
    function checkPoint() external {
        _checkPoint(0, LockedBalance({amount: 0, end: 0}), LockedBalance({amount: 0, end: 0}));
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        baseTokenURI = baseURI;
    }

    /// @notice create a new lock and generate a new nft
    /// @param _value amount of token to lock
    /// @param _unlockTime future timestamp to unlock
    /// @return nftId id of generated nft, starts from 1
    function createLock(uint256 _value, uint256 _unlockTime) external nonReentrant returns(uint256 nftId) {
        uint256 unlockTime = (_unlockTime / WEEK) * WEEK;
        nftNum ++;
        nftId = nftNum; // id starts from 1
        _mint(msg.sender, nftId);
        LockedBalance memory _locked = nftLocked[nftId];
        require(_value > 0, "Amount should >0");
        require(_locked.amount == 0, "Withdraw old tokens first");
        require(unlockTime > block.timestamp, "Can only lock until time in the future");
        require(unlockTime <= block.timestamp + MAXTIME, "Voting lock can be 4 years max");
        _depositFor(nftId, _value, unlockTime, _locked, CREATE_LOCK_TYPE);
    }

    /// @notice increase amount of locked token in an nft
    /// @param nftId id of nft, starts from 1
    /// @param _value increase amount
    function increaseAmount(uint256 nftId, uint256 _value) external nonReentrant {
        LockedBalance memory _locked = nftLocked[nftId];
        require(_value > 0, "Amount should >0");
        require(_locked.end > block.timestamp, "Can only lock until time in the future");
        _depositFor(nftId, _value, 0, _locked, (msg.sender == ownerOf(nftId) || stakedNft[msg.sender] == nftId) ? INCREASE_LOCK_AMOUNT : DEPOSIT_FOR_TYPE);
        if (stakingStatus[nftId].stakingId != 0) {
            _updateGlobalStatus();
            // this nft is staking
            // donot collect reward
            stakeiZiAmount += _value;
            stakingStatus[nftId].lockAmount += _value;
        }
    }

    /// @notice increase unlock time of an nft
    /// @param nftId id of nft
    /// @param _unlockTime future block number to unlock
    function increaseUnlockTime(uint256 nftId, uint256 _unlockTime) external checkAuth(nftId, true) nonReentrant {
        LockedBalance memory _locked = nftLocked[nftId];
        uint256 unlockTime = (_unlockTime / WEEK) * WEEK;

        require(unlockTime > _locked.end, "Can only increase unlock time");
        require(unlockTime > block.timestamp, "Can only lock until time in the future");
        require(unlockTime <= block.timestamp + MAXTIME, "Voting lock can be 4 years max");

        _depositFor(nftId, 0, unlockTime, _locked, INCREASE_UNLOCK_TIME);
        if (stakingStatus[nftId].stakingId != 0) {
            // this nft is staking
            address stakingOwner = stakedNftOwners[nftId];
            _collectReward(nftId, stakingOwner);
        }
    }

    /// @notice withdraw an unstaked-nft
    /// @param nftId id of nft
    function withdraw(uint256 nftId) external checkAuth(nftId, false) nonReentrant {
        LockedBalance memory _locked = nftLocked[nftId];
        require(block.timestamp >= _locked.end, "The lock didn't expire");
        uint256 value = uint256(_locked.amount);

        LockedBalance memory oldLocked = LockedBalance({amount: _locked.amount, end: _locked.end});
        _locked.end = 0;
        _locked.amount  = 0;
        nftLocked[nftId] = _locked;
        uint256 supplyBefore = supply;
        supply = supplyBefore - value;

        _checkPoint(nftId, oldLocked, _locked);
        IERC20(token).safeTransfer(msg.sender, value);

        emit Withdraw(nftId, value, block.timestamp);
        emit Supply(supplyBefore, supplyBefore - value);
    }

    /// @notice burn an unstaked-nft (dangerous!!!)
    /// @param nftId id of nft
    function burn(uint256 nftId) external checkAuth(nftId, false) nonReentrant {
        LockedBalance memory _locked = nftLocked[nftId];
        require(_locked.amount == 0, "Not Withdrawed!");
        _burn(nftId);
    }

    /// @notice merge nftFrom to nftTo
    /// @param nftFrom nft id of nftFrom, cannot be staked, owner must be msg.sender
    /// @param nftTo nft id of nftTo, cannot be staked, owner must be msg.sender
    function merge(uint256 nftFrom, uint256 nftTo) external nonReentrant {
        require(_isApprovedOrOwner(msg.sender, nftFrom), "Not Owner of nftFrom");
        require(_isApprovedOrOwner(msg.sender, nftTo), "Not Owner of nftTo");
        require(stakingStatus[nftFrom].stakingId == 0, "nftFrom is staked");
        require(stakingStatus[nftTo].stakingId == 0, "nftTo is staked");
        require(nftFrom != nftTo, 'Same nft!');

        LockedBalance memory lockedFrom = nftLocked[nftFrom];
        LockedBalance memory lockedTo = nftLocked[nftTo];
        require(lockedTo.end >= lockedFrom.end, "Endblock: nftFrom > nftTo");

        // cancel lockedFrom in the weight-curve
        _checkPoint(nftFrom, LockedBalance({amount: lockedFrom.amount, end: lockedFrom.end}), LockedBalance({amount: 0, end: lockedFrom.end}));

        // add locked iZi of nftFrom to nftTo
        _checkPoint(nftTo, LockedBalance({amount: lockedTo.amount, end: lockedTo.end}), LockedBalance({amount: lockedTo.amount + lockedFrom.amount, end: lockedTo.end}));
        nftLocked[nftFrom].amount = 0;
        nftLocked[nftTo].amount = lockedTo.amount + lockedFrom.amount;
    }

    function _findTimestampEpoch(uint256 _timestamp, uint256 maxEpoch) internal view returns(uint256) {
        uint256 _min = 0;
        uint256 _max = maxEpoch;
        for (uint24 i = 0; i < 128; i ++) {
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (pointHistory[_mid].timestamp <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function _findNftTimestampEpoch(uint256 nftId, uint256 _timestamp) internal view returns(uint256) {

        uint256 _min = 0;
        uint256 _max = nftPointEpoch[nftId];

        for (uint24 i = 0; i < 128; i ++) {
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (nftPointHistory[nftId][_mid].timestamp <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    /// @notice weight of nft (veiZi amount) at certain time after latest update of that nft
    /// @param nftId id of nft
    /// @param timestamp specified timestamp after latest update of this nft (amount change or end change)
    /// @return weight
    function nftVeiZi(uint256 nftId, uint256 timestamp) public view returns(uint256) {
        uint256 _epoch = nftPointEpoch[nftId];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory lastPoint = nftPointHistory[nftId][_epoch];
            require(timestamp >= lastPoint.timestamp, "Too early");
            lastPoint.bias -= lastPoint.slope * int256(timestamp - lastPoint.timestamp);
            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            return uint256(lastPoint.bias);
        }
    }
    
    /// @notice weight of nft (veiZi amount) at certain time
    /// @param nftId id of nft
    /// @param timestamp specified timestamp after latest update of this nft (amount change or end change)
    /// @return weight
    function nftVeiZiAt(uint256 nftId, uint256 timestamp) public view returns(uint256) {

        uint256 targetEpoch = _findNftTimestampEpoch(nftId, timestamp);
        Point memory uPoint = nftPointHistory[nftId][targetEpoch];
        if (timestamp < uPoint.timestamp) {
            return 0;
        }
        uPoint.bias -= uPoint.slope * (int256(timestamp) - int256(uPoint.timestamp));
        if (uPoint.bias < 0) {
            uPoint.bias = 0;
        }
        return uint256(uPoint.bias);
    }

    function _totalVeiZiAt(Point memory point, uint256 timestamp) internal view returns(uint256) {
        Point memory lastPoint = point;
        uint256 ti = (lastPoint.timestamp / WEEK) * WEEK;
        for (uint24 i = 0; i < 255; i ++) {
            ti += WEEK;
            int256 dSlope = 0;
            if (ti > timestamp) {
                ti = timestamp;
            } else {
                dSlope = slopeChanges[ti];
            }
            lastPoint.bias -= lastPoint.slope * int256(ti - lastPoint.timestamp);
            if (lastPoint.bias <= 0) {
                lastPoint.bias = 0;
                break;
            }
            if (ti == timestamp) {
                break;
            }
            lastPoint.slope += dSlope;
            lastPoint.timestamp = ti;
        }
        return uint256(lastPoint.bias);
    }

    /// @notice total weight of all nft at a certain time after check-point of all-nft-collection's curve
    /// @param timestamp specified blockNumber, "certain time" in above line
    /// @return total weight
    function totalVeiZi(uint256 timestamp) external view returns(uint256) {
        uint256 _epoch = epoch;
        Point memory lastPoint = pointHistory[_epoch];
        require(timestamp >= lastPoint.timestamp, "Too Early");
        return _totalVeiZiAt(lastPoint, timestamp);
    }

    /// @notice total weight of all nft at a certain time
    /// @param timestamp specified blockNumber, "certain time" in above line
    /// @return total weight
    function totalVeiZiAt(uint256 timestamp) external view returns(uint256) {
        uint256 _epoch = epoch;
        uint256 targetEpoch = _findTimestampEpoch(timestamp, _epoch);

        Point memory point = pointHistory[targetEpoch];
        if (timestamp < point.timestamp) {
            return 0;
        }
        if (targetEpoch == _epoch) {
            return _totalVeiZiAt(point, timestamp);
        } else {
            point.bias = point.bias - point.slope * (int256(timestamp) - int256(point.timestamp));
            if (point.bias < 0) {
                point.bias = 0;
            }
            return uint256(point.bias);
        }
    }

    function _updateStakingStatus(uint256 nftId) internal {
        StakingStatus storage t = stakingStatus[nftId];
        t.lastTouchBlock = rewardInfo.lastTouchBlock;
        t.lastTouchAccRewardPerShare = rewardInfo.accRewardPerShare;
        t.lastVeiZi = t.lockAmount / MAXTIME * (Math.max(block.timestamp, nftLocked[nftId].end) - block.timestamp);
    }

    /// @notice Collect pending reward for a single veizi-nft. 
    /// @param nftId The related position id.
    /// @param recipient who acquires reward
    function _collectReward(uint256 nftId, address recipient) internal {
        StakingStatus memory t = stakingStatus[nftId];
        
        _updateGlobalStatus();
        uint256 reward = (t.lastVeiZi * (rewardInfo.accRewardPerShare - t.lastTouchAccRewardPerShare)) / FixedPoints.Q128;
        if (reward > 0) {
            IERC20(token).safeTransferFrom(
                rewardInfo.provider,
                recipient,
                reward
            );
        }
        _updateStakingStatus(nftId);
    }

    function setDelegateAddress(uint256 nftId, address addr) external checkAuth(nftId, true) nonReentrant {
        delegateAddress[nftId] = addr;
    }

    function _beforeTokenTransfer(address from, address to, uint256 nftId) internal virtual override {
        super._beforeTokenTransfer(from, to, nftId);
        // when calling stake() or unStake() (to is contract address, or from is contract address)
        // delegateAddress will not change
        if (from != address(this) && to != address(this)) {
            delegateAddress[nftId] = address(0);
        }
    }

    /// @notice stake an nft
    /// @param nftId id of nft
    function stake(uint256 nftId) external nonReentrant {
        require(nftLocked[nftId].end > block.timestamp, "Lock expired");
        // nftId starts from 1, zero or not owner(including staked) cannot be transfered
        safeTransferFrom(msg.sender, address(this), nftId);
        require(stakedNft[msg.sender] == 0, "Has Staked!");

        _updateGlobalStatus();

        stakedNft[msg.sender] = nftId;
        stakedNftOwners[nftId] = msg.sender;

        stakeNum += 1;
        uint256 lockAmount = uint256(nftLocked[nftId].amount);
        stakingStatus[nftId] = StakingStatus({
            stakingId: stakeNum,
            lockAmount: lockAmount,
            lastVeiZi: lockAmount / MAXTIME * (Math.max(block.timestamp, nftLocked[nftId].end) - block.timestamp),
            lastTouchBlock: rewardInfo.lastTouchBlock,
            lastTouchAccRewardPerShare: rewardInfo.accRewardPerShare
        });
        stakeiZiAmount += lockAmount;

        emit Stake(nftId, msg.sender);
    }

    /// @notice unstake an nft
    function unStake() external nonReentrant {
        uint256 nftId = stakedNft[msg.sender];
        require(nftId != 0, "No Staked Nft!");
        stakingStatus[nftId].stakingId = 0;
        stakedNft[msg.sender] = 0;
        stakedNftOwners[nftId] = address(0);
        _collectReward(nftId, msg.sender);
        // refund nft
        // note we can not use safeTransferFrom here because the
        // opterator is msg.sender who is not approved
        _safeTransfer(address(this), msg.sender, nftId, "");

        stakeiZiAmount -= uint256(nftLocked[nftId].amount);
        emit Unstake(nftId, msg.sender);
    }

    /// @notice get user's staking info
    /// @param user address of user
    /// @return nftId id of veizi-nft
    /// @return stakingId id of stake
    /// @return amount amount of locked iZi in nft
    function stakingInfo(address user) external view returns(uint256 nftId, uint256 stakingId, uint256 amount) {
        nftId = stakedNft[user];
        if (nftId != 0) {
            stakingId = stakingStatus[nftId].stakingId;
            amount = uint256(nftLocked[nftId].amount);
            uint256 remainBlock = Math.max(nftLocked[nftId].end, block.timestamp) - block.timestamp;
            amount = amount / MAXTIME * remainBlock;
        } else {
            stakingId = 0;
            amount = 0;
        }
    }
    
    /// @notice Update the global status.
    function _updateGlobalStatus() internal {
        if (block.number <= rewardInfo.lastTouchBlock) {
            return;
        }
        if (rewardInfo.lastTouchBlock >= rewardInfo.endBlock) {
            return;
        }
        uint256 currBlockNumber = Math.min(block.number, rewardInfo.endBlock);
        if (stakeiZiAmount == 0) {
            rewardInfo.lastTouchBlock = currBlockNumber;
            return;
        }

        // tokenReward < 2^25 * 2^64 * 2^10, 15 years, 1000 r/block
        uint256 tokenReward = (currBlockNumber - rewardInfo.lastTouchBlock) * rewardInfo.rewardPerBlock;
        // tokenReward * Q128 < 2^(25 + 64 + 10 + 128)
        rewardInfo.accRewardPerShare = rewardInfo.accRewardPerShare + ((tokenReward * FixedPoints.Q128) / stakeiZiAmount);
        
        rewardInfo.lastTouchBlock = currBlockNumber;
    }

    /// @notice Return reward multiplier over the given _from to _to block.
    /// @param _from The start block.
    /// @param _to The end block.
    function _getRewardBlockNum(uint256 _from, uint256 _to)
        internal
        view
        returns (uint256)
    {
        if (_from > _to) {
            return 0;
        }
        if (_to <= rewardInfo.endBlock) {
            return _to - _from;
        } else if (_from >= rewardInfo.endBlock) {
            return 0;
        } else {
            return rewardInfo.endBlock - _from;
        }
    }

    /// @notice View function to see pending Reward for a staked NFT.
    /// @param nftId The staked NFT id.
    /// @return reward iZi reward amount
    function pendingRewardOfToken(uint256 nftId)
        public
        view
        returns (uint256 reward)
    {
        reward = 0;
        StakingStatus memory t = stakingStatus[nftId];
        if (t.stakingId != 0) {
            // we are sure that stakeiZiAmount is not 0
            uint256 tokenReward = _getRewardBlockNum(
                rewardInfo.lastTouchBlock,
                block.number
            ) * rewardInfo.rewardPerBlock;
            // we are sure that stakeiZiAmount >= t.lockAmount > 0
            uint256 rewardPerShare = rewardInfo.accRewardPerShare + (tokenReward * FixedPoints.Q128) / stakeiZiAmount;
            // l * (currentAcc - lastAcc)
            reward = (t.lastVeiZi * (rewardPerShare - t.lastTouchAccRewardPerShare)) / FixedPoints.Q128;
        }
    }

    /// @notice View function to see pending Reward for a user.
    /// @param user The related user address.
    /// @return reward iZi reward amount
    function pendingRewardOfAddress(address user)
        public
        view
        returns (uint256 reward)
    {
        reward = 0;
        uint256 nftId = stakedNft[user];
        if (nftId != 0) {
            reward = pendingRewardOfToken(nftId);
        }
    }

    /// @notice collect pending reward if some user has a staked veizi-nft
    function collect() external nonReentrant {
        uint256 nftId = stakedNft[msg.sender];
        require(nftId != 0, 'No Staked veizi-nft!');
        _collectReward(nftId, msg.sender);
    }


    /// @notice Set new reward end block.
    /// @param endBlock New end block.
    function modifyEndBlock(uint256 endBlock) external onlyOwner {
        require(endBlock > block.number, "OUT OF DATE");
        _updateGlobalStatus();
        // jump if origin endBlock < block.number
        rewardInfo.lastTouchBlock = block.number;
        rewardInfo.endBlock = endBlock;
    }

    /// @notice Set new reward per block.
    /// @param _rewardPerBlock new reward per block
    function modifyRewardPerBlock(uint256 _rewardPerBlock)
        external
        onlyOwner
    {
        _updateGlobalStatus();
        rewardInfo.rewardPerBlock = _rewardPerBlock;
    }

    function modifyStartBlock(uint256 startBlock) external onlyOwner {
        require(rewardInfo.startBlock > block.number, 'has started!');
        require(startBlock > block.number, 'Too Early!');
        require(startBlock < rewardInfo.endBlock, 'Too Late!');
        rewardInfo.startBlock = startBlock;
        rewardInfo.lastTouchBlock = startBlock; // before start, lastTouchBlock = max(block.number, startBlock)
    }


    /// @notice Set new reward provider.
    /// @param provider New provider
    function modifyProvider(address provider)
        external
        onlyOwner
    {
        rewardInfo.provider = provider;
    }
}