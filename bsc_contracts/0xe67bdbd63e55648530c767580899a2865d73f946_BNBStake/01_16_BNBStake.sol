// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";


contract BNBStake is Initializable, ReentrancyGuardUpgradeable, AccessControlUpgradeable {
    using SafeMathUpgradeable for uint;

    bytes32 public constant JOB_ROLE = keccak256("JOB_ROLE");


    address _feeAddress;
    uint _feeRate;
    uint _totalFee;
    uint _totalUser;

    function initialize(address feeAddress, uint feeRate) initializer public {
        __ReentrancyGuard_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(JOB_ROLE, msg.sender);
        _initProduct();
        _feeAddress = feeAddress;
        _feeRate = feeRate;

    }

    mapping(uint => mapping(uint => uint)) dayToAmountToRewardRate;

    function _initProduct() internal {
        dayToAmountToRewardRate[1][5 * 1e15] = 35;
        dayToAmountToRewardRate[1][1 * 1e16] = 70;
        dayToAmountToRewardRate[1][3 * 1e16] = 70;
        dayToAmountToRewardRate[1][5 * 1e16] = 84;
        dayToAmountToRewardRate[1][10 * 1e16] = 105;

        //        dayToAmountToRewardRate[7][5 * 1e17] = 35;
        //        dayToAmountToRewardRate[7][1 * 1e18] = 70;
        //        dayToAmountToRewardRate[7][3 * 1e18] = 70;
        //        dayToAmountToRewardRate[7][5 * 1e18] = 84;
        //        dayToAmountToRewardRate[7][10 * 1e18] = 105;
    }

    function setProduct(uint _day,uint _totalAmount,uint _rewardsRate) external onlyRole(DEFAULT_ADMIN_ROLE){
        dayToAmountToRewardRate[_day][_totalAmount] = _rewardsRate;
    }


    struct Deposit {
        uint duration;
        uint paidAmount;
        uint totalAmount;
        uint rewards;
        uint contractTime;
        uint createTime;
        uint finishTime;
        bool finished;
        bool isReReserved;
    }

    struct User {
        address upline;
        Deposit[] deposits;
        address[] reffers;
        uint level;

        uint unClaimedRefferRewards;
        uint winthdrawnClaimedRefferRewards;
        mapping(uint => uint) refferLevelToCount;
        uint teamLevel1Count;
        uint teamUserCount;
        uint createTime;
        uint unClaimedGlobalDividend;
        uint claimedClaimedGlobalDividend;

    }

    mapping(address => User) public users;
    address public f;
    address[] allUser;
    address[] allLevel6User;



    struct LogUserRefferRewards{
        address reffer;
        uint rewards;
        uint dateTime;
    }
    mapping(address => LogUserRefferRewards[]) public logUserRefferRewards;

    uint lastGolalDividend;

    event DividendToLevel6User(uint lastGolalDividend,uint length);

    function dividendToLevel6User() public onlyRole(JOB_ROLE){
        uint base = 5614035100000000;
        lastGolalDividend = (random(99) * 1e13) + base;

        for(uint i;i < allLevel6User.length;i++){
            users[allLevel6User[i]].unClaimedGlobalDividend += lastGolalDividend ;
        }
        emit DividendToLevel6User(lastGolalDividend,allLevel6User.length);
    }

    function getUserRefferLevelCount(address addr,uint level) view external returns(uint ){
        return users[addr].refferLevelToCount[level];
    }

    function claimGloblaDivend()  external nonReentrant{
        uint divdends = users[msg.sender].unClaimedGlobalDividend;
        require(divdends > 0,'divdends zero');

        payable(msg.sender).transfer(divdends);
        users[msg.sender].unClaimedGlobalDividend -= divdends;

    }


    function getLogUserRefferRewards(address addr) external view returns( LogUserRefferRewards[] memory){
        LogUserRefferRewards[] memory  logUserReffers = logUserRefferRewards[addr];
        LogUserRefferRewards[] memory logs = new LogUserRefferRewards[](logUserReffers.length);
        for(uint i;i<logUserReffers.length;i++){
            logs[i] = logUserReffers[i];
        }
        return logs;
    }

    function setUpline(address up) external {
        require(up != address(0), 'address can not be zero');
        require(up != msg.sender, 'upline can not be yourself');
        require(users[msg.sender].upline == address(0), 'already exit');
        require(users[users[msg.sender].upline].upline != msg.sender, 'already exit1');
        users[msg.sender].upline = up;
        users[msg.sender].createTime = block.timestamp;
        users[up].reffers.push(msg.sender);

        address _up = up;

        for (uint i; i < 50; i++) {
            if (_up == address(0)) {
                break;
            }
            users[_up].teamUserCount++;
            _up = users[_up].upline;
        }

        if (_totalUser == 0) {
            f = up;
        }

        if (users[msg.sender].level == 0) {
            _totalUser++;
        }

    }


    function random(uint number) private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,
            msg.sender))) % number;
    }

    function reserve(uint duration_) external payable {
        User storage user = users[msg.sender];
        require(user.upline != address(0), 'set upline before');
        uint _totalAmount = msg.value * 100 / 20;
        require(dayToAmountToRewardRate[duration_][_totalAmount] > 0, 'amount wrong');


        Deposit[] storage usersDeposits = user.deposits;

        for (uint i = 0; i < usersDeposits.length; i++) {
            if (!usersDeposits[i].finished) {


                require(usersDeposits[i].totalAmount * 20 / 100 <= msg.value && usersDeposits[i].isReReserved == false, 'repeat');

                if (usersDeposits[i].contractTime > 0
                    && block.timestamp >= (usersDeposits[i].contractTime + (usersDeposits[i].duration * 1 days))) {
                    usersDeposits[i].isReReserved = true;
                } else {
                    revert('repeat');
                }
            }
        }

        user.deposits.push(Deposit({
            duration : duration_,
            paidAmount : msg.value,
            totalAmount : msg.value * 5,
            rewards : 0,
            contractTime : 0,
            createTime : block.timestamp,
            finishTime : 0,
            finished : false,
            isReReserved : false
        }));


        emit Reserve(msg.sender, duration_, msg.value);

    }

    event Reserve(address user, uint duration, uint amount);


    function update(address addr, uint level) private returns(bool){
        uint oldLevel = users[addr].level;
        if(oldLevel==0 && level>1){
            return false;
        }
        if(oldLevel >= level){
            return false;
        }
        if(level == 6){
            allLevel6User.push(addr);
        }
        users[addr].level = level;
        if (address(0) != users[addr].upline) {
            users[users[addr].upline].refferLevelToCount[level]++;
            if(users[users[addr].upline].refferLevelToCount[oldLevel] >0){
                users[users[addr].upline].refferLevelToCount[oldLevel]--;
            }
            updateLevel(users[addr].upline);
        }

        return true;
    }


    function contracted(uint dopIndex) external payable {
        Deposit storage dop = users[msg.sender].deposits[dopIndex];
        require(block.timestamp <= dop.createTime + 10 days, 'expired');
        require(dop.paidAmount == (dop.totalAmount * 20 / 100) && msg.value == (dop.totalAmount * 80 / 100), 'contracted wrong');
        dop.paidAmount += msg.value;
        dop.contractTime = block.timestamp;
        User storage user = users[msg.sender];
        if (user.level == 0) {
            address up = user.upline;
            allUser.push(msg.sender);
             bool upRes = update(msg.sender, 1);
            address _up = up;
            for (uint i; i < 50; i++) {
                if (_up == address(0)) {
                    break;
                }
                if(upRes){
                    users[_up].teamLevel1Count++;
                }
                updateLevel(_up);

                _up = users[_up].upline;
            }
        }

        updateLevel(msg.sender);

        emit Contracted(msg.sender, dopIndex);
    }

    function updateLevel(address addr) private {
        mapping(uint => uint ) storage levelToCount = users[addr].refferLevelToCount;
        if ((levelToCount[5] +levelToCount[6] )> 0 && users[addr].level == 5) {
            update(addr, 6);
        } else if ((levelToCount[2] + levelToCount[3] + levelToCount[4] + levelToCount[5] + levelToCount[6]) >= 5) {
            update(addr, 5);
        } else if ((levelToCount[2] + levelToCount[3] + levelToCount[4] + levelToCount[5] + levelToCount[6]) >= 4) {
            update(addr, 4);
        } else if ((levelToCount[2] + levelToCount[3] + levelToCount[4] + levelToCount[5] + levelToCount[6]) >= 3) {
            update(addr, 3);
        } else if ((levelToCount[1] + levelToCount[2] + levelToCount[3] + levelToCount[4] + levelToCount[5] + levelToCount[6]) >= 3 && users[addr].teamLevel1Count >= 10) {
            update(addr, 2);
        }

    }

    event Contracted(address user, uint dopIndex);

    function claim() external onlyRole(DEFAULT_ADMIN_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    function setFeeAddressAndRate(address feeAddress, uint feeRate) external onlyRole(DEFAULT_ADMIN_ROLE) returns (bool){
        require(feeAddress != address(0), 'can not be zero address ');
        require(feeRate < 50, 'feeRate wrong');
        _feeAddress = feeAddress;
        _feeRate = feeRate;
        return true;
    }


    function withdrawn(uint dopIndex) external nonReentrant {
        Deposit storage dop = users[msg.sender].deposits[dopIndex];
        require(!dop.finished, 'dop finished');
        require(dop.isReReserved, 'dop has not reReserved');
        require(block.timestamp >= (dop.contractTime + (dop.duration * 1 days)), 'dop has not reReserved');
        uint _rewards = dop.paidAmount * dayToAmountToRewardRate[dop.duration][dop.paidAmount] / 1000;

        payable(msg.sender).transfer(_rewards + dop.paidAmount);

        dop.rewards = _rewards;
        updateUplineRewards(msg.sender, dop);
        dop.finished = true;
        dop.finishTime = block.timestamp;
        emit  Withdrawn(msg.sender, dop.paidAmount + _rewards);
    }


    event Withdrawn(address user, uint amount);

    function withdrawnUnClaimedRefferRewards() external nonReentrant {
        require(users[msg.sender].unClaimedRefferRewards > 0, 'no unClaimedRefferRewards');
        users[msg.sender].winthdrawnClaimedRefferRewards += users[msg.sender].unClaimedRefferRewards;

        uint fee = users[msg.sender].unClaimedRefferRewards * _feeRate / 100;

        _totalFee += fee;

        payable(msg.sender).transfer(users[msg.sender].unClaimedRefferRewards - fee);
        payable(_feeAddress).transfer(fee * 15/100);
        payable(address(0x801795a8992aE87e11478F9D9Db810FD5d035599)).transfer(fee * 20/100);
        payable(address(0xC366c22973787f08ae8e77AED82473e920026bEC)).transfer(fee * 20/100);
        payable(address(0x9ae812c03C6688C2242F35AD645396c255FDB1eE)).transfer(fee * 25/100);
        payable(address(0x6A3887FAEfbF795520C9aACA4C49613e9D595513)).transfer(fee * 20/100);

        emit WithdrawnUnClaimedRefferRewards(msg.sender, users[msg.sender].unClaimedRefferRewards - fee, fee);

        users[msg.sender].unClaimedRefferRewards = 0;

    }

    event WithdrawnUnClaimedRefferRewards(address user, uint amount, uint fee);


    function getTotal() external view onlyRole(DEFAULT_ADMIN_ROLE) returns (uint totalFee, uint totalUser){
        totalFee = _totalFee;
        totalUser = _totalUser;
    }

    function getUserTotalAssets(address addr) external view returns (uint total){
        Deposit[] memory dops = users[addr].deposits;

        for (uint i; i < dops.length; i++) {
            if (dops[i].contractTime > 0 && !dops[i].finished) {

                uint rate = dayToAmountToRewardRate[dops[i].duration][dops[i].totalAmount];

                uint nowTime = block.timestamp;
                if (block.timestamp > (dops[i].contractTime + (dops[i].duration * 1 days))) {
                    nowTime = dops[i].contractTime + (dops[i].duration * 1 days);
                }

                uint days_ = (nowTime - dops[i].contractTime) / 1 days;
                uint rewards_ = dops[i].paidAmount * rate * days_ / 1000 / dops[i].duration;

                total += (rewards_ + dops[i].paidAmount);
            }
        }
    }

    function getTodayRewars(address addr) external view returns (uint rewards){

        Deposit[] memory dops = users[addr].deposits;
        for (uint i; i < dops.length; i++) {
            if (dops[i].contractTime > 0 && !dops[i].finished && block.timestamp <= (dops[i].contractTime + (dops[i].duration * 1 days))) {

                uint rate = dayToAmountToRewardRate[dops[i].duration][dops[i].totalAmount];


                uint rewards_ = dops[i].paidAmount * rate / 1000 / dops[i].duration;

                uint r = (block.timestamp - dops[i].contractTime) / (1 days);
                if (r > 0) {
                    rewards += rewards_;
                }


            }
        }
    }


    function updateUplineRewards(address addr_, Deposit storage dop) private {
        address upline = users[addr_].upline;
        for (uint i; i < 50; i++) {
            if (upline == address(0)) {
                break;
            }
            Deposit memory uplineDop = getActiveDeposit(upline);

            uint _duration = dop.duration;
            uint _totalAmount = MathUpgradeable.min(uplineDop.totalAmount,dop.totalAmount);

            uint _rewards =  _totalAmount * dayToAmountToRewardRate[_duration][_totalAmount]/1000;

            if (users[upline].level > i && i == 0) {
                _rewards = _rewards;
            }else if (users[upline].level > i && i == 1) {
                _rewards = (_rewards * 40 / 100);
            }else if (users[upline].level > i && i == 2) {
                _rewards = (_rewards * 20 / 100);
            }else if (users[upline].level > i && i == 3) {
                _rewards = (_rewards * 2 / 100);
            }else if (users[upline].level >= 5 && i > 3) {
                _rewards= (_rewards * 2 / 100);
            }else{
                _rewards = 0;
            }

            if(_rewards > 0){
                logUserRefferRewards[upline].push(LogUserRefferRewards({
                    reffer: addr_,
                    rewards: _rewards,
                    dateTime: block.timestamp
                }));
                users[upline].unClaimedRefferRewards += _rewards;
            }
            upline = users[upline].upline;
        }

    }

    function getDeposit(address addr_, uint dopIndex) public view returns (Deposit memory){
        return users[addr_].deposits[dopIndex];
    }

    function getDeposits(address addr_) public view returns (Deposit [] memory){
        return users[addr_].deposits;
    }

    function getActiveDeposit(address addr_) public view returns(Deposit memory dop){
        Deposit [] memory dops = getDeposits(addr_);
        for(uint i;i<dops.length;i++){
            if(!dops[i].finished){
                dop = dops[i];
                break;
            }
        }
    }

    function userReffers(address addr_) public view returns (address[] memory reffers){
        reffers = users[addr_].reffers;
    }


}