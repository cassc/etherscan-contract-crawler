// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../interfaces/IMultiFeeDistribution.sol";
import "../interfaces/IOnwardIncentivesController.sol";
import "../dependencies/openzeppelin/contracts/IERC20.sol";
import "../dependencies/openzeppelin/contracts/SafeERC20.sol";
import "../dependencies/openzeppelin/contracts/SafeMath.sol";
import "../dependencies/openzeppelin/contracts/Ownable.sol";
import "../dependencies/openzeppelin/contracts/ReentrancyGuard.sol";

// based on the Sushi MasterChef
// https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }
    // Info of each pool.
    struct PoolInfo {
        uint256 allocPoint; // How many allocation points assigned to this pool.
        uint256 lastRewardTime; // Last second that reward distribution occurs.
        uint256 accRewardPerShare; // Accumulated rewards per share, times ACC_SHARE_PRECISION. See below.
        IOnwardIncentivesController onwardIncentives;
    }
    // Info about token emissions for a given time period.
    struct EmissionPoint {
        uint128 startTimeOffset;
        uint128 rewardsPerSecond;
    }

    address public immutable poolConfigurator;

    IMultiFeeDistribution public immutable rewardMinter;
    uint256 public rewardsPerSecond;
    uint256 public immutable maxMintableTokens;
    uint256 public mintedTokens;

    // Info of each pool.
    address[] public registeredTokens;
    mapping(address => PoolInfo) public poolInfo;

    // Data about the future reward rates. emissionSchedule stored in reverse chronological order,
    // whenever the number of blocks since the start block exceeds the next block offset a new
    // reward rate is applied.
    EmissionPoint[] public emissionSchedule;
    // token => user => Info of each user that stakes LP tokens.
    mapping(address => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when reward mining starts.
    uint256 public startTime;
    // accurrate share pricision
    uint256 public constant ACC_SHARE_PRECISION = 1e18;

    // account earning rewards => receiver of rewards for this account
    // if receiver is set to address(0), rewards are paid to the earner
    // this is used to aid 3rd party contract integrations
    mapping (address => address) public claimReceiver;

    event Deposit(
        address indexed token,
        address indexed user,
        uint256 amount
    );

    event Withdraw(
        address indexed token,
        address indexed user,
        uint256 amount
    );

    event EmergencyWithdraw(
        address indexed token,
        address indexed user,
        uint256 amount
    );

    event PoolAdded(
        address token,
        uint256 alloc
    );

    constructor(
        uint128[] memory _startTimeOffset,
        uint128[] memory _rewardsPerSecond,
        address _poolConfigurator,
        IMultiFeeDistribution _rewardMinter,
        uint256 _maxMintable
    )
        Ownable()
    {
        poolConfigurator = _poolConfigurator;
        rewardMinter = _rewardMinter;
        uint256 length = _startTimeOffset.length;
        for (uint256 i = length - 1; i + 1 != 0; i--) {
            emissionSchedule.push(
                EmissionPoint({
                    startTimeOffset: _startTimeOffset[i],
                    rewardsPerSecond: _rewardsPerSecond[i]
                })
            );
        }
        maxMintableTokens = _maxMintable;
    }

    // adjust emission schedule
    function setEmissionSchedule(
        uint128[] memory _startTimeOffset, 
        uint128[] memory _rewardsPerSecond
    ) external onlyOwner {
        uint128 first = _startTimeOffset[0];
        uint256 length = _startTimeOffset.length;
        require(length > 0, "Array cant be 0.");
        if(startTime > 0){
            require(first > block.timestamp.sub(startTime).add(86400), "OffsetTime can be set to at least 24hr.");
        }
        delete emissionSchedule;
        for (uint256 i = length - 1; i + 1 != 0; i--) {
            emissionSchedule.push(
                EmissionPoint({
                    startTimeOffset: _startTimeOffset[i],
                    rewardsPerSecond: _rewardsPerSecond[i]
                })
            );
        }
    }

    // Start the party
    function start() public onlyOwner {
        require(startTime == 0);
        startTime = block.timestamp;
    }

    // Add a new lp to the pool. Can only be called by the poolConfigurator.
    function addPool(address _token, uint256 _allocPoint) external onlyOwner {
        require(poolInfo[_token].lastRewardTime == 0);
        _updateEmissions();
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        registeredTokens.push(_token);
        poolInfo[_token] = PoolInfo({
            allocPoint: _allocPoint,
            lastRewardTime: block.timestamp,
            accRewardPerShare: 0,
            onwardIncentives: IOnwardIncentivesController(0)
        });
        emit PoolAdded(_token, _allocPoint);
    }

    // Update the given pool's allocation point. Can only be called by the owner.
    function batchUpdateAllocPoint(
        address[] calldata _tokens,
        uint256[] calldata _allocPoints
    ) public onlyOwner {
        require(_tokens.length == _allocPoints.length);
        _massUpdatePools();
        uint256 _totalAllocPoint = totalAllocPoint;
        for (uint256 i = 0; i < _tokens.length; i++) {
            PoolInfo storage pool = poolInfo[_tokens[i]];
            require(pool.lastRewardTime > 0, "token invalid!");
            _totalAllocPoint = _totalAllocPoint.sub(pool.allocPoint).add(_allocPoints[i]);
            pool.allocPoint = _allocPoints[i];
        }
        totalAllocPoint = _totalAllocPoint;
    }

    function setClaimReceiver(address _user, address _receiver) external {
        require(msg.sender == _user || msg.sender == owner());
        claimReceiver[_user] = _receiver;
    }

    function poolLength() external view returns (uint256) {
        return registeredTokens.length;
    }

    function claimableReward(address _user, address[] calldata _tokens)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory claimable = new uint256[](_tokens.length);
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            PoolInfo storage pool = poolInfo[token];
            UserInfo storage user = userInfo[token][_user];
            uint256 accRewardPerShare = pool.accRewardPerShare;
            uint256 lpSupply = IERC20(token).balanceOf(address(this));
            if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
                uint256 duration = block.timestamp.sub(pool.lastRewardTime);
                uint256 reward = duration.mul(rewardsPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
                accRewardPerShare = accRewardPerShare.add(reward.mul(ACC_SHARE_PRECISION).div(lpSupply));
            }
            claimable[i] = user.amount.mul(accRewardPerShare).div(ACC_SHARE_PRECISION).sub(user.rewardDebt);
        }
        return claimable;
    }

    function _updateEmissions() internal {
        uint256 length = emissionSchedule.length;
        if (startTime > 0 && length > 0) {
            EmissionPoint memory e = emissionSchedule[length-1];
            if (block.timestamp.sub(startTime) > e.startTimeOffset) {
                 _massUpdatePools();
                rewardsPerSecond = uint256(e.rewardsPerSecond);
                emissionSchedule.pop();
            }
        }
    }

    // Update reward variables for all pools
    function _massUpdatePools() internal {
        uint256 totalAP = totalAllocPoint;
        uint256 length = registeredTokens.length;
        for (uint256 i = 0; i < length; ++i) {
            _updatePool(registeredTokens[i], totalAP);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(address _token, uint256 _totalAllocPoint) internal {
        PoolInfo storage pool = poolInfo[_token];
        if (block.timestamp <= pool.lastRewardTime) {
            return;
        }
        uint256 lpSupply = IERC20(_token).balanceOf(address(this));
        if (lpSupply == 0 || _totalAllocPoint == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 duration = block.timestamp.sub(pool.lastRewardTime);
        if(_totalAllocPoint != 0){
          uint256 reward = duration.mul(rewardsPerSecond).mul(pool.allocPoint).div(_totalAllocPoint);
          pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(ACC_SHARE_PRECISION).div(lpSupply));
          pool.lastRewardTime = block.timestamp;
        }

    }


    function _mint(address _user, uint256 _amount) internal {
        uint256 minted = mintedTokens;
        if (minted.add(_amount) > maxMintableTokens) {
            _amount = maxMintableTokens.sub(minted);
        }
        if (_amount > 0) {
            mintedTokens = minted.add(_amount);
            address receiver = claimReceiver[_user];
            if (receiver == address(0)) receiver = _user;
            rewardMinter.mint(receiver, _amount, true);
        }
    }

    // Deposit LP tokens into the contract. Also triggers a claim.
    function deposit(address _token, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_token];
        require(pool.lastRewardTime > 0, "token invalid!");
        UserInfo storage user = userInfo[_token][msg.sender];
        _updateEmissions();
        _updatePool(_token, totalAllocPoint);
        // suppoet fot token
        uint256 balanceBefore = IERC20(_token).balanceOf(address(this)); 
        IERC20(_token).safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        _amount = IERC20(_token).balanceOf(address(this)).sub(balanceBefore);
        // claim reward
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accRewardPerShare).div(ACC_SHARE_PRECISION).sub(
                    user.rewardDebt
                );
            _mint(msg.sender, pending);
        }
        // update user info
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(ACC_SHARE_PRECISION);

        
        
        emit Deposit(_token, msg.sender, _amount);

    }

    // Withdraw LP tokens. Also triggers a claim.
    function withdraw(address _token, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_token];
        require(pool.lastRewardTime > 0, "token invalid!");
        UserInfo storage user = userInfo[_token][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        _updateEmissions();
        _updatePool(_token, totalAllocPoint);
        // pending reward
        uint256 pending =
            user.amount.mul(pool.accRewardPerShare).div(ACC_SHARE_PRECISION).sub(
                user.rewardDebt
            );
         // update user info
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(ACC_SHARE_PRECISION);
        
        _mint(msg.sender, pending);
        IERC20(_token).safeTransfer(address(msg.sender), _amount); 

        emit Withdraw(_token, msg.sender, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(address _token) external nonReentrant {
        PoolInfo storage pool = poolInfo[_token];
        require(pool.lastRewardTime > 0, "token invalid!");
        UserInfo storage user = userInfo[_token][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        IERC20(_token).safeTransfer(address(msg.sender), amount);

        emit EmergencyWithdraw(_token, msg.sender, amount);
    }

    // Claim pending rewards for one or more pools.
    // Rewards are not received directly, they are minted by the rewardMinter.
    function claim(address _user, address[] calldata _tokens) external nonReentrant {
        _updateEmissions();
        uint256 pending;
        uint256 _totalAllocPoint = totalAllocPoint;
        require(_totalAllocPoint != 0, "Total alloc must > 0");
        for (uint i = 0; i < _tokens.length; i++) {
            PoolInfo storage pool = poolInfo[_tokens[i]];
            require(pool.lastRewardTime > 0, "token invalid!");
            _updatePool(_tokens[i], _totalAllocPoint);
            UserInfo storage user = userInfo[_tokens[i]][_user];
            pending = pending.add(user.amount.mul(pool.accRewardPerShare).div(ACC_SHARE_PRECISION).sub(user.rewardDebt));
            user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(ACC_SHARE_PRECISION);
        }
        _mint(_user, pending);
    }

    function updateEmissions() external onlyOwner {
        _updateEmissions();
    }

}