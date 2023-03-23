/**
 *Submitted for verification at BscScan.com on 2023-03-22
*/

// SPDX-License-Identifier: MIT

/*
project resources:
website: https://busd.doubler.plus
telegram: https://t.me/DOUBLER_plus
*/

pragma solidity 0.8.19;

contract BUSDDOUBLER {

    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event WithdrawReferalsBonus(address indexed user, uint256 amount);
    event WithdrawDeposit(address indexed user, uint256 index, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayedIn(address indexed user, uint256 totalAmount);
    event FeePayedOut(address indexed user, uint256 totalAmount);
    event ReinvestDeposit(address indexed user, uint256 index, uint256 amount);

    address public owner;
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    uint256 public totalInvested;
    uint256 public totalReInvested;
    uint256 public totalPenaltied;
    uint256 public totalWithdrawed;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

    struct Deposit {
        uint8 plan;
        uint256 amount;
        uint256 start;
        uint256 checkpoint;
        uint256 penalty_collected;
    }

    struct Action {
        uint8 types;
        uint256 amount;
        uint256 date;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256[3] levels;
        uint256 bonus;
        uint256 totalBonus;
        uint256 withdrawn;
        Action[] actions;
    }

    mapping(address => User) internal users;

    bool public started;
    address payable public commissionWallet;


    uint256[] public REFERRAL_PERCENTS = [10]; 
    uint256 public INVEST_MIN_AMOUNT = 15000000000000000000;  // 1
    uint256 public INVEST_MAX_AMOUNT = 10000000000000000000000; // 10000
    uint256 public PROJECT_FEE = 8; 
    uint256 constant public TIME_STEP = 1 days; // days - minutes
    uint8 private planCurrent = 0;

    IERC20 constant STABLE_TOKEN = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56); // busd_binance
    
    constructor() {
        owner = msg.sender;
        commissionWallet = payable(msg.sender);
        plans.push(Plan(20, 10));
        plans.push(Plan(5, 30));
        started = false; 
    }

    function startproject() public onlyOwner {
        started = true;
    }

    function deposit(address referrer, uint256 value) public payable {
        require(started, "Not launched");
        
        require(value >= INVEST_MIN_AMOUNT, "Deposit value is too small");
        require(value <= INVEST_MAX_AMOUNT, "Deposit limit exceeded");
        require(planCurrent < plans.length, "Invalid plan");

        uint256 fee = 0;
        if (PROJECT_FEE > 0 ) {
            fee = ( value * PROJECT_FEE) / 100;
            STABLE_TOKEN.transferFrom(msg.sender, commissionWallet, fee);
            emit FeePayedIn(msg.sender, fee);
        }

        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }

            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i] = users[upline].levels[i] + 1;
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if (upline != address(0)) {
                    uint256 amount = ( value * REFERRAL_PERCENTS[i] ) / 100;
                    users[upline].bonus = users[upline].bonus + amount;
                    users[upline].totalBonus = users[upline].totalBonus + amount;
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }


        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }

        STABLE_TOKEN.transferFrom(msg.sender, address(this), value - fee);

        user.deposits.push(Deposit(planCurrent, value, block.timestamp, block.timestamp, 0));
        user.actions.push(Action(0, value, block.timestamp));

        totalInvested = totalInvested + value;

        emit NewDeposit(msg.sender, planCurrent, value);
    }

    function withdrawreferalsbonus() public {
        User storage user = users[msg.sender];
        uint256 referralBonus = users[msg.sender].bonus;
        uint256 contractBalance = STABLE_TOKEN.balanceOf(address(this));
        
        require(referralBonus > 0, "User has no referal payments");
        require(contractBalance > referralBonus , "No enought balance. Try later");

        if (referralBonus > 0) {
            user.bonus = 0;
        }
        
        if (PROJECT_FEE > 0 ) {
            uint256 fee = ( referralBonus * PROJECT_FEE) / 100;
            STABLE_TOKEN.transfer(commissionWallet, fee);
            emit FeePayedOut(msg.sender, fee);
        }

        user.withdrawn = user.withdrawn + referralBonus;
        user.actions.push(Action(2, referralBonus, block.timestamp));
        totalWithdrawed = totalWithdrawed + referralBonus;
        STABLE_TOKEN.transfer(msg.sender, referralBonus);
        emit WithdrawReferalsBonus(msg.sender, referralBonus);
    }

    function withdrawdeposit(uint256 index) public returns (
        uint256 _index,
        uint256 _withdraw,
        uint256 _penalty_amount
        
    ) {
        require(started, "Not launched");
        
        User storage user = users[msg.sender];

        (,,,,,uint256 withdraw,,) = getUserDepositInfo(msg.sender, index);
        require(withdraw > 0, "No deposit amount");
        
        uint256 finish = user.deposits[index].start + plans[user.deposits[index].plan].time * TIME_STEP;
        if (finish > block.timestamp)
            user.deposits[index].checkpoint = block.timestamp; 
        else   
            user.deposits[index].checkpoint = finish; 

        user.withdrawn = user.withdrawn + withdraw;
        user.actions.push(Action(3, withdraw, block.timestamp));
        
        uint256 penalty_percent = 0;
        uint256 penalty_amount = 0;
        if (block.timestamp < finish) {
            penalty_percent = 100 - (block.timestamp - user.deposits[index].start) / TIME_STEP * (100 / plans[0].time);
            penalty_amount  = withdraw * penalty_percent / 100;
            user.deposits[index].penalty_collected = user.deposits[index].penalty_collected + penalty_amount;
        }

        STABLE_TOKEN.transfer(msg.sender, withdraw - penalty_amount);
        totalWithdrawed = totalWithdrawed + (withdraw - penalty_amount);
        totalPenaltied = totalPenaltied + penalty_amount;
        emit WithdrawDeposit(msg.sender, index, withdraw);

        if (PROJECT_FEE > 0 ) {
            uint256 fee = ( withdraw * PROJECT_FEE ) / 100;
            STABLE_TOKEN.transfer(commissionWallet, fee);
            emit FeePayedOut(msg.sender, fee);
        }

        return (
            index,
            withdraw - penalty_amount, 
            penalty_amount
        );
    }

    
    function getUserTotalDeposits(address userAddress) public view returns (uint256 amount) {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount + users[userAddress].deposits[i].amount;
        }
        return amount;
    }


    function getUserDepositsInfo(address userAddress) public view returns (
        uint256[] memory _index, 
        uint256[] memory _start, 
        uint256[] memory _finish, 
        uint256[] memory _amount, 
        uint256[] memory _withdrawn, 
        uint256[] memory _profit,
        bool[]    memory _is_finished
    ) {
       
        User storage user = users[userAddress];

        uint256[] memory index       = new uint256[](user.deposits.length);
        uint256[] memory start       = new uint256[](user.deposits.length);
        uint256[] memory finish      = new uint256[](user.deposits.length);
        uint256[] memory checkpoint  = new uint256[](user.deposits.length);
        uint256[] memory amount      = new uint256[](user.deposits.length);
        uint256[] memory withdrawn   = new uint256[](user.deposits.length);
        uint256[] memory profit      = new uint256[](user.deposits.length);
        bool[]    memory is_finished = new bool[](user.deposits.length);
        
        for (uint256 i=0; i< user.deposits.length; i++) {
            uint8 plan_id = user.deposits[i].plan;
            index[i]  = i;
            amount[i] = user.deposits[i].amount;
            start[i]  = user.deposits[i].start;
            checkpoint[i] = user.deposits[i].checkpoint;
            finish[i] = user.deposits[i].start + plans[plan_id].time * TIME_STEP;
            uint256 share = (amount[i] * plans[plan_id].percent / 100);
            withdrawn[i] = share * (checkpoint[i] - start[i]) / TIME_STEP;
            is_finished[i] = withdrawn[i] >= amount[i] / 100 * (plans[plan_id].time * plans[plan_id].percent)  ? true : false;

            profit[i] = 0;
            if (checkpoint[i] < finish[i]) {
                uint256 from = start[i] > checkpoint[i] ? start[i] : checkpoint[i];
                uint256 to = finish[i] < block.timestamp ? finish[i] : block.timestamp;
                if (from < to) {
                    profit[i] = share * (to - from) / TIME_STEP;
                }
            }
        }
       
        return
        (
            index,
            start,
            finish,
            amount,
            withdrawn,
            profit,
            is_finished
        );
    }

    function getUserPenalties(address userAddress) public view returns (
        uint256[] memory _index,
        uint256[] memory _penalty_percent,
        uint256[] memory _penalty_amount,
        uint256[] memory _penalty_collected
    ) {
        User storage user = users[userAddress];
        uint256[] memory index       = new uint256[](user.deposits.length);
        uint256[] memory start       = new uint256[](user.deposits.length);
        uint256[] memory finish      = new uint256[](user.deposits.length);
        uint256[] memory amount      = new uint256[](user.deposits.length);
        uint256[] memory penalty_percent   = new uint256[](user.deposits.length);
        uint256[] memory penalty_amount    = new uint256[](user.deposits.length);
        uint256[] memory penalty_collected = new uint256[](user.deposits.length);

        (index, start, finish, amount,,,) = getUserDepositsInfo(userAddress);
       
        for (uint256 i=0; i < index.length; i++) {
            uint8 plan_id = user.deposits[i].plan;
            index[i] = i;
            
            penalty_percent[i] = 0;
            if (block.timestamp < finish[i]) {
                penalty_percent[i] = 100 - (block.timestamp - start[i]) / TIME_STEP  * (100 / plans[plan_id].time);
            }
            penalty_amount[i]  = amount[i] * penalty_percent[i] / 100;
            penalty_collected[i] = user.deposits[i].penalty_collected;
        } 
        return (
            index,
            penalty_percent,
            penalty_amount,
            penalty_collected
        );
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns (
        uint8 plan_id,
        uint256 amount, 
        uint256 start, 
        uint256 finish, 
        uint256 withdrawn, 
        uint256 profit, 
        uint256 penalty_percent,
        uint256 penalty_collected
    ) {
        User storage user = users[userAddress];

        plan_id = user.deposits[index].plan;
        amount  = user.deposits[index].amount;
        start   = user.deposits[index].start;
        finish  = user.deposits[index].start + plans[plan_id].time * TIME_STEP;
        uint256 checkpoint = user.deposits[index].checkpoint;
        uint256 share      = amount * plans[plan_id].percent / 100;
        withdrawn          = share  * (checkpoint - start)   / TIME_STEP;
        penalty_collected  = user.deposits[index].penalty_collected;
        profit = 0;

        if (checkpoint < finish) {
            uint256 from = user.deposits[index].start > user.deposits[index].checkpoint ? user.deposits[index].start : user.deposits[index].checkpoint;
            uint256 to = finish < block.timestamp ? finish : block.timestamp;
            if (from < to) {
                profit = share * (to - from) / TIME_STEP;
            }
        }

        if (block.timestamp < finish) {
            penalty_percent = 100 - (block.timestamp - start) / TIME_STEP * (100 / plans[0].time);
        } else {
            penalty_percent = 0;
        }
    }


    function getSiteInfo() public view returns (
        uint256 _totalInvested, 
        uint256 _totalReInvested, 
        uint256 _totalPenaltied, 
        uint256 _totalWithdrawed, 
        uint256 _refPercent,
        uint256 _INVEST_MIN_AMOUNT,
        uint256 _INVEST_MAX_AMOUNT,
        uint256 _contractBalance
        ) 
    {
        return (
            totalInvested, 
            totalReInvested, 
            totalPenaltied, 
            totalWithdrawed, 
            REFERRAL_PERCENTS[0],
            INVEST_MIN_AMOUNT,
            INVEST_MAX_AMOUNT,
            STABLE_TOKEN.balanceOf(address(this))
        );
    }

    function getUserInfo(address userAddress) public view returns (
        uint256 totalDeposit, 
        uint256 totalWithdrawn, 
        uint256 totalReferrals,
        uint256 totalReferralBonus,
        uint256 totalReferralTotalBonus,
        uint256 totalReferralWithdrawn
        ) {
        return (
            getUserTotalDeposits(userAddress), 
            users[userAddress].withdrawn,
            users[userAddress].levels[0] + users[userAddress].levels[1] + users[userAddress].levels[2],
            users[userAddress].bonus,
            users[userAddress].totalBonus,
            users[userAddress].totalBonus - users[userAddress].bonus
            );
    }
    
}


interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}