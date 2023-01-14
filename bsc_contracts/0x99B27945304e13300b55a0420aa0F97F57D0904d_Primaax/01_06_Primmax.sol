// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Primaax is ERC20, Ownable {

    IERC20 public usdt;
    address public referral;
    uint256 public totalUser;
    uint256 public totalDeposited;
    uint256 public totalMinted;
    uint256 public totalStaked;
    uint256 public constant MAX_SUPPLY = 2000000000e18;
    uint256 public constant RATE = 10000;
    uint256 public constant MIN_WITHDRAWAL = 25 * 10 ** 18;
    uint256 public constant TIME_COUNT = 1 days;
    uint8[7] public BONUS_PERCENT = [10, 5, 3, 2, 2, 3, 5];
    uint256[10] public GROUP_REWARD = [10000e18, 100000e18, 100000e18, 100000e18, 500000e18, 500000e18, 1000000e18, 2500000e18, 5000000e18, 10000000e18];
    uint8[10] public FLUSH_TIME = [90, 90, 90, 60, 60, 30, 30, 30, 30, 30];

    struct Deposit {
		uint256 amount;
		uint256 start;
        uint256 end;
        uint8 planId;
	}
    
    struct WithdrawHistory {
        uint256 amount;
        uint256 time;
        string typeOfW;
    }

    struct Group {
        address legOne;
        address legTwo;
        address[] legThree;
        uint256 highest;
        uint256 second;
        uint256 rest;
        uint8 level;
    }

    struct User {
        Deposit[] deposits;
        WithdrawHistory[] pastWiths;
        address referrer;
        uint256 totalAllBonus;
        uint256 totalRefBonus;
        uint256 totalStakeBonus;
        uint256 totalGroupBonus;
        uint256 totalStake;
        uint256 totalClaimed;
        uint256 totalDownline;
        uint256 totalGroupSales;
        uint256 totalGroupClaimed;
        uint256 flushAmt;
        uint256 flushDeathline;
        uint256 packId;
    }

    struct Plan {
        uint256 minAmt;
        uint256 ror;
    }

    mapping(address => User) public userInfo;
    mapping(uint8 => Plan) public plan;
    mapping(address => address[]) public downline;
    mapping(address => Group) public groupInfo;

    event BuyPMX(address user, uint256 usdAmt, uint256 pmxAmt);
    event NewStake(address user, uint256 amount, uint256 start, uint8 planId);
    event Referral(address user, address upline);
    event Withdraw(address user, uint256 amount);
    event GroupClaim(address user, uint256 amount);

    constructor (address _usdtAddress) ERC20 ("PRIMMAX", "PRIMM") {
        usdt = IERC20(_usdtAddress);

        Plan storage plan1 = plan[0];
        Plan storage plan2 = plan[1];
        Plan storage plan3 = plan[2];

        plan1.minAmt = 250 * 10 ** 18;
        plan1.ror = 5000;

        plan2.minAmt = 10000 * 10  ** 18;
        plan2.ror = 7000;

        plan3.minAmt = 50000 * 10  ** 18;
        plan3.ror = 10000;

        referral = msg.sender;
    }

    function userStakes(address _userAddr, uint256 _index) external view returns (uint256 amt, uint256 start, uint256 end, uint8 plan_id) {
        User memory u = userInfo[_userAddr];
        Deposit memory dep = u.deposits[_index];
        return (dep.amount, dep.start, dep.end, dep.planId);
    }

    function userPastWiths(address _userAddr, uint256 _index) external view returns (uint256 amt, uint256 time) {
        User memory u = userInfo[_userAddr];
        WithdrawHistory memory wih = u.pastWiths[_index];
        return (wih.amount, wih.time);
    }

    function deposit(uint256 _amount) external {
        require(_amount >= 1e18, "Min $1");
        require(totalMinted + _amount * 10 <= MAX_SUPPLY, "Max supply hit");
        usdt.transferFrom(msg.sender, address(this), _amount);

        _mint(msg.sender, _amount * 10);
        totalMinted += _amount * 10;
        totalDeposited += _amount;
        emit BuyPMX(msg.sender, _amount, _amount * 10);
    }

    function stake(address _referrer, uint256 _amount, uint8 _planId) external {
        uint256 stakeAmt = _amount;
        require(stakeAmt >= 250 * 10 ** 18, 'Min 250 PMX');
        require(_planId >= 0 && _planId < 3, "Invalid Plan Id");
        require(stakeAmt >= plan[_planId].minAmt, "Insufficient amount");
        require(_referrer == referral || userInfo[_referrer].deposits.length > 0 && _referrer != msg.sender,  "No upline found");

        totalStaked += stakeAmt;
        _burn(msg.sender, stakeAmt);

        //Check user's referral
        address upline_addr = _checkRef(msg.sender, _referrer);

        //Update user's upline referral bonus
        _calRefBonus(upline_addr, stakeAmt);

        //Update all group member's flush amount
        _updateGroupAmt(upline_addr, stakeAmt);

        //Calculate user's downline sales
        (uint8 ftd, uint8 ttd, uint8 otd, uint8 fh) = _calCurrentLevel(msg.sender);

        User storage user = userInfo[msg.sender];

        if(user.flushDeathline < block.timestamp) {
            Group storage gi = groupInfo[msg.sender];

            user.flushDeathline = block.timestamp + FLUSH_TIME[gi.level] * TIME_COUNT;

            for(uint256 i = 0; i < downline[msg.sender].length; i++) {
                User storage direct_down = userInfo[downline[msg.sender][i]];
                if(i == 0) {
                }
                else {
                    direct_down.flushAmt = 0;
                }
            }
        }

        user.flushAmt += stakeAmt;

        user.totalStake += stakeAmt;
        if(user.packId != 7) {
            if (user.totalStake >= 50000e18 && ftd >= 7) {
                user.packId = 7;
            } else if (user.totalStake >= 30000e18 && ttd >= 6) {
                user.packId = 6;
            } else if (user.totalStake >= 10000e18 && otd >= 5) {
                user.packId = 5;
            } else if (user.totalStake >= 5000e18 && fh >= 2) {
                user.packId = 4;
            } else{
                user.packId = 3;
            }
        }

        user.deposits.push(Deposit(stakeAmt, block.timestamp + TIME_COUNT, block.timestamp + (366 * TIME_COUNT), _planId));

        emit NewStake(msg.sender, stakeAmt, block.timestamp + TIME_COUNT, _planId);
    }

    function _checkRef(address _user, address _referrer) internal returns (address) {
        address upline_addr = _referrer;
        User storage user = userInfo[_user];
        if (user.referrer == address(0)) {
            if (userInfo[upline_addr].totalStake < 250 * 10 ** 18) {
                upline_addr = referral;
            }
            
            user.referrer = upline_addr;

            downline[user.referrer].push(_user);

            User storage upline = userInfo[user.referrer];
            Group storage gupline = groupInfo[user.referrer];

            if( downline[user.referrer].length == 1) {
                gupline.legOne = _user;
            }

            upline.totalDownline++;
            totalUser++;
            emit Referral(_user, upline_addr);
        }
        return user.referrer;
    }

    function _calRefBonus(address _upline, uint256 _stakeAmt) internal {
        address upline_addr = _upline;
        uint256 stakeAmt = _stakeAmt;
        for(uint256 i = 0; i < 7; i++) {
            User storage upline = userInfo[upline_addr];
            if(upline_addr == referral) {
                break;
            }

            if(upline.packId - 1 >= i) {
                upline.totalAllBonus += BONUS_PERCENT[i] * stakeAmt / 100;
                upline.totalRefBonus += BONUS_PERCENT[i] * stakeAmt / 100;
            }
            
            upline_addr = upline.referrer;
        }
    }

    function _updateGroupAmt(address _upline, uint256 _stakeAmt) internal {
        address upline_addr = _upline;
        uint256 stakeAmt = _stakeAmt;
        for(uint256 i = 0; i < 15; i++) {
            User storage upline = userInfo[upline_addr];
            if(upline_addr == referral) {
                break;
            }

            upline.totalGroupSales += stakeAmt;
            upline.flushAmt += stakeAmt;
            upline_addr = upline.referrer;
        }
    }

    function _calCurrentLevel(address _user) internal view returns (uint8, uint8, uint8, uint8) {
        address user = _user;
        uint8 ftd;
        uint8 ttd;
        uint8 otd;
        uint8 fh;

        for(uint256 i = 0; i < downline[user].length; i++) {
            User memory direct_down = userInfo[downline[user][i]];
            if (direct_down.totalStake >= 30000e18)
                ftd++;
            if (direct_down.totalStake >= 20000e18)
                ttd++;
            if (direct_down.totalStake >= 10000e18)
                otd++;
            if (direct_down.totalStake >= 5000e18)
                fh++;

        }
        return (ftd, ttd, otd, fh);
    }

    function userReward(address _user) external view 
    returns(uint gTotalBonus, uint sTotalBonus, uint refTotalBonus, uint totalBonus, uint rClaimed, uint gSales, uint gEnd) {
        address puser = _user;
        User memory user = userInfo[puser];
        uint256 bonus = 0;

        for(uint256 i = 0; i < user.deposits.length; i++) {
            if(block.timestamp > user.deposits[i].start && block.timestamp - user.deposits[i].start > TIME_COUNT) {
                bonus += user.deposits[i].amount * plan[user.deposits[i].planId].ror * ((block.timestamp - user.deposits[i].start) / TIME_COUNT  > 365 ? 365 : (block.timestamp - user.deposits[i].start) / TIME_COUNT ) / RATE / 365;
            }
        }
        
        uint256 theRest;
        uint256 theSecond;
        uint256 lowest;
        uint256 groupBonus;

        Group memory gi = groupInfo[puser];
        for(uint256 i = 0; i < downline[puser].length; i++) {
            User memory direct_down = userInfo[downline[puser][i]];

            if (i == 0) {
                gi.highest = direct_down.flushAmt - user.totalGroupClaimed;
            } else {
                if(direct_down.flushAmt >= theSecond) {
                    theRest += theSecond;
                    theSecond = direct_down.flushAmt;
                }
                else {
                    theRest += direct_down.flushAmt;
                }
            }
        }

        gi.rest = theRest;
        gi.second = theSecond;
        lowest = theRest;
        
        if(gi.rest > gi.second) {
            lowest = gi.second;
        }

        if (lowest > gi.highest) {
            lowest = gi.highest;
        }

        uint256 rewards = GROUP_REWARD[gi.level];
        if( user.flushDeathline > block.timestamp && gi.level < 10 ) {
            if(lowest >= rewards && user.totalStake >= rewards * 25 / 100) {
                groupBonus = rewards;
            }
        }
  
        user.totalGroupBonus += groupBonus;
        user.totalStakeBonus = bonus;
        user.totalAllBonus = user.totalStakeBonus + user.totalGroupBonus + user.totalRefBonus;

        return (user.totalGroupBonus, user.totalStakeBonus, user.totalRefBonus, user.totalAllBonus, user.totalClaimed, user.totalGroupSales, user.flushDeathline );
    }

    function userGroupInfo(address _user) external view returns(
        address a, address b, 
        uint256 gOneAmt, uint256 gTwoAmt, uint256 gRestAmt, uint8 gLevel, uint256 gLength) {
        address puser = _user;
        uint256 theRest = 0;
        uint256 theSecond = 0;
        User memory user = userInfo[puser];
        Group memory gi = groupInfo[puser];
        for(uint256 i = 0; i < downline[puser].length; i++) {
            User memory direct_down = userInfo[downline[puser][i]];
            if(i == 0) {
                gi.highest = direct_down.flushAmt - user.totalGroupClaimed;
            }
            else {
                if (direct_down.flushAmt >= theSecond) {
                    theRest += theSecond;
                    theSecond = direct_down.flushAmt;
                    gi.legTwo = downline[puser][i];
                }
                else {
                    theRest += direct_down.flushAmt;
                }
            }
        }

        return (gi.legOne, gi.legTwo, gi.highest, theSecond, theRest, gi.level, downline[puser].length);
    }

    function withdraw() external {
        User storage user = userInfo[msg.sender];
        uint256 bonus = 0;
        for(uint256 i = 0; i < user.deposits.length; i++) {
            if(block.timestamp > user.deposits[i].start && block.timestamp - user.deposits[i].start > TIME_COUNT) {
                bonus += user.deposits[i].amount * plan[user.deposits[i].planId].ror * ((block.timestamp - user.deposits[i].start) / TIME_COUNT  > 365 ? 365 : (block.timestamp - user.deposits[i].start) / TIME_COUNT ) / RATE / 365;            
            }
        }
        
        user.totalStakeBonus = bonus;
        user.totalAllBonus = user.totalStakeBonus + user.totalGroupBonus + user.totalRefBonus;
        uint256 claimable = user.totalAllBonus - user.totalClaimed;

        require(claimable / 10 >= MIN_WITHDRAWAL, "Min 25 USD");
        usdt.transfer(msg.sender, claimable / 10);

        user.totalClaimed += claimable;
        user.pastWiths.push(WithdrawHistory(claimable / 10, block.timestamp, 'stake'));
        emit Withdraw(msg.sender, claimable / 10);
    }

    function groupClaim() external {
        User storage user = userInfo[msg.sender];

        uint256 lowest;
        uint256 theRest;
        uint256 theSecond;
        uint256 groupBonus;
        Group storage gi = groupInfo[msg.sender];
        delete gi.legThree;
        for(uint256 i = 0; i < downline[msg.sender].length; i++) {
            User storage direct_down = userInfo[downline[msg.sender][i]];
            if(i == 0) {
                gi.highest = direct_down.flushAmt - user.totalGroupClaimed;
            }
            else {
                if(direct_down.flushAmt >= theSecond) {
                    theRest += theSecond;
                    theSecond = direct_down.flushAmt;
                    if(gi.legTwo != address(0) ) {
                        gi.legThree.push(gi.legTwo);
                    }
                    gi.legTwo = downline[msg.sender][i];
                }
                else {
                    gi.legThree.push(downline[msg.sender][i]);
                    theRest += direct_down.flushAmt;
                }
                direct_down.flushAmt = 0;
            }
        }
        gi.rest = theRest;
        gi.second = theSecond;
        lowest = theRest;

        if(gi.rest > gi.second) {
            lowest = gi.second;
        }

        if (lowest > gi.highest) {
            lowest = gi.highest;
        }

        uint256 rewards = GROUP_REWARD[gi.level];
        if( user.flushDeathline > block.timestamp && gi.level < 10 ) {
            if(lowest >= rewards && user.totalStake >= rewards * 25 / 100) {
                groupBonus = rewards;
                gi.level += 1;
                
                if(gi.level == 10) {
                    user.flushDeathline = block.timestamp;
                } else {
                    user.flushDeathline = block.timestamp + FLUSH_TIME[gi.level] * TIME_COUNT;
                }
            }
        } else {
            user.flushDeathline = block.timestamp + FLUSH_TIME[gi.level] * TIME_COUNT;
        }

        user.totalGroupClaimed += groupBonus;
        user.totalGroupBonus += groupBonus;
        user.totalAllBonus = user.totalStakeBonus + user.totalGroupBonus + user.totalRefBonus;
        uint256 claimable = groupBonus;

        require(claimable / 10 >= 1e18, "Min 1$");
        usdt.transfer(msg.sender, claimable / 10);

        user.totalClaimed += claimable;

        user.pastWiths.push(WithdrawHistory(claimable / 10, block.timestamp, 'group'));
        emit GroupClaim(msg.sender, claimable / 10);
    }

    function getDepositLength(address _userAddr) external view returns(uint){
        User memory u = userInfo[_userAddr];
        return u.deposits.length;
    }

    function getWithdrawHistoryLength(address _userAddr) external view returns(uint){
        User memory u = userInfo[_userAddr];
        return u.pastWiths.length;
    }

    function ownerWithdraw(uint256 _amount) external onlyOwner {
        usdt.transfer(msg.sender, _amount);
    }

    function otherTokenWithdraw(address _contract, uint256 _amount) external onlyOwner {
        IERC20(_contract).transfer(msg.sender, _amount);
    }

}