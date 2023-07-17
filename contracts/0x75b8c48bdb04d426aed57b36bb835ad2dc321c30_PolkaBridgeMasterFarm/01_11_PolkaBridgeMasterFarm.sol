pragma solidity >=0.6.0;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./PolkaBridge.sol";

// import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
//import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

contract PolkaBridgeMasterFarm is Ownable {
    string public name = "PolkaBridge: Deflationary Farming";
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amountLP;
        uint256 rewardDebt;
        uint256 rewardDebtAtBlock;
        uint256 rewardClaimed;
    }

    struct PoolInfo {
        IERC20 lpToken;
        IERC20 tokenA;
        IERC20 tokenB;
        uint256 multiplier;
        uint256 lastPoolReward; //history pool reward
        uint256 lastRewardBlock;
        uint256 lastLPBalance;
        uint256 accPBRPerShare;
        uint256 startBlock;
        uint256 stopBlock;
        uint256 totalRewardClaimed;
        bool isActived;
    }

    PolkaBridge public polkaBridge;
    uint256 public START_BLOCK;

    //pool Info
    PoolInfo[] public poolInfo;
    mapping(address => uint256) public poolId1;
    // Info of each user that stakes LP tokens. pid => user address => info
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    constructor(PolkaBridge _polkaBridge, uint256 _startBlock) public {
        polkaBridge = _polkaBridge;
        START_BLOCK = _startBlock;
    }

    function poolBalance() public view returns (uint256) {
        return polkaBridge.balanceOf(address(this));
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(IERC20 _lpToken,IERC20 _tokenA, IERC20 _tokenB, uint256 _multiplier, uint256 _startBlock) public onlyOwner {
        require(
            poolId1[address(_lpToken)] == 0,
            "PolkaBridgeMasterFarm::add: lp is already in pool"
        );

        uint256 _lastRewardBlock =
            block.number > START_BLOCK ? block.number : START_BLOCK;

        poolId1[address(_lpToken)] = poolInfo.length + 1;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                tokenA: _tokenA,
                tokenB: _tokenB,
                multiplier: _multiplier,
                lastRewardBlock: _lastRewardBlock,
                lastPoolReward: 0,
                lastLPBalance: 0,
                accPBRPerShare: 0,
                startBlock: _startBlock > 0 ? _startBlock : block.number,
                stopBlock: 0,
                totalRewardClaimed: 0,
                isActived: true
            })
        );

        massUpdatePools();
    }

    function getChangePoolReward(uint256 _pid, uint256 _totalMultiplier) public view returns (uint256) {
        uint256 changePoolReward;
        if (_totalMultiplier == 0) {
            changePoolReward = 0;
        }
        else {
            uint256 currentPoolBalance = poolBalance();
            uint256 totalLastPoolReward = getTotalLastPoolReward();
            changePoolReward = ((currentPoolBalance.sub(totalLastPoolReward)).mul(poolInfo[_pid].multiplier).mul(1e18)).div(_totalMultiplier);
        }

        if (changePoolReward <= 0) {
            changePoolReward = 0;
        }

        return changePoolReward;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        uint256 totalMultiplier = countTotalMultiplier();
        for (uint256 pid = 0; pid < length; pid++) {
            if (poolInfo[pid].isActived) {
                uint256 changePoolReward = getChangePoolReward(pid, totalMultiplier);
                updatePool(pid, changePoolReward, 1);
            }
        }
    }

    function getTotalLastPoolReward() public view returns (uint256) {
        uint256 total;
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            if (poolInfo[pid].isActived) {
                total += poolInfo[pid].lastPoolReward;
            }
        }
        return total;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(
        uint256 _pid,
        uint256 _changePoolReward,
        uint256 flag
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock && flag==1) {
            return;
        }
        uint256 lpSupply = pool.lastLPBalance;
        if (lpSupply == 0) { // first deposit
            pool.accPBRPerShare = 0;
        } else {
            pool.accPBRPerShare = pool.accPBRPerShare.add(
                (_changePoolReward.mul(1e18).div(lpSupply))
            );
        }
        pool.lastRewardBlock = block.number;

        if (flag == 1) {
            pool.lastPoolReward += _changePoolReward;
        } else {
            pool.lastPoolReward -= _changePoolReward;
        }

        pool.lastLPBalance = pool.lpToken.balanceOf(address(this));
    }

    function pendingReward(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 temptAccPBRPerShare = pool.accPBRPerShare;
        uint256 totalMultiplier = countTotalMultiplier();

        if (block.number > pool.lastRewardBlock && lpSupply > 0) {
            temptAccPBRPerShare = pool.accPBRPerShare.add(
                (getChangePoolReward(_pid, totalMultiplier).mul(1e18).div(lpSupply))
            );
        }

        uint256 pending = (
                user.amountLP.mul(temptAccPBRPerShare).sub(
                    user.rewardDebt.mul(1e18)
                )
            ).div(1e18);

        return pending;
    }

    function claimReward(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        massUpdatePools();
        _harvest(_pid);

        user.rewardDebt = user.amountLP.mul(pool.accPBRPerShare).div(1e18);
    }

    function _harvest(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.amountLP > 0) {
            uint256 pending = pendingReward(_pid, msg.sender);
            uint256 masterBal = poolBalance();

            if (pending > masterBal) {
                pending = masterBal;
            }

            if (pending > 0) {
                polkaBridge.transfer(msg.sender, pending);
                pool.lastPoolReward -= pending;
                pool.totalRewardClaimed += pending;
            }

            user.rewardDebtAtBlock = block.number;
            user.rewardClaimed += pending;
        }
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        require(
            _amount > 0,
            "PolkaBridgeMasterFarmer::deposit: amount must be greater than 0"
        );

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );

        massUpdatePools();
        _harvest(_pid);

        if (user.amountLP == 0) {
            user.rewardDebtAtBlock = block.number;
        }

        user.amountLP = user.amountLP.add(_amount);
        user.rewardDebt = user.amountLP.mul(pool.accPBRPerShare).div(1e18);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(
            user.amountLP >= _amount,
            "PolkaBridgeMasterFarmer::withdraw: not good"
        );

        if (_amount > 0) {
            massUpdatePools();
            _harvest(_pid);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.lastLPBalance = pool.lpToken.balanceOf(address(this));

            // update pool
            // updatePool(_pid, 0, 1);
            user.amountLP = user.amountLP.sub(_amount);
            user.rewardDebt = user.amountLP.mul(pool.accPBRPerShare).div(1e18);
        }
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amountLP);

        user.amountLP = 0;
        user.rewardDebt = 0;
    }

    function getPoolInfo(uint256 _pid)
        public
        view
        returns (
            uint256,
            uint256,
            address,
            uint256,
            uint256,
            uint256,
            // bool,
            uint256
        )
    //uint256
    {
        return (
            poolInfo[_pid].lastRewardBlock,
            poolInfo[_pid].multiplier,
            address(poolInfo[_pid].lpToken),
            poolInfo[_pid].lastPoolReward,
            poolInfo[_pid].startBlock,
            poolInfo[_pid].accPBRPerShare,
            // poolInfo[_pid].isActived,
            poolInfo[_pid].lpToken.balanceOf(address(this))
            //poolInfo[_pid].lastLPBalance
        );
    }

    function getUserInfo(uint256 _pid)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        UserInfo memory user = userInfo[_pid][msg.sender];
        return (user.amountLP, user.rewardDebt, user.rewardClaimed);
    }

    function stopPool(uint256 pid) public onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        pool.isActived = false;
        pool.stopBlock = block.number;
    }

    function activePool(uint256 pid) public onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        pool.isActived = true;
        pool.stopBlock = 0;
    }

    function changeMultiplier(uint256 pid, uint256 _multiplier) public onlyOwner {
        PoolInfo storage pool = poolInfo[pid];
        pool.multiplier = _multiplier;
    }

    function countActivePool() public view returns (uint256) {
        uint256 length = 0;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            if (poolInfo[i].isActived) length++;
        }
        return length;
    }

    function countTotalMultiplier() public view returns (uint256) {
        uint256 totalMultiplier = 0;
        for (uint256 i = 0; i < poolInfo.length; i++) {
            if (poolInfo[i].isActived) totalMultiplier += poolInfo[i].multiplier;
        }
        return totalMultiplier.mul(1e18);
    }

    function totalRewardClaimed(uint256 _pid) public view returns (uint256) {
        return poolInfo[_pid].totalRewardClaimed;
    }

    function avgRewardPerBlock(uint256 _pid) public view returns (uint256) {
        uint256 totalMultiplier = countTotalMultiplier();
        uint256 changePoolReward = getChangePoolReward(_pid, totalMultiplier);
        uint256 totalReward = poolInfo[_pid].totalRewardClaimed + poolInfo[_pid].lastPoolReward + changePoolReward;
        uint256 changeBlock;
        if (block.number <= poolInfo[_pid].lastRewardBlock){
            changeBlock = poolInfo[_pid].lastRewardBlock.sub(poolInfo[_pid].startBlock);
        }
        else {
            changeBlock = block.number.sub(poolInfo[_pid].startBlock);
        }

        return totalReward.div(changeBlock);
    }

    receive() external payable {}
}