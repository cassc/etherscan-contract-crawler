// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interface/ISFTToken.sol";


contract Reward is Ownable2StepUpgradeable {
    using SafeERC20 for IERC20;
    struct LockInfo {
        uint amount;
        uint stakeAt; // 质押时间
        uint lockPeriod; // 锁仓期限
        uint totalRewards; // 总奖励
        uint unclaimedRewards; // 未领取奖励
    }

    IERC20 public filToken;
    ISFTToken public sftToken;
    address public distributor;
    // pid为0：表示活期，pid为1表示三个月定期
    mapping (uint => uint) public pools; // poolId => lockPeriod
    mapping (address => mapping (uint => LockInfo[])) public userInfo; // address => poolId => LockInfo

    event Stake(address indexed user, uint indexed pid, uint index, uint amount);
    event Unstake(address indexed user, uint indexed pid, uint index, uint amount);
    event Claim(address indexed user, uint indexed pid, uint index, uint amount);
    event DistributeSingleReward(address distributor, address user, uint pid, uint index, uint reward);
    event DistributeReward(address distributor, address[] userList, uint[] pidList, uint[] indexList, uint[] rewardList, uint totalRewads);
    event TokensRescued(address indexed to, address indexed token, uint256 amount);
    event SetDistributor(address oldDistributor, address newDistributor);
    event SetPool(uint pid, uint lockPeriod);

    function initialize(IERC20 _filToken, ISFTToken _sftToken, address _distributor) external initializer {
        require(address(_filToken) != address(0), "fil token address cannot be zero");
        require(address(_sftToken) != address(0), "SFT token address cannot be zero");
        __Context_init_unchained();
        __Ownable_init_unchained();
        filToken = _filToken;
        sftToken = _sftToken;
        _setPool(1, 7776000); //三个月定期, 活期使用默认值:pools[0] = 0
        _setDistributor(_distributor);
    }

    function setDistributor(address newDistributor) external onlyOwner {
        _setDistributor(newDistributor);
    }

    function _setDistributor(address _distributor) private {
        emit SetDistributor(distributor, _distributor);
        distributor = _distributor;
    }

    function setPool(uint pid, uint lockPeriod) external onlyOwner {
        _setPool(pid, lockPeriod);
    }

    function _setPool(uint pid, uint lockPeriod) private {
        require(pid != 0 && pools[pid] == 0, "pool already exists");
        pools[pid] = lockPeriod;
        emit SetPool(pid, lockPeriod);
    }

    function getUserInfo(address user, uint pid) external view returns(LockInfo[] memory) {
        return userInfo[user][pid];
    }

    // 质押
    function stake(uint pid, uint amount) external {
        require(pid == 0 || pools[pid] > 0, "pool not exsits");
        require(sftToken.balanceOf(address(msg.sender)) >= amount, "stake: sft token banlance not enough");
        require(sftToken.transferFrom(address(msg.sender),address(this), amount), "stake: transfer failed");
        LockInfo[] storage lockList = userInfo[address(msg.sender)][pid];
        // 活期单独处理
        if (pid == 0) {
            // 第一次质押
            if (lockList.length == 0) {
                lockList.push(
                    LockInfo({
                        amount: amount,
                        stakeAt: block.timestamp,
                        lockPeriod: 0,
                        totalRewards: 0,
                        unclaimedRewards: 0
                    })
                );
            } else {
                LockInfo storage lockInfo = lockList[0];
                lockInfo.amount += amount;
                // 活期的stakeAt表示最近的一次质押时间
                lockInfo.stakeAt = block.timestamp;
            }
        // 非活期，直接添加一次质押记录
        } else {
            lockList.push(
                LockInfo({
                    amount: amount,
                    stakeAt: block.timestamp,
                    lockPeriod: pools[pid],
                    totalRewards: 0,
                    unclaimedRewards: 0
                })
            );
        }
        emit Stake(address(msg.sender), pid, lockList.length - 1, amount);
    }

    // 解质押，pid:哪个池子，index:第几次质押，amount:数量；注意：index从0开始。
    function unstake(uint pid, uint index, uint amount) external {
        LockInfo storage lockInfo = userInfo[address(msg.sender)][pid][index];
        require(block.timestamp > lockInfo.stakeAt + lockInfo.lockPeriod, "it is not time to unlock");
        require(lockInfo.amount >= amount, "unstake: balance not enough");
        lockInfo.amount -= amount;
        require(sftToken.transfer(address(msg.sender), amount), "unstake: transfer fialed");
        emit Unstake(address(msg.sender), pid, index, amount);
    }

    // 分发奖励,给用户userList[i]在池子pidList[i]中的第indexList[i]次质押发放rewardList[i]个FIL的奖励，并将totalReward个FIL转到当前合约中
    function distributeReward(address[] calldata userList, uint[] calldata pidList, uint[] calldata indexList, uint[] calldata rewardList, uint totalRewards) external {
        require(address(msg.sender) == distributor, "only distributor can call");
        require(userList.length == pidList.length && userList.length == indexList.length && userList.length == rewardList.length, "incorrent params");
        require(filToken.balanceOf(msg.sender) >= totalRewards, "fil token balance not enough");
        for (uint i = 0; i < userList.length; i++) {
            LockInfo storage lockInfo = userInfo[userList[i]][pidList[i]][indexList[i]];
            lockInfo.totalRewards += rewardList[i];
            lockInfo.unclaimedRewards += rewardList[i];
            emit DistributeSingleReward(address(msg.sender), userList[i], pidList[i], indexList[i], rewardList[i]);
        }
        filToken.safeTransferFrom(address(msg.sender), address(this), totalRewards);
        emit DistributeReward(address(msg.sender), userList, pidList, indexList, rewardList, totalRewards);
    }

    // 领取收益，用户领取在pid号池子中第index质押的奖励
    function claim(uint pid, uint index, uint amount) external {
        LockInfo storage lockInfo = userInfo[address(msg.sender)][pid][index];
        require(lockInfo.unclaimedRewards >= amount, "unclaimed rewards not enough");
        lockInfo.unclaimedRewards -= amount;
        filToken.safeTransfer(address(msg.sender), amount);
        emit Claim(address(msg.sender), pid, index, amount);
    }

    // 提取误转入的代币
    function rescueTokens(
        address _to,
        address _token,
        uint256 _amount
    ) external onlyOwner {
        require(_to != address(0), "Cannot send to address(0)");
        require(_amount != 0, "Cannot rescue 0 tokens");
        IERC20 token = IERC20(_token);
        token.safeTransfer(_to, _amount);
        emit TokensRescued(_to, _token, _amount);
    }
}