// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

// Note that this pool has no minter key of stars (rewards).
// Instead, the governance will call stars distributeReward method and send reward to this pool at the beginning.
contract Farm is Initializable, AccessControlUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant NFT_CONTROLLER = keccak256("NFT_CONTROLLER");

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Info of each pool.
    struct PoolInfo {
        IERC20Upgradeable token; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Stars to distribute per block.
        uint256 lastRewardTime; // Last time that stars distribution occurs.
        uint256 accStarsPerShare; // Accumulated stars per share, times 1e18. See below.
        bool isStarted; // if lastRewardTime has passed
        uint256 fee;
    }

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each NFT
    mapping(address => mapping(uint256 => uint256)) public nftBoostAmount;

    // Info of each user that stakes NFTs tokens.
    mapping(address => mapping(uint256 => mapping(address => uint256)))
        public nftDepositedAmount;
    mapping(address => uint256) public totalUserBoost;

    // Reward Token Info
    IERC20Upgradeable public stars;
    uint256 public stakedStars; // To track single staked stars

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    // The time when stars mining starts.
    uint256 public poolStartTime;

    // The time when stars mining ends.
    uint256 public poolEndTime;

    uint256 public starsPerSecond; // 94500 stars / (545 days * 24h * 60min * 60s)
    uint256 public constant TOTAL_REWARDS = 94500 ether;

    uint256 public baseBoost; // 28.5%
    uint256 public maxBoost; // 71.5%

    address public NFT;
    address public DAO;
    address public teamDistributor;

    uint256 public recycleReserve;
    uint256 public totalRecycled;
    uint256 public percentAllocatedToDao;
    uint256 public percentAllocatedToTeam;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event RewardPaid(address indexed user, uint256 amount);
    event ChangeDaoAddress(address indexed user, address indexed newAddress);

    event NFTDeposit(
        address indexed user,
        address indexed nftAddress,
        uint256 indexed tokenID,
        uint256 amount,
        uint256 boostAmount
    );

    event NFTWithdraw(
        address indexed user,
        address indexed nftAddress,
        uint256 indexed tokenID,
        uint256 amount,
        uint256 boostAmount
    );

    event FundDao(uint256 indexed amount);
    event FundTeam(uint256 amount);
    event Recycle(uint256 indexed amount);
    event RecycleReserved(uint256 indexed amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _stars,
        uint256 _poolStartTime,
        address _dao,
        address _nft,
        address _teamDistributor
    ) public initializer {
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(NFT_CONTROLLER, _nft);

        require(block.timestamp < _poolStartTime, "Can't start before funding");
        require(_stars != address(0), "Can't set to Zero Address");
        stars = IERC20Upgradeable(_stars);
        starsPerSecond = 0.002 ether; // 94500 stars / (545 days * 24h * 60min * 60s)
        poolStartTime = _poolStartTime;

        poolEndTime = poolStartTime;
        DAO = _dao;
        NFT = _nft;
        teamDistributor = _teamDistributor;

        percentAllocatedToDao = 8;
        percentAllocatedToTeam = 2;

        baseBoost = 28500; // 28.5
        maxBoost = 71500;
    }

    // Fund the farm, increase the end block
    function fund(uint256 _amount) public onlyRole(OPERATOR_ROLE) {
        require(block.timestamp < poolEndTime, "Can't fund after close");
        stars.safeTransferFrom(msg.sender, address(this), _amount);
        poolEndTime += _amount.div(starsPerSecond);
        calculateRecycleReserveAmount(
            _amount.sub(starsPerSecond.mul(_amount.div(starsPerSecond)))
        );
    }

    function recycle(uint256 _amount) internal {
        require(block.timestamp < poolEndTime, "Can't fund after close");
        totalRecycled += _amount;

        calculateRecycleReserveAmount(
            _amount.add(recycleReserve).sub(
                starsPerSecond.mul(recycleReserve.div(starsPerSecond))
            )
        );
        uint256 secondsToAdd = _amount.add(recycleReserve).div(starsPerSecond);
        if (secondsToAdd > 0) {
            poolEndTime += secondsToAdd;

            recycleReserve -= starsPerSecond.mul(
                recycleReserve.div(starsPerSecond)
            );
            emit Recycle(_amount);
        }
    }

    function calculateRecycleReserveAmount(uint256 _amount) internal {
        recycleReserve += _amount;
        emit RecycleReserved(_amount);
    }

    function checkPoolDuplicate(IERC20Upgradeable _token) internal view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(
                poolInfo[pid].token != _token,
                "StarsRewardPool: existing pool?"
            );
        }
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (_pid == 0) {
            tokenSupply = stakedStars;
        }

        if (tokenSupply == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        if (!pool.isStarted) {
            pool.isStarted = true;
            totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
        }
        if (totalAllocPoint > 0) {
            uint256 _generatedReward = getGeneratedReward(
                pool.lastRewardTime,
                block.timestamp
            );
            uint256 _starsReward = _generatedReward.mul(pool.allocPoint).div(
                totalAllocPoint
            );
            pool.accStarsPerShare = pool.accStarsPerShare.add(
                _starsReward.mul(1e18).div(tokenSupply)
            );
        }
        pool.lastRewardTime = block.timestamp;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IERC20Upgradeable _token,
        bool _withUpdate,
        uint256 _lastRewardTime,
        uint256 _fee
    ) public onlyRole(OPERATOR_ROLE) {
        require(_fee <= 100, "Fee must be less than or equal to 1%");
        checkPoolDuplicate(_token);
        if (_withUpdate) {
            massUpdatePools();
        }
        if (block.timestamp < poolStartTime) {
            // farm not started
            if (_lastRewardTime == 0 || _lastRewardTime < poolStartTime) {
                _lastRewardTime = poolStartTime;
            }
        } else {
            // farm already started
            if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
                _lastRewardTime = block.timestamp;
            }
        }
        bool _isStarted = (_lastRewardTime <= poolStartTime) ||
            (_lastRewardTime <= block.timestamp);
        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                lastRewardTime: _lastRewardTime,
                accStarsPerShare: 0,
                isStarted: _isStarted,
                fee: _fee
            })
        );
        if (_isStarted) {
            totalAllocPoint = totalAllocPoint.add(_allocPoint);
        }
    }

    // Update the given pool's stars allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint256 _fee
    ) public onlyRole(OPERATOR_ROLE) {
        require(_fee <= 100, "Fee must be less than or equal to 1%");
        massUpdatePools();
        PoolInfo storage pool = poolInfo[_pid];
        if (pool.isStarted) {
            totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(
                _allocPoint
            );
        }
        pool.fee = _fee;
        pool.allocPoint = _allocPoint;
    }

    // View function to see deposited LP for a user.
    function deposited(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_pid][_user];
        return user.amount;
    }

    // Return accumulate rewards over the given _from to _to block.
    function getGeneratedReward(uint256 _fromTime, uint256 _toTime)
        public
        view
        returns (uint256)
    {
        if (_fromTime >= _toTime) {
            return 0;
        }
        if (_toTime >= poolEndTime) {
            if (_fromTime >= poolEndTime) {
                return 0;
            }
            if (_fromTime <= poolStartTime) {
                return poolEndTime.sub(poolStartTime).mul(starsPerSecond);
            }

            return poolEndTime.sub(_fromTime).mul(starsPerSecond);
        } else {
            if (_toTime <= poolStartTime) {
                return 0;
            }
            if (_fromTime <= poolStartTime) {
                return _toTime.sub(poolStartTime).mul(starsPerSecond);
            }

            return _toTime.sub(_fromTime).mul(starsPerSecond);
        }
    }

    // View function to see pending stars on frontend.
    function pendingShare(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accStarsPerShare = pool.accStarsPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (_pid == 0) {
            tokenSupply = stakedStars;
        }
        if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
            uint256 _generatedReward = getGeneratedReward(
                pool.lastRewardTime,
                block.timestamp
            );

            uint256 _starsReward = _generatedReward.mul(pool.allocPoint).div(
                totalAllocPoint
            );

            accStarsPerShare = accStarsPerShare.add(
                _starsReward.mul(1e18).div(tokenSupply)
            );
        }
        uint256 pendingBeforeDeductions = user
            .amount
            .mul(accStarsPerShare)
            .div(1e18)
            .sub(user.rewardDebt);

        uint256 flatProtocolDeduction = pendingBeforeDeductions.div(10);
        uint256 pendingAmount = pendingBeforeDeductions - flatProtocolDeduction;
        uint256 userBoost = totalUserBoost[msg.sender]; // 28500 | 28.5
        if (userBoost >= maxBoost) {
            userBoost = maxBoost;
        }

        uint256 updatedBase = baseBoost + userBoost; // 57000 | 57

        uint256 amountAfterBoostCalc = pendingAmount.mul(updatedBase).div(
            100000
        );

        return amountAfterBoostCalc;
    }

    // Deposit LP tokens.
    function deposit(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pendingAmount = user
                .amount
                .mul(pool.accStarsPerShare)
                .div(1e18)
                .sub(user.rewardDebt);

            if (pendingAmount > 0) {
                uint256 daoShare = pendingAmount.mul(percentAllocatedToDao).div(
                    100
                );
                uint256 TeamShare = pendingAmount
                    .mul(percentAllocatedToTeam)
                    .div(100);

                safeStarsTransfer(DAO, daoShare);
                emit FundDao(daoShare);
                safeStarsTransfer(teamDistributor, TeamShare);
                emit FundTeam(TeamShare);

                pendingAmount -= daoShare + TeamShare;

                uint256 userBoost = totalUserBoost[msg.sender]; // 28500 | 28.5
                // console.log("Deposit User Boost", userBoost);
                if (userBoost >= maxBoost) {
                    userBoost = maxBoost;
                }

                uint256 updatedBase = baseBoost + userBoost; // 57000 | 57

                uint256 amountAfterBoostCalc = pendingAmount
                    .mul(updatedBase)
                    .div(100000);
                safeStarsTransfer(_sender, amountAfterBoostCalc);
                emit RewardPaid(_sender, amountAfterBoostCalc);

                pendingAmount -= amountAfterBoostCalc;

                if (pendingAmount > 0 && block.timestamp < poolEndTime) {
                    recycle(pendingAmount);
                }
            }
        }
        if (_amount > 0) {
            uint256 fee = _amount.mul(pool.fee).div(10000);
            pool.token.safeTransferFrom(_sender, address(this), _amount);
            if (_pid == 0) {
                stakedStars += _amount;
            }
            if (fee > 0) {
                pool.token.transfer(DAO, fee);
            }
            user.amount = user.amount.add(_amount - fee);
        }
        user.rewardDebt = user.amount.mul(pool.accStarsPerShare).div(1e18);
        emit Deposit(_sender, _pid, _amount);
    }

    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public {
        address _sender = msg.sender;
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_sender];
        require(
            user.amount >= _amount,
            "withdraw: can't withdraw more than deposit"
        );
        updatePool(_pid);

        uint256 pendingAmount = user
            .amount
            .mul(pool.accStarsPerShare)
            .div(1e18)
            .sub(user.rewardDebt);

        if (pendingAmount > 0) {
            uint256 daoShare = pendingAmount.mul(percentAllocatedToDao).div(
                100
            );
            uint256 TeamShare = pendingAmount.mul(percentAllocatedToTeam).div(
                100
            );

            safeStarsTransfer(DAO, daoShare);
            emit FundDao(daoShare);
            safeStarsTransfer(teamDistributor, TeamShare);
            emit FundTeam(TeamShare);

            pendingAmount -= daoShare + TeamShare;

            uint256 userBoost = totalUserBoost[msg.sender]; // 28500 | 28.5
            if (userBoost >= maxBoost) {
                userBoost = maxBoost;
            }

            uint256 updatedBase = baseBoost + userBoost; // 57000 | 57

            uint256 amountAfterBoostCalc = pendingAmount.mul(updatedBase).div(
                100000
            );

            safeStarsTransfer(_sender, amountAfterBoostCalc);
            emit RewardPaid(_sender, amountAfterBoostCalc);

            pendingAmount -= amountAfterBoostCalc;

            if (pendingAmount > 0 && block.timestamp < poolEndTime) {
                recycle(pendingAmount);
            }
        }
        if (_amount > 0) {
            if (_pid == 0) {
                stakedStars -= _amount;
            }
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(_sender, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accStarsPerShare).div(1e18);

        emit Withdraw(_sender, _pid, _amount);
    }

    modifier massClaim(address _user) {
        for (uint pid = 0; pid < poolInfo.length; pid++) {
            UserInfo storage user = userInfo[pid][_user];
            if (user.amount > 0) {
                PoolInfo storage pool = poolInfo[pid];

                updatePool(pid);

                uint256 pendingAmount = user
                    .amount
                    .mul(pool.accStarsPerShare)
                    .div(1e18)
                    .sub(user.rewardDebt);

                uint256 daoShare = pendingAmount.mul(percentAllocatedToDao).div(
                    100
                );
                uint256 TeamShare = pendingAmount
                    .mul(percentAllocatedToTeam)
                    .div(100);

                safeStarsTransfer(DAO, daoShare);
                emit FundDao(daoShare);
                safeStarsTransfer(teamDistributor, TeamShare);
                emit FundTeam(TeamShare);

                pendingAmount -= daoShare + TeamShare;

                uint256 userBoost = totalUserBoost[_user]; // 28500 | 28.5

                if (userBoost >= maxBoost) {
                    userBoost = maxBoost;
                }

                uint256 updatedBase = baseBoost + userBoost; // 57000 | 57

                uint256 amountAfterBoostCalc = pendingAmount
                    .mul(updatedBase)
                    .div(100000);

                safeStarsTransfer(_user, amountAfterBoostCalc);

                pendingAmount -= amountAfterBoostCalc;

                if (pendingAmount > 0 && block.timestamp < poolEndTime) {
                    recycle(pendingAmount);
                }
                if (pid == 0) {
                    stakedStars -= 0;
                }

                user.rewardDebt = user.amount.mul(pool.accStarsPerShare).div(
                    1e18
                );

                emit Withdraw(msg.sender, pid, 0);
            }
        }

        _;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 _amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(msg.sender, _amount);
        emit EmergencyWithdraw(msg.sender, _pid, _amount);
    }

    // Safe stars transfer function, just in case if rounding error causes pool to not have enough stars.
    function safeStarsTransfer(address _to, uint256 _amount) internal {
        uint256 _starsBal = stars.balanceOf(address(this));
        if (_starsBal > 0) {
            if (_amount > _starsBal) {
                stars.safeTransfer(_to, _starsBal);
            } else {
                stars.safeTransfer(_to, _amount);
            }
        }
    }

    // NFT Logic

    function setNFT(
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _newBoostAmount
    ) public onlyRole(NFT_CONTROLLER) {
        require(_newBoostAmount <= maxBoost, "Boost too high");
        nftBoostAmount[_tokenAddress][_tokenId] = _newBoostAmount;
    }

    function depositNFT(
        address _user,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount
    ) public massClaim(_user) onlyRole(NFT_CONTROLLER) {
        require(nftBoostAmount[_tokenAddress][_tokenId] > 0, "Ineligible NFT");

        nftDepositedAmount[_tokenAddress][_tokenId][_user] += _amount;
        totalUserBoost[_user] +=
            nftBoostAmount[_tokenAddress][_tokenId] *
            _amount;

        emit NFTDeposit(
            _user,
            _tokenAddress,
            _tokenId,
            _amount,
            nftBoostAmount[_tokenAddress][_tokenId]
        );
    }

    function withdrawNFT(
        address _user,
        address _tokenAddress,
        uint256 _tokenId,
        uint256 _amount
    ) public massClaim(_user) onlyRole(NFT_CONTROLLER) {
        require(
            nftDepositedAmount[_tokenAddress][_tokenId][_user] >= _amount,
            "You don't have this many deposited"
        );

        nftDepositedAmount[_tokenAddress][_tokenId][_user] -= _amount;
        totalUserBoost[_user] -=
            nftBoostAmount[_tokenAddress][_tokenId] *
            _amount;

        emit NFTWithdraw(
            _user,
            _tokenAddress,
            _tokenId,
            _amount,
            nftBoostAmount[_tokenAddress][_tokenId]
        );
    }

    // Operator Functions

    function changeDaoAddress(address _DAOAddress)
        public
        onlyRole(OPERATOR_ROLE)
    {
        DAO = _DAOAddress;
        emit ChangeDaoAddress(msg.sender, _DAOAddress);
    }

    function changeAllocations(uint256 _newDao, uint256 _newTeam)
        public
        onlyRole(OPERATOR_ROLE)
    {
        require(_newDao < 50, "More than 50%");
        require(_newTeam < 50, "More than 50%");
        percentAllocatedToDao = _newDao;
        percentAllocatedToTeam = _newTeam;
    }

    function changeBoostMinMax(uint256 _newMin, uint256 _newMax)
        public
        onlyRole(OPERATOR_ROLE)
    {
        require(_newMin < 100000, "Can't be higher than 100%");
        require(_newMax < 100000, "Can't be higher than 100%");
        baseBoost = _newMin;
        maxBoost = _newMax;
    }

    function governanceRecoverUnsupported(
        IERC20Upgradeable _token,
        uint256 amount,
        address to
    ) external onlyRole(OPERATOR_ROLE) {
        if (block.timestamp < poolEndTime + 90 days) {
            // do not allow to drain core token (stars or lps) if less than 90 days after pool ends
            require(_token != stars, "stars");
            uint256 length = poolInfo.length;
            for (uint256 pid = 0; pid < length; ++pid) {
                PoolInfo storage pool = poolInfo[pid];
                require(_token != pool.token, "pool.token");
            }
        }
        _token.safeTransfer(to, amount);
    }
}