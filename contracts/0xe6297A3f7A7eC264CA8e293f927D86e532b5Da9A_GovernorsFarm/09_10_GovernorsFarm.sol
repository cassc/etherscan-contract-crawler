// SPDX-License-Identifier: MIT
pragma solidity >0.8.10;

import "communal/SafeERC20.sol";
import "communal/Owned.sol";
import "local/interfaces/IvdUSH.sol";
import "communal/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/math/SignedSafeMath.sol";

// ================================================================
// |██╗   ██╗███╗   ██╗███████╗██╗  ██╗███████╗████████╗██╗  ██╗
// |██║   ██║████╗  ██║██╔════╝██║  ██║██╔════╝╚══██╔══╝██║  ██║
// |██║   ██║██╔██╗ ██║███████╗███████║█████╗     ██║   ███████║
// |██║   ██║██║╚██╗██║╚════██║██╔══██║██╔══╝     ██║   ██╔══██║
// |╚██████╔╝██║ ╚████║███████║██║  ██║███████╗   ██║   ██║  ██║
// | ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝
// ================================================================
// ======================= GovernorsFarm =+++======================
// ================================================================
// Allows vdUSH users to enter the matrix and recieve USH rewards
// Users can claim their rewards at any time
// No staking needed, just enter the matrix and claim rewards
// No user deposits held in this contract!
//
// Author: unshETH team (github.com/unsheth)
// Heavily inspired by StakingRewards, MasterChef
//

interface IGovFarm {
    function getAllUsers() external returns (address[] memory);
    function lastClaimTimestamp(address user) external returns (uint);
}

