// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

contract LP_Stake is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    IERC20Upgradeable public LP;
    IERC20Upgradeable public SP;
    IERC20Upgradeable public BNQ;
    uint public totalStake;
    uint public debt;
    uint public lastTime;
    uint constant acc = 1e10;
    uint public dailyOut;
    uint public rate;
    uint public totalClaimed;

    struct UserInfo {
        uint stakeAmount;
        uint claimed;
        uint toClaim;
        uint debt;
    }

    struct LockInfo {
        uint lockAmount;
        uint startTime;
        uint endTime;
        uint claimTime;
        uint rate;
        uint claimed;
    }

    mapping(address => LockInfo) public lockInfo;
    mapping(address => UserInfo)public userInfo;
    mapping(address => bool) public admin;
    address[] nodeList;
    uint public totalLock;
    address public SP_LP;
    IERC20Upgradeable public U;
    mapping(uint => mapping(address => bool)) public nodeAdd;
    uint public lastSendTime;
    uint public totalNodeReward;
    mapping(uint => uint) public nodeReward;

    struct ShareInfo {
        uint debt;
        uint totalAmount;
        uint claimed;
        uint lastBNQ;
    }

    struct ShareUserInfo {
        uint claimed;
        uint debt;
        uint toClaim;
    }

    ShareInfo public debtInfo;
    mapping(address => ShareUserInfo) public userShare;

    event Stake(address indexed addr, uint indexed amount);
    event Claim(address indexed addr, uint indexed amount);
    event UnStake(address indexed addr, uint indexed amount);
    event Lock(address indexed addr, uint indexed amount);

    function initialize() public initializer {
        __Ownable_init();
        dailyOut = 20 ether;
        rate = dailyOut / 86400;
    }

    modifier onlyEOA(){
        require(!AddressUpgradeable.isContract(msg.sender), "only EOA");
        _;
    }

    function setLP(address addr) external onlyOwner {
        LP = IERC20Upgradeable(addr);
    }

    function reSet() external onlyOwner{
        debtInfo.debt = 0;
        debtInfo.lastBNQ = BNQ.balanceOf(address(this));

    }

    function setSP(address addr) external onlyOwner {
        SP = IERC20Upgradeable(addr);
    }

    function setBNQ(address addr) external onlyOwner {
        BNQ = IERC20Upgradeable(addr);
    }

    function setSP_LP(address addr) external onlyOwner {
        SP_LP = addr;
    }

    function setU(address addr) external onlyOwner {
        U = IERC20Upgradeable(addr);
    }

    function setAdmin(address addr, bool b) external onlyOwner {
        admin[addr] = b;
    }

    function getTempDebt() public  view returns (uint){
        uint out = debtInfo.debt + (BNQ.balanceOf(address(this)) - debtInfo.lastBNQ) * acc / totalStake;
        return out;
    }

    function calculateBNQ(address addr) public view returns (uint){
        uint rew = (getTempDebt() - userShare[addr].debt) * userInfo[addr].stakeAmount / acc;
        rew += userShare[addr].toClaim;
        return rew;
    }

    function _claimBNQ() internal {
        debtInfo.debt += (BNQ.balanceOf(address(this)) - debtInfo.lastBNQ) * acc / totalStake;
        uint rew = debtInfo.debt - userShare[msg.sender].debt;
        rew = userShare[msg.sender].toClaim + rew * userInfo[msg.sender].stakeAmount / acc;
        if (rew > 0) {
            BNQ.transfer(msg.sender, rew);
            userShare[msg.sender].debt = debtInfo.debt;
            userShare[msg.sender].claimed += rew;
            userShare[msg.sender].toClaim = 0;
            debtInfo.claimed += rew;

        }
        debtInfo.lastBNQ = BNQ.balanceOf(address(this));
    }

    function countingDebt() public view returns (uint){
        if (totalStake == 0) {
            return 0 + debt;
        }
        uint time = block.timestamp;
        uint timeDiff = time - lastTime;
        uint _debt = debt + timeDiff * rate * acc / totalStake;
        return _debt;
    }

    function _calculate(address addr) public view returns (uint){
        UserInfo storage user = userInfo[addr];
        uint reward = user.stakeAmount * (countingDebt() - user.debt) / acc;
        return reward;
    }

    function calculateReward(address addr) external view returns (uint){
        return _calculate(addr) + userInfo[addr].toClaim;
    }

    function getBNQPrice() public view returns (uint){
        uint _uBalance = U.balanceOf(address(LP));
        uint _bnqBalance = BNQ.balanceOf(address(LP));
        uint price = _uBalance * 1e18 / _bnqBalance;
        return price;
    }

    function getSPPrice() public view returns (uint price){
        uint _spBalance = SP.balanceOf(address(SP_LP));
        uint _bnqBalance = BNQ.balanceOf(address(SP_LP));
        price = _bnqBalance * getBNQPrice() / _spBalance;
        return price;
    }

    function addNodeList(address[] memory addr) external {
        require(admin[msg.sender], "only admin");
        for (uint i = 0; i < addr.length; i++) {
            require(!nodeAdd[lastSendTime][addr[i]], 'added');
            nodeList.push(addr[i]);
            nodeAdd[lastSendTime][addr[i]] = true;

        }
    }

    function sendNode(uint totalReward) external {
        require(admin[msg.sender], 'only admin');
        BNQ.transferFrom(msg.sender, address(this), totalReward);
        totalNodeReward += totalReward;
        uint reward = totalReward / nodeList.length;
        require(nodeList.length > 0, 'no node');
        for (uint i = 0; i < nodeList.length; i++) {
            BNQ.transfer(nodeList[i], reward);
        }
        lastSendTime = block.timestamp;
        nodeReward[lastSendTime] = reward;
        delete nodeList;
    }

    function checkNodeList() external view returns (address[] memory){
        return nodeList;
    }

    function changeTotalLock(uint amount) external onlyOwner {
        totalLock = amount;
    }


    function stake(uint amount) external onlyEOA {
        require(amount > 0, "amount > 0");
        UserInfo storage user = userInfo[msg.sender];
        uint _debt = countingDebt();
        uint reward = _calculate(msg.sender);
        if(totalStake > 0){
            if (user.stakeAmount > 0) {
                debtInfo.debt += (BNQ.balanceOf(address(this)) - debtInfo.lastBNQ) * acc / totalStake;
                uint rew = debtInfo.debt - userShare[msg.sender].debt;
                rew = userShare[msg.sender].toClaim + rew / acc;
                if (rew > 0) {
                    userShare[msg.sender].toClaim += rew;
                    userShare[msg.sender].debt = debtInfo.debt;
                }
            } else {
                debtInfo.debt += (BNQ.balanceOf(address(this)) - debtInfo.lastBNQ) * acc / totalStake;
                userShare[msg.sender].debt = debtInfo.debt;
            }
            debtInfo.lastBNQ = BNQ.balanceOf(address(this));
        }

        user.toClaim += reward;
        user.debt = _debt;
        totalStake += amount;
        user.stakeAmount += amount;
        debt = _debt;
        lastTime = block.timestamp;
        LP.safeTransferFrom(msg.sender, address(this), amount);


        emit Stake(msg.sender, amount);
    }

    function claim() external onlyEOA {
        UserInfo storage user = userInfo[msg.sender];
        uint reward = _calculate(msg.sender);
        user.toClaim += reward;
        user.debt = countingDebt();
        user.claimed += user.toClaim;
        require(user.toClaim > 0, "no reward");
        SP.safeTransfer(msg.sender, user.toClaim);
        totalClaimed += user.toClaim;
        user.toClaim = 0;
//        _claimBNQ();
        emit Claim(msg.sender, user.toClaim);
    }

    function unStake() external {
        UserInfo storage user = userInfo[msg.sender];
        uint _debt = countingDebt();
        uint reward = _calculate(msg.sender);
        {
            debtInfo.debt += (BNQ.balanceOf(address(this)) - debtInfo.lastBNQ) * acc / totalStake;
            uint rew = debtInfo.debt - userShare[msg.sender].debt;
            rew = userShare[msg.sender].toClaim + rew / acc;
            if (rew > 0) {
                userShare[msg.sender].toClaim += rew;
                userShare[msg.sender].debt = debtInfo.debt;
            }
            debtInfo.lastBNQ = BNQ.balanceOf(address(this));
        }
        user.toClaim += reward;
        user.debt = _debt;
        totalStake -= user.stakeAmount;
        LP.safeTransfer(msg.sender, user.stakeAmount);
        SP.safeTransfer(msg.sender, user.toClaim);
        totalClaimed += user.toClaim;
        user.claimed += user.toClaim;
        user.toClaim = 0;
        user.stakeAmount = 0;
        debt = _debt;
        lastTime = block.timestamp;

        emit UnStake(msg.sender, user.stakeAmount);
    }

    function lockBNQ(uint amount) external onlyEOA {
        require(amount > 0, 'amount > 0');
        LockInfo storage lock = lockInfo[msg.sender];
        BNQ.safeTransferFrom(msg.sender, address(this), amount);
        require(lock.lockAmount == 0, 'locked');
        lock.lockAmount = amount;
        lock.startTime = block.timestamp;
        lock.endTime = block.timestamp + 30 days;
        lock.rate = amount / 200 / 86400;
        lock.claimTime = lock.endTime;
        totalLock += amount;
        debtInfo.debt += (BNQ.balanceOf(address(this)) - debtInfo.lastBNQ) * acc / totalStake;
        debtInfo.lastBNQ = BNQ.balanceOf(address(this));
    }

    function claimLock() external onlyEOA {
        LockInfo storage lock = lockInfo[msg.sender];
        require(lock.lockAmount != 0, 'not lock');
        require(block.timestamp >= lock.endTime, 'not end');
        uint rew = (block.timestamp - lock.claimTime) * lock.rate;
        bool isDone;
        if (rew + lock.claimed >= lock.lockAmount) {
            rew = lock.lockAmount - lock.claimed;
            isDone = true;
        }
        BNQ.safeTransfer(msg.sender, rew);
        totalLock -= rew;
        lock.claimTime = block.timestamp;
        if (isDone) {
            delete lockInfo[msg.sender];
        }
        debtInfo.debt += (BNQ.balanceOf(address(this)) - debtInfo.lastBNQ) * acc / totalStake;
        debtInfo.lastBNQ = BNQ.balanceOf(address(this));
    }

    function calculateLock(address addr) external view returns (uint){
        LockInfo storage lock = lockInfo[addr];
        if (block.timestamp <= lockInfo[addr].endTime) {
            return 0;
        }
        uint rew = (block.timestamp - lock.claimTime) * lock.rate;
        if (rew + lock.claimed >= lock.lockAmount) {
            rew = lock.lockAmount - lock.claimed;
        }
        return rew;
    }

    function checkNodeReward() public view returns (uint, uint){
        return (totalNodeReward, nodeReward[lastSendTime]);
    }

    function checkBNQShareInfo(address addr) public view returns (uint userClaimed, uint userToClaim, uint totalClaimedBNQ){
        userClaimed = userShare[addr].claimed;
        userToClaim = calculateBNQ(addr);
        totalClaimedBNQ = debtInfo.claimed;
    }


}