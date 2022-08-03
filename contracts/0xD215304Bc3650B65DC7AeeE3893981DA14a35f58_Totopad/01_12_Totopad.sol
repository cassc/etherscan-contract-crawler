// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Fund raising platform facilitated by launch pool
 * @author Rock`N`Block
 * @notice Fork of LaunchPool
 * @dev Only only
 */
contract Totopad is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    uint256 private constant TOTAL_TOKEN_ALLOCATION_POINTS = (100 * (10**18));

    IERC20 public immutable stakingToken;
    IERC20 public immutable fundingToken;

    PoolInfo[] public poolInfo;
    ProjectInfo[] public projectInfo;

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => address) public projectOwner;

    struct UserInfo {
        uint256 amount;
        uint256 fundingAmount;
        uint256 rewardDebt;
        uint256 tokenAllocDebt;
    }

    struct PoolInfo {
        uint256 maxStakingAmountPerUser;
        uint256 lastAllocTime;
        uint256 accPercentPerShare;
        uint256 rewardAmount;
        uint256 targetRaise;
        uint256 totalStaked;
        uint256 totalRaised;
    }

    struct ProjectInfo {
        IERC20 rewardToken;
        uint256 allocStartTime;
        uint256 stakingEndTime;
        uint256 fundingEndTime;
        uint256 rewardStopTime;
        uint256 totalRaised;
        uint256 softCap;
        bool fundsClaimed;
        bool isActive;
    }

    event ProjectCreate(uint256 pid);
    event ProjectStatusChanges(uint256 pid, bool isAccepted);
    event Pledge(address indexed user, uint256 pid, uint256 amount);
    event PledgeFunded(address indexed user, uint256 pid, uint256 amount);
    event Withdraw(address indexed user, uint256 pid, uint256 amount);
    event FundClaimed(address indexed user, uint256 projectId, uint256 amount);
    event RewardClaimed(address indexed user, uint256 pid, uint256 amount);
    event RewardWithdraw(
        address indexed user,
        uint256 projectId,
        uint256 amount
    );

    /**
     * @notice Constructor that creates reward guild band and set staking token
     * @param _stakingToken totoro staking token
     */
    constructor(IERC20 _stakingToken, IERC20 _fundingToken, address _owner) {
        require(address(_stakingToken) != address(0), "zero address error");
        require(address(_fundingToken) != address(0), "zero address error");

        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        stakingToken = _stakingToken;
        fundingToken = _fundingToken;
    }

    /**
     * @notice Function for adding new project
     * @dev Creates 3 pools
     * @param _rewardToken reward token address
     * @param _projectOwner project owner
     * @param _allocStartTime allocation start time
     * @param _stakingEndTime allocation stop time
     * @param _fundingEndTime funding stop time
     * @param _rewardStopTime reward stop time
     * @param _rewardAmounts reward amounts for 3 pools
     * @param _targetRaises target raise for 3 pools
     * @param _softcap general soft cap for project
     */
    function add(
        IERC20 _rewardToken,
        address _projectOwner,
        uint256 _allocStartTime,
        uint256 _stakingEndTime,
        uint256 _fundingEndTime,
        uint256 _rewardStopTime,
        uint256[3] calldata _rewardAmounts,
        uint256[3] calldata _targetRaises,
        uint256 _softcap
    ) external nonReentrant {
        require(address(_rewardToken) != address(0), "zero address error");
        require(address(_projectOwner) != address(0), "zero address error");
        require(block.timestamp <= _allocStartTime, "time in past");
        require(_allocStartTime < _stakingEndTime, "alloc must be before fund");
        require(
            _stakingEndTime < _fundingEndTime,
            "fund must be before reward"
        );
        require(
            _fundingEndTime < _rewardStopTime,
            "reward start must be before stop"
        );

        require(_softcap > 0, "add: Invalid soft cap");

        poolInfo.push(
            PoolInfo({
                lastAllocTime: _allocStartTime,
                maxStakingAmountPerUser: 250 * 1e18,
                accPercentPerShare: 0,
                rewardAmount: _rewardAmounts[0],
                targetRaise: _targetRaises[0],
                totalStaked: 0,
                totalRaised: 0
            })
        );

        poolInfo.push(
            PoolInfo({
                lastAllocTime: _allocStartTime,
                maxStakingAmountPerUser: 1000 * 1e18,
                accPercentPerShare: 0,
                rewardAmount: _rewardAmounts[1],
                targetRaise: _targetRaises[1],
                totalStaked: 0,
                totalRaised: 0
            })
        );

        poolInfo.push(
            PoolInfo({
                lastAllocTime: _allocStartTime,
                maxStakingAmountPerUser: type(uint256).max,
                accPercentPerShare: 0,
                rewardAmount: _rewardAmounts[2],
                targetRaise: _targetRaises[2],
                totalStaked: 0,
                totalRaised: 0
            })
        );

        projectInfo.push(
            ProjectInfo({
                rewardToken: _rewardToken,
                allocStartTime: _allocStartTime,
                stakingEndTime: _stakingEndTime,
                fundingEndTime: _fundingEndTime,
                rewardStopTime: _rewardStopTime,
                totalRaised: 0,
                softCap: _softcap,
                fundsClaimed: false,
                isActive: false
            })
        );

        projectOwner[projectInfo.length - 1] = _projectOwner;

        uint256 rewardAmount = _rewardAmounts[0] +
            _rewardAmounts[1] +
            _rewardAmounts[2];
        _rewardToken.safeTransferFrom(
            _msgSender(),
            address(this),
            rewardAmount
        );

        emit ProjectCreate(projectInfo.length - 1);
    }

    function changeProjectStatus(uint256 projectId, bool isAccept)
        external
        nonReentrant
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(projectId < projectInfo.length, "Invalid project id");

        ProjectInfo storage project = projectInfo[projectId];
        require(project.isActive == false, "Already accepted");
        if (isAccept) {
            require(projectInfo[projectId].softCap > 0, "Already declined");
            projectInfo[projectId].isActive = true;
            if (block.timestamp > project.allocStartTime) {
                uint256 oldStartTime = project.allocStartTime;
                uint256 newStartTime = block.timestamp + 1 days;

                project.allocStartTime = newStartTime;
                project.stakingEndTime =
                    newStartTime +
                    (project.stakingEndTime - oldStartTime);
                project.fundingEndTime =
                    newStartTime +
                    (project.fundingEndTime - oldStartTime);
                project.rewardStopTime =
                    newStartTime +
                    (project.rewardStopTime - oldStartTime);

                poolInfo[projectId * 3].lastAllocTime = newStartTime;
                poolInfo[projectId * 3 + 1].lastAllocTime = newStartTime;
                poolInfo[projectId * 3 + 2].lastAllocTime = newStartTime;
            }
        } else {
            uint256 rewardAmount = poolInfo[projectId * 3].rewardAmount +
                poolInfo[projectId * 3 + 1].rewardAmount +
                poolInfo[projectId * 3 + 2].rewardAmount;
            require(rewardAmount > 0, "Already declined");
            projectInfo[projectId].rewardToken.safeTransfer(
                projectOwner[projectId],
                rewardAmount
            );

            delete projectInfo[projectId];
            delete poolInfo[projectId * 3];
            delete poolInfo[projectId * 3 + 1];
            delete poolInfo[projectId * 3 + 2];
        }

        emit ProjectStatusChanges(projectId, isAccept);
    }

    //|-----------------------|
    //| Stake platform tokens |
    //|-----------------------|

    /**
     * @notice Staking totoro token for acquiring token allocation
     * @param _pid pool id
     * @param _amount amount to fund
     */
    function pledge(uint256 _pid, uint256 _amount) external nonReentrant {
        require(_pid < poolInfo.length, "pledge: Invalid PID");
        require(_amount > 0, "pledge: No pledge specified");
        require(projectInfo[_pid / 3].isActive, "Non active project");

        address sender = _msgSender();
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][sender];

        require(
            user.amount + _amount <= pool.maxStakingAmountPerUser,
            "amount exeeds limits"
        );
        require(
            block.timestamp <= projectInfo[_pid / 3].stakingEndTime,
            "allocation already ends"
        );

        updatePool(_pid);

        user.amount += _amount;
        user.tokenAllocDebt += (_amount * pool.accPercentPerShare) / 1e18;

        pool.totalStaked += _amount;

        stakingToken.safeTransferFrom(sender, address(this), _amount);

        emit Pledge(sender, _pid, _amount);
    }

    //|--------------------|
    //| Buyback allocation |
    //|--------------------|

    /**
     * @notice Fund pledge
     * @param _pid pid address
     */
    function fundPledge(uint256 _pid) external nonReentrant {
        require(_pid < poolInfo.length, "fundPledge: Invalid PID");
        require(projectInfo[_pid / 3].isActive, "Non active project");

        updatePool(_pid);

        address sender = _msgSender();
        ProjectInfo storage project = projectInfo[_pid / 3];
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][sender];

        require(user.fundingAmount == 0, "Already funded");
        require(
            block.timestamp > project.stakingEndTime &&
                block.timestamp <= project.fundingEndTime,
            "Not required time"
        );
        require(getPledgeFundingAmount(_pid, sender) > 0, "Cant fund");

        uint256 fundingAmount = getPledgeFundingAmount(_pid, sender);

        user.fundingAmount = fundingAmount;
        pool.totalRaised += fundingAmount;
        project.totalRaised += fundingAmount;

        fundingToken.safeTransferFrom(sender, address(this), fundingAmount);
        stakingToken.safeTransfer(sender, user.amount);

        emit PledgeFunded(sender, _pid, fundingAmount);
    }

    //|---------------------------------------------------------------------------|
    //| Withdraw stakeToken for non-funders or fundToken when softcap not reached |
    //|---------------------------------------------------------------------------|

    /**
     * @notice Withdraw function for non-funders
     * @param _pid pool id
     */
    function withdraw(uint256 _pid) external nonReentrant {
        require(_pid < poolInfo.length, "withdraw: invalid _pid");
        require(projectInfo[_pid / 3].isActive, "Non active project");

        address sender = _msgSender();
        UserInfo memory user = userInfo[_pid][sender];
        ProjectInfo memory project = projectInfo[_pid / 3];

        require(user.amount > 0, "No stake to withdraw");
        require(
            block.timestamp > project.fundingEndTime,
            "withdraw: Not yet permitted"
        );

        uint256 withdrawAmount;
        IERC20 withdrawToken;

        if (user.fundingAmount == 0) {
            withdrawAmount = user.amount;
            withdrawToken = stakingToken;
        } else {
            require(project.totalRaised < project.softCap, "Softcap reached");

            withdrawAmount = user.fundingAmount;
            withdrawToken = fundingToken;
        }

        delete userInfo[_pid][sender];
        withdrawToken.safeTransfer(sender, withdrawAmount);

        emit Withdraw(sender, _pid, withdrawAmount);
    }

    //|---------------------------------------------------------------------------|
    //| Withdraw reward when softcap not reached |
    //|---------------------------------------------------------------------------|

    function withdrawReward(uint256 projectId) external nonReentrant {
        require(projectId < projectInfo.length, "Invalid project id");
        ProjectInfo memory project = projectInfo[projectId];
        require(project.isActive, "Non active project");

        require(
            projectOwner[projectId] == _msgSender(),
            "Not allowed to withdraw"
        );
        require(block.timestamp > project.fundingEndTime, "Not yet");
        require(project.totalRaised < project.softCap, "Softcap reached");

        uint256 rewardCollect;
        for (uint256 i = 0; i < 3; ) {
            rewardCollect += poolInfo[projectId * 3 + i].rewardAmount;
            poolInfo[projectId].rewardAmount = 0;
            unchecked {
                ++i;
            }
        }
        require(rewardCollect > 0, "Already withdraw");
        project.rewardToken.safeTransfer(_msgSender(), rewardCollect);

        emit RewardWithdraw(_msgSender(), projectId, rewardCollect);
    }

    //|---------------------------------|
    //| Claim reward if softcap reached |
    //|---------------------------------|

    function claimReward(uint256 _pid) external nonReentrant {
        require(_pid < poolInfo.length, "Invalid pid");
        require(projectInfo[_pid / 3].isActive, "Non active project");

        address sender = _msgSender();
        ProjectInfo memory project = projectInfo[_pid / 3];
        UserInfo storage user = userInfo[_pid][sender];

        require(block.timestamp > project.fundingEndTime, "Not yet");
        require(project.totalRaised >= project.softCap, "Softcap not reached");

        uint256 pending = pendingRewards(_pid, sender);

        if (pending > 0) {
            user.rewardDebt += pending;

            project.rewardToken.safeTransfer(sender, pending);
        }

        emit RewardClaimed(sender, _pid, pending);
    }

    //|--------------------------------------|
    //| Claim fund raised if softcap reached |
    //|--------------------------------------|

    /**
     * @notice Claim all funds and reward for owner
     */
    function claimFundRaising(uint256 projectId) external nonReentrant {
        require(projectId < projectInfo.length, "Invalid project id");

        ProjectInfo storage project = projectInfo[projectId];
        require(project.isActive, "Non active project");
        require(
            projectOwner[projectId] == _msgSender(),
            "Not allowed to claim"
        );
        require(block.timestamp > project.fundingEndTime, "Not yet");
        require(project.totalRaised >= project.softCap, "Not enough :( ");
        require(!project.fundsClaimed, "Already claimed");

        project.fundsClaimed = true;
        fundingToken.safeTransfer(_msgSender(), project.totalRaised);
        uint256 rewardExcess;
        for (uint256 i = 0; i < 3; ) {
            PoolInfo memory pool = poolInfo[projectId  * 3 + i];
            if (pool.totalRaised == 0) {
                rewardExcess += pool.rewardAmount;
            } else {
                rewardExcess +=
                    (pool.rewardAmount *
                        (pool.targetRaise - pool.totalRaised)) /
                    pool.targetRaise;
            }
            unchecked {
                ++i;
            }
        }
        if (rewardExcess > 0) {
            project.rewardToken.safeTransfer(
                projectOwner[projectId],
                rewardExcess
            );
        }
        emit FundClaimed(_msgSender(), projectId, project.totalRaised);
    }

    function getProjectCounts() external view returns (uint256) {
        return projectInfo.length;
    }

    /**
     * @notice Mass update pools
     */
    function massUpdatePools() public {
        for (uint256 pid = 0; pid < poolInfo.length; pid++) {
            updatePool(pid);
        }
    }

    /**
     * @notice Update pools variable
     * @dev Changes accPercentPerShare and lastAllocTime
     * @param _pid pool id
     */
    function updatePool(uint256 _pid) public {
        require(_pid < poolInfo.length, "updatePool: invalid _pid");
        require(projectInfo[_pid / 3].isActive, "Non active project");

        ProjectInfo memory project = projectInfo[_pid / 3];
        PoolInfo storage pool = poolInfo[_pid];

        // staking not started
        if (block.timestamp < project.allocStartTime) {
            return;
        }

        if (pool.totalStaked == 0) {
            pool.lastAllocTime = block.timestamp;
            return;
        }

        uint256 maxEndTimeAlloc = block.timestamp <= project.stakingEndTime
            ? block.timestamp
            : project.stakingEndTime;
        uint256 timeSinceAlloc = getMultiplier(
            pool.lastAllocTime,
            maxEndTimeAlloc
        );

        if (timeSinceAlloc > 0) {
            (
                uint256 accPercentPerShare,
                uint256 lastAllocTime
            ) = getAccPerShareAlloc(_pid);
            pool.accPercentPerShare = accPercentPerShare;
            pool.lastAllocTime = lastAllocTime;
        }
    }

    /**
     * @notice Calculate funding amount
     * @dev 1. Get currentAccPerShare
     *      2. Calculate userPercentAlloc = amount * currentAccPerShare / 1e18 - tokenAllocDebt
     *      3. Return userPercentAlloc * targetRaise / totalAllocPoint
     * @param _pid pool id
     * @return funding amount
     */
    function getPledgeFundingAmount(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        require(_pid < poolInfo.length, "Invalid pid");
        require(projectInfo[_pid / 3].isActive, "Non active project");

        UserInfo memory user = userInfo[_pid][_user];

        (uint256 accPercentPerShare, ) = getAccPerShareAlloc(_pid);

        uint256 userPercentAlloc = (user.amount * accPercentPerShare) /
            1e18 -
            user.tokenAllocDebt;
        return
            (userPercentAlloc * poolInfo[_pid].targetRaise) /
            TOTAL_TOKEN_ALLOCATION_POINTS;
    }

    /**
     * @notice Calculate pending reward
     * @param _pid pool id
     * @param _user address user
     * @return pending reward
     */
    function pendingRewards(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        require(_pid < poolInfo.length);
        require(projectInfo[_pid / 3].isActive, "Non active project");

        UserInfo memory user = userInfo[_pid][_user];
        ProjectInfo memory project = projectInfo[_pid / 3];
        PoolInfo memory pool = poolInfo[_pid];

        if (
            user.fundingAmount == 0 || block.timestamp < project.fundingEndTime
        ) {
            return 0;
        }

        uint256 endRewardTime = block.timestamp <= project.rewardStopTime
            ? block.timestamp
            : project.rewardStopTime;
        uint256 timePass = endRewardTime - project.fundingEndTime;
        uint256 rewardDuration = project.rewardStopTime -
            project.fundingEndTime;

        return
            (pool.rewardAmount * user.fundingAmount * timePass) /
            rewardDuration /
            pool.targetRaise -
            user.rewardDebt;
    }

    // Calculate percent unlocked after previous update pool. Cumulative accPercent + percent * 1e18 / totalStaked
    function getAccPerShareAlloc(uint256 _pid)
        internal
        view
        returns (uint256, uint256)
    {
        ProjectInfo memory project = projectInfo[_pid / 3];
        PoolInfo memory pool = poolInfo[_pid];

        uint256 stakingDuration = project.stakingEndTime -
            project.allocStartTime;
        uint256 allocAvailPerSec = TOTAL_TOKEN_ALLOCATION_POINTS /
            stakingDuration;

        uint256 maxEndTimeAlloc = block.timestamp <= project.stakingEndTime
            ? block.timestamp
            : project.stakingEndTime;
        uint256 timeSinceAlloc = getMultiplier(
            pool.lastAllocTime,
            maxEndTimeAlloc
        );
        uint256 percentUnlocked = timeSinceAlloc * allocAvailPerSec;

        return (
            pool.accPercentPerShare +
                (percentUnlocked * 1e18) /
                pool.totalStaked,
            maxEndTimeAlloc
        );
    }

    function getMultiplier(uint256 _from, uint256 _to)
        private
        pure
        returns (uint256)
    {
        return _to - _from;
    }
}