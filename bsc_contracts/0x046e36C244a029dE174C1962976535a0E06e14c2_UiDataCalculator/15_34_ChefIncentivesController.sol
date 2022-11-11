// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "../interfaces/IMultiFeeDistribution.sol";
import "../interfaces/IOnwardIncentivesController.sol";
import "../dependencies/openzeppelin/contracts/IERC20.sol";
import "../dependencies/openzeppelin/contracts/SafeERC20.sol";
import "../dependencies/openzeppelin/contracts/SafeMath.sol";
import "../dependencies/openzeppelin/contracts/Ownable.sol";

// based on the Sushi MasterChef
// https://github.com/sushiswap/sushiswap/blob/master/contracts/MasterChef.sol
contract ChefIncentivesController is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }
    // Info of each pool.
    struct PoolInfo {
        uint256 totalSupply;
        uint256 allocPoint; // How many allocation points assigned to this pool.
        uint256 lastRewardTime; // Last second that reward distribution occurs.
        uint256 accRewardPerShare; // Accumulated rewards per share, times 1e12. See below.
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

    // account earning rewards => receiver of rewards for this account
    // if receiver is set to address(0), rewards are paid to the earner
    // this is used to aid 3rd party contract integrations
    mapping (address => address) public claimReceiver;

    event BalanceUpdated(
        address indexed token,
        address indexed user,
        uint256 balance,
        uint256 totalSupply
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

    // Start the party
    function start() public onlyOwner {
        require(startTime == 0);
        startTime = block.timestamp;
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

    // Add a new lp to the pool. Can only be called by the poolConfigurator.
    function addPool(address _token, uint256 _allocPoint) external {
        require(msg.sender == poolConfigurator);
        require(poolInfo[_token].lastRewardTime == 0);
        _updateEmissions();
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        registeredTokens.push(_token);
        poolInfo[_token] = PoolInfo({
            totalSupply: 0,
            allocPoint: _allocPoint,
            lastRewardTime: block.timestamp,
            accRewardPerShare: 0,
            onwardIncentives: IOnwardIncentivesController(0)
        });
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
            require(pool.lastRewardTime > 0);
            _totalAllocPoint = _totalAllocPoint.sub(pool.allocPoint).add(_allocPoints[i]);
            pool.allocPoint = _allocPoints[i];
        }
        totalAllocPoint = _totalAllocPoint;
    }

    function setOnwardIncentives(
        address _token,
        IOnwardIncentivesController _incentives
    )
        external
        onlyOwner
    {
        require(poolInfo[_token].lastRewardTime != 0);
        poolInfo[_token].onwardIncentives = _incentives;
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
            uint256 lpSupply = pool.totalSupply;
            if (block.timestamp > pool.lastRewardTime && lpSupply != 0 && totalAllocPoint != 0) {
                uint256 duration = block.timestamp.sub(pool.lastRewardTime);
                uint256 reward = duration.mul(rewardsPerSecond).mul(pool.allocPoint).div(totalAllocPoint);
                accRewardPerShare = accRewardPerShare.add(reward.mul(1e12).div(lpSupply));
            }
            claimable[i] = user.amount.mul(accRewardPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 lpSupply = pool.totalSupply;
        if (lpSupply == 0  || _totalAllocPoint == 0) {
            pool.lastRewardTime = block.timestamp;
            return;
        }
        uint256 duration = block.timestamp.sub(pool.lastRewardTime);
        if(_totalAllocPoint != 0){
          uint256 reward = duration.mul(rewardsPerSecond).mul(pool.allocPoint).div(_totalAllocPoint);
          pool.accRewardPerShare = pool.accRewardPerShare.add(reward.mul(1e12).div(lpSupply));
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

    function handleAction(address _user, uint256 _balance, uint256 _totalSupply) external {
        PoolInfo storage pool = poolInfo[msg.sender];
        require(pool.lastRewardTime > 0);
        _updateEmissions();
        _updatePool(msg.sender, totalAllocPoint);
        UserInfo storage user = userInfo[msg.sender][_user];
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accRewardPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            _mint(_user, pending);
        }
        user.amount = _balance;
        user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        pool.totalSupply = _totalSupply;
        if (pool.onwardIncentives != IOnwardIncentivesController(0)) {
            pool.onwardIncentives.handleAction(_user, _balance, _totalSupply);
        }
        emit BalanceUpdated(msg.sender, _user, _balance, _totalSupply);
    }

    // Claim pending rewards for one or more pools.
    // Rewards are not received directly, they are minted by the rewardMinter.
    function claim(address _user, address[] calldata _tokens) external {
        _updateEmissions();
        uint256 pending;
        uint256 _totalAllocPoint = totalAllocPoint;
        require(_totalAllocPoint != 0, "Total alloc must > 0");
        for (uint i = 0; i < _tokens.length; i++) {
            PoolInfo storage pool = poolInfo[_tokens[i]];
            require(pool.lastRewardTime > 0);
            _updatePool(_tokens[i], _totalAllocPoint);
            UserInfo storage user = userInfo[_tokens[i]][_user];
            pending = pending.add(user.amount.mul(pool.accRewardPerShare).div(1e12).sub(user.rewardDebt));
            user.rewardDebt = user.amount.mul(pool.accRewardPerShare).div(1e12);
        }
        _mint(_user, pending);
    }

    function updateEmissions() external onlyOwner {
        _updateEmissions();
    }

}