contract GovernorsFarm is Owned, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SignedSafeMath for int256;
    IERC20 public immutable USH;
    IvdUSH public immutable vdUsh;
    uint public vdLockPercentage; //percentage of rewards to lock as vdUSH

    //check if an address has entered the matrix
    mapping(address => bool) public isInMatrix;
    address[] public users; //array of users in the matrix

    uint public totalSupplyMultiplier; //total supply multiplier to adjust for vdush total supply calc on bnb chain
    uint public ushPerSec;

    mapping(address => uint) public initialEarned;
    mapping(address => uint) public lastClaimTimestamp;
    mapping(address => uint) public lastClaimVdUshBalance;
    mapping(address => uint) public lastClaimTotalSupply;


    struct Point {
        int128 bias;
        int128 slope; // # -dweight / dt
        uint ts;
        uint blk; // block
    }
    uint internal constant WEEK = 1 weeks;

    event MatrixEntered(address indexed user);
    event RewardsClaimed(address indexed user, uint ushClaimed, uint vdUSHClaimed);
    event UshPerSecUpdated(uint _ushPerSec);
    event TotalSupplyMultiplierUpdated(uint _totalSupplyMultiplier);
    event vdLockPercentageUpdated(uint _vdLockPercentage);

    //Constructor
    constructor(address _owner, address _USH, address _vdUSH, uint _vdLockPercentage, uint _ushPerSec, uint _totalSupplyMultiplier, address _govFarmV1) Owned(_owner) {
        USH = IERC20(_USH);
        vdUsh = IvdUSH(_vdUSH);
        vdLockPercentage = _vdLockPercentage; //set to 50e18 for 50%
        ushPerSec = _ushPerSec;
        totalSupplyMultiplier = _totalSupplyMultiplier;
        USH.approve(address(vdUsh), type(uint).max); //for locking on behalf of users

        //Seed values from V1Farm for migration
        IGovFarm govFarmV1 = IGovFarm(_govFarmV1);
        address[] memory v1Users = govFarmV1.getAllUsers();
        //Gas efficient method to migrate users in v1 farm with no require checks or events
        for(uint i = 0; i < v1Users.length; ) {
            address user = v1Users[i];
            isInMatrix[user] = true;
            users.push(user);
            lastClaimTimestamp[user] = govFarmV1.lastClaimTimestamp(user);
            unchecked { ++i; }
        }

    }


    /**
     * @dev Allows a user with non zero vdUSH balance to enter the matrix and start earning farm rewards.
     * The user's address is registered in a mapping.
     * The user's last claim timestamp is set to the current block timestamp (rewards start from the moment they enter).
     * @param user The address of the user entering the matrix.
     */
    function enterMatrix(address user) external nonReentrant {
        _enterMatrix(user);
    }

    function _enterMatrix(address user) internal {
        require(!isInMatrix[user], "Already in matrix");
        require(vdUsh.balanceOf(user) > 0, "Cannot enter the matrix without vdUSH");
        isInMatrix[user] = true;
        users.push(user);
        lastClaimTimestamp[user] = block.timestamp;
        emit MatrixEntered(user);
    }

    /**
     * @dev Calculate user's earned USH and vdUSH rewards since last claim.
     * User earned rewards are proportional to their share of total vdUSH at the time of claim.
     * @param user The address of the user entering the matrix.
     */
    function earned(address user) public view returns (uint, uint) {
        uint lastClaimTimeStamp = lastClaimTimestamp[user];
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
        uint ushEarned = averageVdUshShare * secsSinceLastClaim * ushPerSec / 1e18 * totalSupplyMultiplier / 1e18;
        uint lockedUsh = ushEarned * vdLockPercentage / 100e18;
        uint claimableUsh = ushEarned - lockedUsh;

        return (claimableUsh, lockedUsh);
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

    function passGoAndCollect(address user) external nonReentrant {
        uint claimableUsh;
        uint lockedUsh;
        (claimableUsh, lockedUsh) = earned(user);
        require(lockedUsh > 0 || claimableUsh > 0, "Nothing to claim");
        lastClaimTimestamp[user] = block.timestamp;
        lastClaimVdUshBalance[user] = vdUsh.balanceOf(user);
        lastClaimTotalSupply[user] = vdUsh.totalSupply();
        //add to user's vdUSH if their lock hasn't expired
        if(vdUsh.balanceOf(user) != 0) {
            vdUsh.deposit_for(user, 0, 0, lockedUsh);
        } else {
            lockedUsh = 0;
        }
        //transfer remainder to user
        USH.safeTransfer(user, claimableUsh);

        initialEarned[user] = 0;

        emit RewardsClaimed(user, claimableUsh, lockedUsh);
    }

    //view funcs
    function getAllUsers() public view returns (address[] memory) {
        return users;
    }

    function getVdUshTotalSupplyInFarm() public view returns (uint) {
        uint totalVdUsh;
        for(uint i = 0; i < users.length;) {
            totalVdUsh += vdUsh.balanceOf(users[i]);
            unchecked{ ++i; }
        }
        return totalVdUsh;
    }

    //owner funcs
    function setUSHPerSec(uint _ushPerSec) external onlyOwner {
        ushPerSec = _ushPerSec;
        emit UshPerSecUpdated(_ushPerSec);
    }

    function setVdLockPercentage(uint _vdLockPercentage) external onlyOwner {
        require(_vdLockPercentage <= 100e18, "Percentage too high");
        vdLockPercentage = _vdLockPercentage;
        emit vdLockPercentageUpdated(_vdLockPercentage);
    }

    function setTotalSupplyMultiplier(uint _totalSupplyMultiplier) external onlyOwner {
        //make sure to set it in 1e18 terms
        totalSupplyMultiplier = _totalSupplyMultiplier;
        emit TotalSupplyMultiplierUpdated(_totalSupplyMultiplier);
    }

    function setTotalSupplyMultiplier_onChain() external onlyOwner {
        totalSupplyMultiplier = vdUsh.totalSupply() * 1e18 / getVdUshTotalSupplyInFarm();
        emit TotalSupplyMultiplierUpdated(totalSupplyMultiplier);
    }

    //emergency funcs
    function recoverUSH(uint amount, address dst) external onlyOwner {
        USH.safeTransfer(dst, amount);
    }

    // ⢠⣶⣿⣿⣶⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    // ⣿⣿⠁⠀⠙⢿⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    // ⠸⣿⣆⠀⠀⠈⢻⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣾⡿⠿⠛⠻⠿⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣤⣤⣤⣀⡀⠀
    // ⠀⢻⣿⡆⠀⠀⠀⢻⣷⡀⠀⠀⠀⠀⠀⠀⢀⣴⣾⠿⠿⠿⣿⣿⠀⠀⠀⠀⠀⠈⢻⣷⡀⠀⠀⠀⠀⠀⢀⣠⣶⣿⠿⠛⠋⠉⠉⠻⣿⣦
    // ⠀⠀⠻⣿⡄⠀⠀⠀⢿⣧⣠⣶⣾⠿⠿⠿⣿⡏⠀⠀⠀⠀⢹⣿⡀⠀⠀⠀⢸⣿⠈⢿⣷⠀⠀⠀⢀⣴⣿⠟⠉⠀⠀⠀⠀⠀⠀⠀⢸⣿
    // ⠀⠀⠀⠹⣿⡄⠀⠀⠈⢿⣿⡏⠀⠀⠀⠀⢻⣷⠀⠀⠀⠀⠸⣿⡇⠀⠀⠀⠈⣿⠀⠘⢿⣧⣠⣶⡿⠋⠁⠀⠀⠀⠀⠀⠀⣀⣠⣤⣾⠟
    // ⠀⠀⠀⠀⢻⣿⡄⠀⠀⠘⣿⣷⠀⠀⠀⠀⢸⣿⡀⠀⠀⠀⠀⣿⣷⠀⠀⠀⠀⣿⠀⢶⠿⠟⠛⠉⠀⠀⠀⠀⠀⢀⣤⣶⠿⠛⠋⠉⠁⠀
    // ⠀⠀⠀⠀⠀⢿⣷⠀⠀⠀⠘⣿⡆⠀⠀⠀⠀⣿⡇⠀⠀⠀⠀⢹⣿⠀⠀⠀⠀⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⡿⠋⠁⠀⠀⠀⠀⠀⠀
    // ⠀⠀⠀⠀⠀⠘⣿⡇⠀⠀⠀⢸⣷⠀⠀⠀⠀⢿⣷⠀⠀⠀⠀⠈⣿⡇⠀⠀⠀⣿⡇⠀⠀⠀⠀⠀⠀⠀⣴⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀
    // ⠀⠀⠀⠀⠀⠀⢻⣿⠀⠀⠀⠀⢿⣇⠀⠀⠀⠸⣿⡄⠀⠀⠀⠀⣿⣷⠀⠀⠀⣿⡇⠀⠀⠀⠀⠀⠀⣼⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    // ⠀⠀⠀⠀⠀⠀⠘⣿⡇⠀⠀⠀⠸⣿⡀⠀⠀⠀⢿⣇⠀⠀⠀⠀⢸⣿⡀⠀⢠⣿⠇⠀⠀⠀⠀⠀⣼⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    // ⠀⠀⠀⠀⠀⠀⠀⢹⣿⠀⠀⠀⠀⢻⣧⠀⠀⠀⠸⣿⡄⠀⠀⠀⢘⣿⡿⠿⠟⠋⠀⠀⠀⠀⠀⣼⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    // ⠀⠀⠀⠀⠀⠀⠀⠈⣿⣇⠀⠀⠀⠈⣿⣄⠀⢀⣠⣿⣿⣶⣶⣶⡾⠋⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    // ⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⡀⠀⠀⠀⠈⠻⠿⠟⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢻⣧⡀⠀⠀⠀⣀⠀⠀⠀⣴⣤⣄⣀⣀⣀⣠⣤⣾⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⣶⣶⣿⡿⠃⠀⠀⠉⠛⠻⠿⠿⠿⠿⢿⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
    // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
}