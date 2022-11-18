// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract NekoStaking is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;

    uint256 public constant PERIOD = 86400; // 1 days,
    uint256 public constant TIME_LINEAR = 30; // 1 months,
    address public NINO_TOKEN;

    mapping(address => uint256) public countRelease;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public numberOfToken;
    mapping(address => uint256) public nextRelease;
    //
    struct UserInfo {
        uint256 amount;
        uint256 lastDeposit;
        uint256 unclaimed;
    }

    struct PoolInfo {
        uint256 timeStart;
        uint256 timeEnd;
        uint256 totalNinoStake;
        uint256 rewardNinoPerSecond;
        uint256 timeLock;
        uint256 limitTokenStake;
    }

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Release(address indexed user, uint256 indexed pid, uint256 countRelease, uint256 amount);

    PoolInfo[] public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    mapping(address => mapping(uint256 => uint256)) public blanceOfBlock;
    mapping(address => uint256[]) public arrBlockOfUser;
    mapping(address => bool) public staker;

    //
    mapping(address => uint256) public countReleaseV2;
    mapping(address => uint256) public balanceOfV2;
    mapping(address => uint256) public numberOfTokenV2;
    mapping(address => uint256) public nextReleaseV2;
    mapping(address => mapping(uint256 => uint256)) public blanceOfBlockV2;
    mapping(address => uint256[]) public arrBlockOfUserV2;
    mapping(address => bool) public stakerV2;
    mapping (address=> uint256) public userMultiple;
    uint256 public MULTIPLE;
    uint256 public limitApy;
    bool public enableLimitApy;
    mapping (address=> uint256) public userApy;
    uint256 public totalNinoV2Claimed;
    mapping (address=> bool) userV2;
    mapping (address=> bool) userV2Claimed;

    function initialize() public initializer {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        NINO_TOKEN = 0x6CAD12b3618a3C7ef1FEb6C91FdC3251f58c2a90;
    }

    function editPool(
        uint256 _pid,
        uint256 _timeStart,
        uint256 _timeEnd
    ) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.timeStart = _timeStart;
        pool.timeEnd = _timeEnd;
    }

    function createPool(
        uint256 _timeStart,
        uint256 _timeEnd,
        uint256 _ninoReward,
        uint256 _limitTokenStake,
        uint256 _numberDayLock
    ) public onlyOwner {
        uint256 rewardPerSecond = _ninoReward / (_timeEnd - _timeStart);
        poolInfo.push(
            PoolInfo({timeStart: _timeStart, timeEnd: _timeEnd, totalNinoStake: 0, rewardNinoPerSecond: rewardPerSecond, timeLock: _numberDayLock * PERIOD, limitTokenStake: _limitTokenStake})
        );
    }

    function setMultiple(uint256 _multiple) external onlyOwner {
        MULTIPLE = _multiple;
    }

    function resetUserMultiple(address _user) external onlyOwner {
        userMultiple[_user] = MULTIPLE;
    }

    function setAddVestingCountRelease(address[] memory arrAddress, uint256[] memory arrCountRelease) external onlyOwner {
        for (uint256 i = 0; i < arrAddress.length; i++) {
            address useradd = arrAddress[i];
            countRelease[useradd] = arrCountRelease[i];
        }
    }

    function resetCountRelease(address[] memory arrAddress) external onlyOwner {
        for (uint256 i = 0; i < arrAddress.length; i++) {
            address useradd = arrAddress[i];
            uint256 cliff = block.timestamp.sub(nextRelease[useradd]).div(PERIOD) + 1;
            if (cliff <= 12) {
                countRelease[useradd] = 12 - cliff;
            }
        }
    }

    function setLimitApy(uint256 _limitApy) external onlyOwner {
        limitApy = _limitApy;
    }

    function setEnableLimitApy(bool _enable) external onlyOwner {
        enableLimitApy = _enable;
    }

    function setUserV2(address[] memory _users) external onlyOwner {
        for(uint256 i = 0 ; i < _users.length ; i++){
            userV2[_users[i]] = true;
        }
        
    }

    function setUserV2Claimed(address[] memory _users) external onlyOwner {
        for(uint256 i = 0 ; i < _users.length ; i++){
            userV2Claimed[_users[i]] = true;
        }
        
    }

    function stakeV2(uint256 _pid, uint256 _amount) public whenNotPaused nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        require(block.timestamp >= pool.timeStart, "Not started yet");
        require(block.timestamp <= pool.timeEnd, "Ended yet");
        require(_amount > 0, "Require amount stake > 0");
        if (pool.limitTokenStake > 0) {
            require(block.timestamp < pool.timeStart + pool.timeLock, "Linear pool: Ended yet");
            require(pool.totalNinoStake + _amount <= pool.limitTokenStake, "Linear pool: limited token stake");
        }

        UserInfo storage user = userInfo[_pid][msg.sender];
        IERC20Upgradeable(NINO_TOKEN).transferFrom(address(msg.sender), address(this), _amount);
        uint256 reward = pendingReward(_pid, msg.sender);
        user.amount += _amount;
        user.unclaimed += reward;
        user.lastDeposit = block.timestamp;
        pool.totalNinoStake = pool.totalNinoStake + _amount;

        uint256 newRewardPerSecond = (pool.rewardNinoPerSecond * (pool.timeEnd - pool.timeStart) - reward) / (pool.timeEnd - pool.timeStart);
        pool.rewardNinoPerSecond = newRewardPerSecond;

        if (pool.limitTokenStake > 0) {
            uint256 timeStartRelease = pool.timeStart + pool.timeLock;
            _setAddressVesting(_pid, msg.sender, user.amount, timeStartRelease);
        }

        if (_pid == 1) {
            arrBlockOfUser[msg.sender].push(block.number);
            blanceOfBlock[msg.sender][block.number] = user.amount;
            staker[msg.sender] = true;
        } else if (_pid == 2) {
            arrBlockOfUserV2[msg.sender].push(block.number);
            blanceOfBlockV2[msg.sender][block.number] = user.amount;
            stakerV2[msg.sender] = true;
        }

        emit Deposit(msg.sender, _pid, _amount);
    }

    function setAddVesting( address[] memory arrAddress) external onlyOwner {
        uint256 timeReleaseV1 = 1660120200; 
        uint256 timeReleaseV2 = 1668412800;

        for(uint256 i = 0 ; i< arrAddress.length ; i ++) {
            address useradd = arrAddress[i];

            UserInfo memory user = userInfo[1][useradd];
            uint256 amount = user.amount ;
            uint256 numberRelease = countRelease[useradd] ;
            uint256 amountStakeV1 =  amount * TIME_LINEAR / (TIME_LINEAR - numberRelease );

            _setAddressVesting( 2 , arrAddress[i] , balanceOf[useradd]  , timeReleaseV2);
            _setAddressVesting( 1 , arrAddress[i] , amountStakeV1  , timeReleaseV1);
        }
    }

    function pendingReward(uint256 _pid, address _user) public view whenNotPaused returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        //

        if (_pid == 1) {
            if (countRelease[_user] > 0 && pool.limitTokenStake > 0) {
                return 0;
            }
        }

        if (_pid == 2) {
            if (countReleaseV2[_user] > 0 && pool.limitTokenStake > 0) {
                return 0;
            }
        }
        //
        uint256 time = block.timestamp;
        if (pool.totalNinoStake == 0 || block.timestamp <= pool.timeStart) {
            return 0;
        }

        if (block.timestamp > pool.timeEnd) {
            time = pool.timeEnd;
        }
        // if(block.timestamp - user.lastDeposit <= 1 days && pool.limitTokenStake == 0) {
        //     return 0;
        // }

        if (_pid == 2 ) {
            if(!enableLimitApy || userV2[_user] || (user.amount <= 100000* 10**18 && user.amount >= 50000* 10**18 )) {
             uint256 rewardV2 =   user.amount * (time - user.lastDeposit)  / PERIOD / 366 ;
             return rewardV2 ;
            }
        }

        uint256 rewarPerSecond = pool.rewardNinoPerSecond ;

        uint256 total = pool.totalNinoStake;
        if(user.amount > pool.totalNinoStake) {
            total = pool.totalNinoStake + user.amount ;
        }
        uint256 reward =  ((time - user.lastDeposit) * rewarPerSecond * user.amount) / total; 
        return reward;
    }

    function calRewardV2Claimed(address _user) public view returns(uint256) {
        PoolInfo memory pool = poolInfo[2];
        UserInfo memory user = userInfo[2][_user];

        uint256 reward = 0;
        if(userV2Claimed[_user]){
          reward = numberOfTokenV2[_user] * (pool.timeEnd - user.lastDeposit)  / PERIOD / 366  - numberOfTokenV2[_user]  * pool.rewardNinoPerSecond * (pool.timeEnd - user.lastDeposit) / pool.totalNinoStake;
        }
        return reward;
    }

    function _pendingReward(uint256 _pid, address _user) private view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo memory user = userInfo[_pid][_user];
        //

        if (_pid == 1) {
            if (countRelease[_user] > 0 && pool.limitTokenStake > 0) {
                return 0;
            }
        }

        if (_pid == 2) {
            if (countReleaseV2[_user] > 0 && pool.limitTokenStake > 0) {
                return 0;
            }
        }
        //
        uint256 time = block.timestamp;
        if (pool.totalNinoStake == 0 || block.timestamp <= pool.timeStart) {
            return 0;
        }

        if (block.timestamp > pool.timeEnd) {
            time = pool.timeEnd;
        }

        uint256 rewarPerSecond = pool.rewardNinoPerSecond ;

        uint256 total = pool.totalNinoStake;
        if(user.amount > pool.totalNinoStake) {
            total = pool.totalNinoStake + user.amount ;
        }
        uint256 reward =  ((time - user.lastDeposit) * rewarPerSecond * user.amount) / total; 
        return reward;
    }

    function setTotalNinoStake(uint256 _pid, uint256 _amount) public onlyOwner {
        _setTotalNinoStake(_pid, _amount);
    }

    function _setTotalNinoStake(uint256 _pid, uint256 _amount) private {
        PoolInfo storage pool = poolInfo[_pid];
        pool.totalNinoStake = _amount;
    }

    function getReward(uint256 _pid, address _user) public view whenNotPaused returns (uint256) {
        UserInfo memory user = userInfo[_pid][_user];
        uint256 reward = pendingReward(_pid, _user);
        uint256 totalReward = user.unclaimed + reward;
        if(_pid == 2) {
            return reward;
        }
        return totalReward;
    }

    function unStakeV2(uint256 _pid) public whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];

        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 reward = pendingReward(_pid, msg.sender);
        uint256 totalReward = reward ;

        if (block.timestamp - user.lastDeposit <= 1 days && pool.limitTokenStake == 0) {
            reward = 0;
            totalReward = 0;
        }

        setV2UnclaimedAndClaimed();

        bool check =(!enableLimitApy || userV2[msg.sender] || (user.amount <= 100000* 10**18 && user.amount >= 50000* 10**18 ) );
        if( _pid == 2 && check) {
            uint256 rewardV2 = _pendingReward(_pid, msg.sender);
            totalReward = reward + user.unclaimed; 
            totalNinoV2Claimed += (reward - rewardV2); 
            uint256 newRewardPerSecond = (pool.rewardNinoPerSecond * (pool.timeEnd - pool.timeStart) - rewardV2 ) / (pool.timeEnd - pool.timeStart);
            pool.rewardNinoPerSecond = newRewardPerSecond;
        }else {
            uint256 newRewardPerSecond = (pool.rewardNinoPerSecond * (pool.timeEnd - pool.timeStart) - reward) / (pool.timeEnd - pool.timeStart);
            pool.rewardNinoPerSecond = newRewardPerSecond;
            totalReward = reward + user.unclaimed;  
        }
        

        if (_pid == 0) {
            pool.totalNinoStake -= user.amount;
        }

        if (_pid == 1) {
            if (countRelease[msg.sender] == 0 && pool.totalNinoStake >= user.amount) {
                pool.totalNinoStake -= user.amount;
            }
        }

        if (_pid == 2) {
            if (countReleaseV2[msg.sender] == 0 && pool.totalNinoStake >= user.amount) {
                pool.totalNinoStake -= user.amount;
            }
            totalReward += calRewardV2Claimed(msg.sender);
            totalNinoV2Claimed  += calRewardV2Claimed(msg.sender);
        }

        if (pool.limitTokenStake == 0) {
            IERC20Upgradeable(NINO_TOKEN).transfer(address(msg.sender), user.amount);
            user.amount = 0;
        } else {
            if (_pid == 1) {
                balanceOf[msg.sender] = user.amount;
            }

            uint256 amountRelease = _release(_pid);
            require(user.amount >= amountRelease, "Error amount release");
            user.amount -= amountRelease;
        }

        IERC20Upgradeable(NINO_TOKEN).transfer(address(msg.sender), totalReward);
        user.unclaimed = 0;
        //
        if (_pid == 1) {
            arrBlockOfUser[msg.sender].push(block.number);
            blanceOfBlock[msg.sender][block.number] = user.amount;
        } else if (_pid == 2) {
            arrBlockOfUserV2[msg.sender].push(block.number);
            blanceOfBlockV2[msg.sender][block.number] = user.amount;
        }
    }

    function setV2UnclaimedAndClaimed() public {
        address add1 = address(0x1193b75c95089b37F54F09998562DCe81c25B9f8);
        if(!userV2[add1]) userV2[add1] = true;
        //
        address add2 = address(0x5796fDEB5D0DCAC3946B3A9e65B1D3c2F1fB9835);
        if(!userV2Claimed[add2]) userV2Claimed[add2] = true;
    }

    //
    function setPause() external onlyOwner {
        _pause();
    }

    function unsetPause() external onlyOwner {
        _unpause();
    }

    function _setAddressVesting(
        uint256 _pid,
        address _addr,
        uint256 _amount,
        uint256 _timeStart
    ) private {
        if (_pid == 1) {
            balanceOf[_addr] = _amount;
            numberOfToken[_addr] = _amount;
            nextRelease[_addr] = _timeStart;
        } else if (_pid == 2) {
            balanceOfV2[_addr] = _amount;
            numberOfTokenV2[_addr] = _amount;
            nextReleaseV2[_addr] = _timeStart;
        }
    }

    function calculatorBalanceOfV1(address[] memory users) external onlyOwner {
        for(uint256 i = 0 ; i < users.length ; i++) {
            address user = users[i];
            UserInfo storage userPool = userInfo[1][user];
            uint256 timeRemain = TIME_LINEAR - countRelease[user] ;
            uint256 amountRemain = numberOfToken[user].mul(timeRemain).div(TIME_LINEAR);
            balanceOf[user] = amountRemain;
            userPool.amount = amountRemain;
        }
    }

    function _release(uint256 _pid) private returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];

        if (_pid == 1) {
            require(balanceOf[msg.sender] > 0, "Invalid amount");
            require(block.timestamp >= pool.timeStart + pool.timeLock + PERIOD.mul(countRelease[msg.sender]), "TokenTimelock: current time is before release time");
            require(IERC20Upgradeable(NINO_TOKEN).balanceOf(address(this)) > 0, "TokenTimelock: no tokens to release");

            uint256 cliff = block.timestamp.sub(nextRelease[msg.sender]).div(PERIOD) + 1;
            uint256 amount = numberOfToken[msg.sender].mul(cliff).div(TIME_LINEAR);
            if (countRelease[msg.sender] + cliff >= TIME_LINEAR) {
                IERC20Upgradeable(NINO_TOKEN).transfer(msg.sender, balanceOf[msg.sender]);
                amount = balanceOf[msg.sender];
                balanceOf[msg.sender] = 0;
                
            } else {
                nextRelease[msg.sender] = nextRelease[msg.sender] + PERIOD.mul(cliff);
                balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);

                IERC20Upgradeable(NINO_TOKEN).transfer(msg.sender, amount);
            }

            countRelease[msg.sender] += cliff;
            emit Release(msg.sender, _pid, countRelease[msg.sender], amount);
            return amount;
        } else if (_pid == 2) {
            require(balanceOfV2[msg.sender] > 0, "Invalid amount");
            require(block.timestamp >= pool.timeStart + pool.timeLock + PERIOD.mul(countReleaseV2[msg.sender]), "TokenTimelock: current time is before release time");
            require(IERC20Upgradeable(NINO_TOKEN).balanceOf(address(this)) > 0, "TokenTimelock: no tokens to release");

            uint256 cliff = block.timestamp.sub(nextReleaseV2[msg.sender]).div(PERIOD) + 1;
            uint256 amount = numberOfTokenV2[msg.sender].mul(cliff).div(TIME_LINEAR);
            if (countReleaseV2[msg.sender] + cliff >= TIME_LINEAR) {
                IERC20Upgradeable(NINO_TOKEN).transfer(msg.sender, balanceOfV2[msg.sender]);
                amount = balanceOfV2[msg.sender];
                balanceOfV2[msg.sender] = 0;
            } else {
                nextReleaseV2[msg.sender] = nextReleaseV2[msg.sender] + PERIOD.mul(cliff);
                balanceOfV2[msg.sender] = balanceOfV2[msg.sender].sub(amount);

                IERC20Upgradeable(NINO_TOKEN).transfer(msg.sender, amount);
            }

            countReleaseV2[msg.sender] += cliff;
            emit Release(msg.sender, _pid, countReleaseV2[msg.sender], amount);
            return amount;
        }
        return 0;
    }

    function getTimeReleaseNext(uint256 _pid) public view returns (uint256) {
        PoolInfo memory pool = poolInfo[_pid];
        if (_pid == 1) {
            return pool.timeStart + pool.timeLock + PERIOD.mul(countRelease[msg.sender]);
        } else {
            return pool.timeStart + pool.timeLock + PERIOD.mul(countReleaseV2[msg.sender]);
        }
    }

    function setTokenAddress(address _addr) external onlyOwner {
        NINO_TOKEN = _addr;
    }

    function getBalanceRemainingVesting(address _addr) external view returns (uint256) {
        return balanceOf[_addr];
    }

    function getBalanceAvailable(uint256 _pid, address _addr) external view returns (uint256) {
        if (_pid == 1) {
            if (balanceOf[_addr] == 0) {
                return 0;
            }
            //
            if (block.timestamp >= nextRelease[_addr]) {

                uint256 cliff = block.timestamp.sub(nextRelease[_addr]).div(PERIOD) + 1;

                if (countRelease[_addr] + cliff >= TIME_LINEAR) {
                    return balanceOf[_addr];
                }

                uint256 amount = numberOfToken[_addr].mul(cliff).div(TIME_LINEAR);
                return amount;
            }
        } else if (_pid == 2) {
            if (balanceOfV2[_addr] == 0) {
                return 0;
            }
            //
            if (block.timestamp >= nextReleaseV2[_addr]) {
                uint256 cliff = block.timestamp.sub(nextReleaseV2[_addr]).div(PERIOD) + 1;

                if (countReleaseV2[_addr] + cliff >= TIME_LINEAR) {
                    return balanceOf[_addr];
                }
                uint256 amount = numberOfTokenV2[_addr].mul(cliff).div(TIME_LINEAR);
                return amount;
            }
        }
        //
        return 0;
    }

    function getBalance() public view returns (uint256) {
        return IERC20Upgradeable(NINO_TOKEN).balanceOf(address(this));
    }

    function recoverToken(address _token) external onlyOwner {
        uint256 balance = IERC20Upgradeable(_token).balanceOf(address(this));
        require(balance != 0, "Operations: Cannot recover zero balance");

        IERC20Upgradeable(_token).transfer(address(msg.sender), balance);
    }

    function getArrBlockChangeBalance(uint256 _pid, address _user) external view returns (uint256[] memory) {
        if (_pid == 1) {
            return arrBlockOfUser[_user];
        }
        return arrBlockOfUserV2[_user];
    }

    function getNumberStakeAtBlock(
        uint256 _pid,
        address _user,
        uint256 _block
    ) external view returns (uint256) {
        if (_pid == 1) {
            if (!staker[_user]) {
                return balanceOf[_user];
            }
            uint256[] memory arrBlock = arrBlockOfUser[_user];
            for (uint256 i = 0; i < arrBlock.length - 1; i++) {
                if (arrBlock[i] <= _block && arrBlock[i + 1] > _block) {
                    uint256 userBlock = arrBlock[i];
                    return blanceOfBlock[_user][userBlock];
                }
            }
            uint256 blockLeast = arrBlock[arrBlock.length];
            return blanceOfBlock[_user][blockLeast];
        } else {
            if (!stakerV2[_user]) {
                return balanceOfV2[_user];
            }
            uint256[] memory arrBlock = arrBlockOfUserV2[_user];
            for (uint256 i = 0; i < arrBlock.length - 1; i++) {
                if (arrBlock[i] <= _block && arrBlock[i + 1] > _block) {
                    uint256 userBlock = arrBlock[i];
                    return blanceOfBlockV2[_user][userBlock];
                }
            }
            uint256 blockLeast = arrBlock[arrBlock.length];
            return blanceOfBlockV2[_user][blockLeast];
        }
    }
}