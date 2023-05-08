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

contract GovernorsFarm is Owned, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SignedSafeMath for int256;
    IERC20 public immutable USH;
    IvdUSH public immutable vdUSH;
    uint256 public vdLockPercentage; //percentage of rewards to lock as vdUSH

    //check if an address has entered the matrix
    mapping(address => bool) public isInMatrix;
    address[] public users; //array of users in the matrix

    uint256 public totalSupplyMultiplier; //total supply multiplier to adjust for vdush total supply calc on bnb chain
    uint256 public ushPerSec;

    mapping(address => uint256) public lastClaimTimestamp;
    mapping(address => uint256) public lastClaimVdUshBalance;
    mapping(address => uint256) public lastClaimTotalSupply;


    event MatrixEntered(address indexed user);
    event RewardsClaimed(address indexed user, uint256 ushClaimed, uint256 vdUSHClaimed);

    //Constructor
    constructor(address _owner, address _USH, address _vdUSH, uint256 _vdLockPercentage, uint256 _ushPerSec, uint256 _totalSupplyMultiplier ) Owned(_owner) {
        USH = IERC20(_USH);
        vdUSH = IvdUSH(_vdUSH);
        vdLockPercentage = _vdLockPercentage; //set to 50e18 for 50%
        ushPerSec = _ushPerSec;
        totalSupplyMultiplier = _totalSupplyMultiplier;
        USH.approve(address(vdUSH), type(uint256).max); //for locking on behalf of users
    }

    /**
     * @dev Allows a user with non zero vdUSH balance to enter the matrix and start earning farm rewards.
     * The user's address is registered in a mapping.
     * The user's last claim timestamp is set to the current block timestamp (rewards start from the moment they enter).
     * @param user The address of the user entering the matrix.
     */
    function enterMatrix(address user) external nonReentrant {
        require(!isInMatrix[user], "Already in matrix");
        require(vdUSH.balanceOf(user) > 0, "Cannot enter the matrix without vdUSH");
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
    function earned(address user) public view returns (uint256, uint256) {

        uint256 lastClaimTimeStamp = lastClaimTimestamp[user];
        uint256 secsSinceLastClaim = block.timestamp - lastClaimTimeStamp;
        uint256 lastEpoch = vdUSH.user_point_epoch(user);
        uint256 lastEpochTimestamp = vdUSH.user_point_history__ts(user, lastEpoch);

        uint256 userVdUsh;
        uint256 totalVdUsh;

        userVdUsh = lastClaimVdUshBalance[user];
        totalVdUsh = lastClaimTotalSupply[user];

        //sampling:
        //fyi we start at i=1, bc i=0 is the lastClaim which is already stored
        for(uint i = 1; i < 53;) {
            uint256 timestamp = lastClaimTimeStamp + i * 1 weeks;
            //if 1 wk after last claim is after current block timestamp, break
            if(timestamp > block.timestamp) {
                userVdUsh += vdUSH.balanceOf(user);
                totalVdUsh += vdUSH.totalSupply();
                break;
            }
            //round down to nearest week if needed
            if(timestamp > lastEpochTimestamp) {
                timestamp = lastEpochTimestamp;
            }
            userVdUsh += vdUSH.balanceOfAtT(user, timestamp);
            totalVdUsh += vdUSH.totalSupplyAtT(timestamp);
            unchecked{ ++i; }
        }

        uint256 averageVdUshShare = userVdUsh * 1e18 / totalVdUsh;
        uint256 ushEarned = averageVdUshShare * secsSinceLastClaim * ushPerSec / 1e18 * totalSupplyMultiplier / 1e18;
        uint256 lockedUsh = ushEarned * vdLockPercentage / 100e18;
        uint256 claimableUsh = ushEarned - lockedUsh;

        return (claimableUsh, lockedUsh);
    }

    function passGoAndCollect(address user) external nonReentrant {
        uint256 claimableUsh;
        uint256 lockedUsh;
        (claimableUsh, lockedUsh) = earned(user);
        require(lockedUsh > 0 || claimableUsh > 0, "Nothing to claim");
        lastClaimTimestamp[user] = block.timestamp;
        lastClaimVdUshBalance[user] = vdUSH.balanceOf(user);
        lastClaimTotalSupply[user] = vdUSH.totalSupply();
        //add to user's vdUSH if their lock hasn't expired
        if(vdUSH.balanceOf(user) != 0) {
            vdUSH.deposit_for(user, 0, 0, lockedUsh);
        } else {
            lockedUsh = 0;
        }
        //transfer remainder to user
        USH.safeTransfer(user, claimableUsh);
        emit RewardsClaimed(user, claimableUsh, lockedUsh);
    }

    //view funcs
    function getAllUsers() public view returns (address[] memory) {
        return users;
    }

    function getVdUshTotalSupplyInFarm() public view returns (uint256) {
        uint256 totalVdUsh;
        for(uint i = 0; i < users.length;) {
            totalVdUsh += vdUSH.balanceOf(users[i]);
            unchecked{ ++i; }
        }
        return totalVdUsh;
    }

    //owner funcs
    function setUSHPerSec(uint256 _ushPerSec) external onlyOwner {
        ushPerSec = _ushPerSec;
    }

    function setVdLockPercentage(uint256 _vdLockPercentage) external onlyOwner {
        require(_vdLockPercentage <= 100e18, "Percentage too high");
        vdLockPercentage = _vdLockPercentage;
    }

    function setTotalSupplyMultiplier(uint256 _totalSupplyMultiplier) external onlyOwner {
        //make sure to set it in 1e18 terms
        //This is how it should be set, but we do it off-chain bc it's expensive
        //totalSupplyMultiplier = getVdUshTotalSupplyInFarm() * 1e18 / vdUSH.totalSupply();
        totalSupplyMultiplier = _totalSupplyMultiplier;
    }

    //emergency funcs
    function recoverUSH(uint256 amount, address dst) external onlyOwner {
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