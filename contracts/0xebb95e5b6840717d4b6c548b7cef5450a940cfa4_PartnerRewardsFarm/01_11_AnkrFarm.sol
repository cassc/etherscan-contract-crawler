// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.18;

import "communal/SafeERC20.sol";
import "local/interfaces/IvdUSH.sol";
import "communal/ReentrancyGuard.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import "openzeppelin/utils/math/SignedSafeMath.sol";


// ================================================================
// Allows vdUSH stakers to claim farm rewards from partner tokens
// Users can claim their rewards at any time
// No staking needed, just looks up staked balances from vdUSH farm
// No user deposits held in this contract!
// Author: unshETH team (github.com/unsheth)
// Heavily inspired by StakingRewards, MasterChef

interface IGovFarm {
    function getAllUsers() external view returns (address[] memory);
    function totalSupplyMultiplier() external view returns (uint);
    function isInMatrix(address user) external view returns (bool);
}

contract PartnerRewardsFarm is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    IvdUSH public constant vdUsh = IvdUSH(0xd027Ef82dB658805C9Ba8053196cD6ED1Dd407E4);
    IERC20 public immutable rewardToken;

    IGovFarm public govFarm; //govFarm contract
    uint public startTime; //start time of the farm
    uint public rewardPerSec;

    mapping(address => uint) public lastClaimTimestamp;
    mapping(address => uint) public lastClaimVdUshBalance;
    mapping(address => uint) public lastClaimTotalSupply;
    mapping(address => bool) public isBlocked; //if a user is blocked from claiming rewards

    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint ts;
        uint blk; // block
    }
    uint internal constant WEEK = 1 weeks;

    event RewardsClaimed(address indexed _user, uint _rewardClaimed);
    event RewardPerSecUpdated(uint _rewardPerSec);
    event GovFarmUpdated(address _govFarmAddress);
    event BlockListUpdated(address indexed _user, bool _isBlocked);
    event FarmStarted(uint _rewardPerSec, uint _startTime);

    //Constructor
    constructor(address _govFarmAddress, address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
        govFarm = IGovFarm(_govFarmAddress);
    }

    /**
     * @dev Calculate user's earned USH and vdUSH rewards since last claim.
     * User earned rewards are proportional to their share of total vdUSH at the time of claim.
     * @param user The address of the user entering the matrix.
     */
    function earned(address user) public view returns (uint) {
        require(govFarm.isInMatrix(user), "User not in matrix");
        require(startTime!= 0 && block.timestamp > startTime, "Farm not started");
        require(!isBlocked[user], "User is blocked from claiming rewards");

        uint lastClaimTimeStamp = lastClaimTimestamp[user] == 0 ? startTime : lastClaimTimestamp[user];

        uint secsSinceLastClaim = block.timestamp - lastClaimTimeStamp;
        uint lastEpoch = vdUsh.user_point_epoch(user);
        uint lastEpochTimestamp = vdUsh.user_point_history__ts(user, lastEpoch);

        uint userVdUsh;
        uint totalVdUsh;

        userVdUsh = lastClaimVdUshBalance[user];
        totalVdUsh = lastClaimTotalSupply[user];

        //sampling:
        //fyi we start at i=1, bc i=0 is the lastClaim which is already stored
        for(uint i = 1; i < 53;) {
            uint timestamp = lastClaimTimeStamp + i * 1 weeks;
            //if 1 wk after last claim is after current block timestamp, break
            if(timestamp > block.timestamp) {
                userVdUsh += vdUsh.balanceOf(user);
                totalVdUsh += vdUsh.totalSupply();
                break;
            }
            //round down to nearest week if needed
            if(timestamp > lastEpochTimestamp) {
                timestamp = lastEpochTimestamp;
            }

            userVdUsh += vdUsh.balanceOfAtT(user, timestamp);
            //calculate totalSupplyAtT internally due to versioning issue in ve-contracts
            totalVdUsh += _totalSupplyAtT(timestamp);

            unchecked{ ++i; }
        }

        uint averageVdUshShare = userVdUsh * 1e18 / totalVdUsh;
        uint claimable = averageVdUshShare * secsSinceLastClaim * rewardPerSec / 1e18 * govFarm.totalSupplyMultiplier() / 1e18;

        return claimable;
    }


    /*
    ============================================================================
    Calculations to get correct total supply at historical point T
    ============================================================================
    */

    function _get_point_history(uint _epoch) internal view returns (Point memory) {
        (int128 bias, int128 slope, uint ts, uint blk) = vdUsh.point_history(_epoch);
        return Point(bias, slope, ts, blk);
    }

    function _totalSupplyAtT(uint t) internal view returns (uint) {
        uint _epoch = vdUsh.epoch();
        Point memory last_point = _get_point_history(_epoch);
        return _supply_at(last_point, t);
    }

    function _supply_at(Point memory point, uint t) internal view returns (uint) {
        Point memory last_point = point;
        uint t_i = (last_point.ts / WEEK) * WEEK;
        for (uint i = 0; i < 255; ++i) {
            t_i += WEEK;
            int128 d_slope = 0;
            if (t_i > t) {
                t_i = t;
            } else {
                d_slope = vdUsh.slope_changes(t_i);
            }
            last_point.bias -= last_point.slope * int128(int(t_i) - int(last_point.ts));
            if (t_i == t) {
                break;
            }
            last_point.slope += d_slope;
            last_point.ts = t_i;
        }

        if (last_point.bias < 0) {
            last_point.bias = 0;
        }
        return uint(uint128(last_point.bias));
    }

    /*
    ============================================================================
    Claim
    ============================================================================
    */

    function claim(address user) external nonReentrant {
        uint claimable = earned(user);
        require(claimable > 0, "Nothing to claim");

        lastClaimTimestamp[user] = block.timestamp;
        lastClaimVdUshBalance[user] = vdUsh.balanceOf(user);
        lastClaimTotalSupply[user] = vdUsh.totalSupply();
        rewardToken.safeTransfer(user, claimable);
        emit RewardsClaimed(user, claimable);
    }

    //view funcs
    function getAllUsers() public view returns (address[] memory) {
        return govFarm.getAllUsers();
    }

    function getVdUshTotalSupplyInFarm() public view returns (uint) {
        uint totalVdUsh;
        address[] memory users = getAllUsers();
        for(uint i = 0; i < users.length;) {
            uint vdUshBalance = isBlocked[users[i]] ? 0 : vdUsh.balanceOf(users[i]);
            totalVdUsh += vdUshBalance;
            unchecked{ ++i; }
        }
        return totalVdUsh;
    }

    //owner funcs
    function startFarm(uint _rewardPerSec) external onlyOwner {
        require(startTime == 0, "Farm already started");
        rewardPerSec = _rewardPerSec;
        startTime = block.timestamp;
        emit FarmStarted(_rewardPerSec, startTime);
    }

    function setRewardPerSec(uint _rewardPerSec) external onlyOwner {
        rewardPerSec = _rewardPerSec;
        emit RewardPerSecUpdated(_rewardPerSec);
    }

    function updateGovFarm(address _govFarmAddress) external onlyOwner {
        govFarm = IGovFarm(_govFarmAddress);
        emit GovFarmUpdated(_govFarmAddress);
    }

    function updateBlockList(address _user, bool _isBlocked) external onlyOwner {
        isBlocked[_user] = _isBlocked;
        emit BlockListUpdated(_user, _isBlocked);
    }

    //emergency funcs
    function recoverTokens(uint amount, address dst) external onlyOwner {
        rewardToken.safeTransfer(dst, amount);
    }

}