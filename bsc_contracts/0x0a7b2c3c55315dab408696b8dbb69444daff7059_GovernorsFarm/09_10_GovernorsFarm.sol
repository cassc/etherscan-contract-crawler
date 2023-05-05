// SPDX-License-Identifier: MIT
pragma solidity >0.8.10;

import "communal/SafeERC20.sol";
import "communal/Owned.sol";
import "local/interfaces/IvdUSH.sol";
import "communal/ReentrancyGuard.sol";
import "openzeppelin-contracts/contracts/utils/math/SignedSafeMath.sol";
//import "ERC20/IERC20.sol";

// ================================================================
// |██╗   ██╗███╗   ██╗███████╗██╗  ██╗███████╗████████╗██╗  ██╗
// |██║   ██║████╗  ██║██╔════╝██║  ██║██╔════╝╚══██╔══╝██║  ██║
// |██║   ██║██╔██╗ ██║███████╗███████║█████╗     ██║   ███████║
// |██║   ██║██║╚██╗██║╚════██║██╔══██║██╔══╝     ██║   ██╔══██║
// |╚██████╔╝██║ ╚████║███████║██║  ██║███████╗   ██║   ██║  ██║
// | ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝
// ================================================================                                                            
// ========================== GovernorsFarm =======================
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

    uint256 public ushPerSec; //TODO: convert this into USH per sec
    uint256 public accUshPerVdush; //accumulated USH per share
    uint256 public lastRewardBlock; //last block timestamp that USH distribution occurs

    uint256 public periodStart; //timestamp when the farm starts
    

    mapping(address => int256) public userRewardDebt;

    event MatrixEntered(address indexed user);
    event RewardsClaimed(address indexed user, uint256 ushClaimed, uint256 vdUSHClaimed);
    
    //Constructor
    constructor(address _owner, address _USH, address _vdUSH, uint256 _vdLockPercentage, uint256 _ushPerSec, uint256 _periodStart ) Owned(_owner) {
        USH = IERC20(_USH);
        vdUSH = IvdUSH(_vdUSH);
        vdLockPercentage = _vdLockPercentage; //set to 50e18 for 50%
        ushPerSec = _ushPerSec;
        periodStart = _periodStart;
        USH.approve(address(vdUSH), type(uint256).max); //for locking on behalf of users
    }

    //view funcs 
    function toUInt256(int256 a) internal pure returns (uint256) {
        require(a >= 0, "Integer < 0");
        return uint256(a);
    }

    function earned(address user) public view returns(uint256) {
        uint256 vdUSHSupply = vdUSH.totalSupply();
        uint256 vdUSHBalance = vdUSH.balanceOf(user);

        if (block.timestamp > lastRewardBlock && vdUSHSupply != 0) {
            uint256 elapsedTime = block.timestamp - lastRewardBlock; 
            uint256 accUshPerVdush = accUshPerVdush + elapsedTime * ushPerSec * 1e18 / vdUSHSupply;
        }
        return toUInt256(int256( vdUSHBalance * accUshPerVdush / 1e18) - userRewardDebt[user]);
    }

    //user funcs
    function enterMatrix(address user) external nonReentrant {
        require(!isInMatrix[user], "Already in matrix");
        uint256 vdUSHBalance = vdUSH.balanceOf(user);
        require(vdUSHBalance > 0, "Cannot enter the matrix without vdUSH");
        require(block.timestamp >= periodStart, "Matrix pending...");
        refreshMatrix();
        //update user info
        //usr.amount += vdUSHBalance;
        userRewardDebt[user] += int256(vdUSHBalance * accUshPerVdush / 1e18);
        isInMatrix[user] = true;

        emit MatrixEntered(user);
    }
    
    //update rewards
    function refreshMatrix() public nonReentrant {
        require(block.timestamp >= periodStart, "Matrix pending...");
        if (block.timestamp <= lastRewardBlock) {
            return;
        }

        uint256 vdUSHSupply = vdUSH.totalSupply();
        uint256 elapsedTime = block.timestamp - lastRewardBlock;
        accUshPerVdush += elapsedTime * ushPerSec * 1e18 / vdUSHSupply; //TODO: shouldn't this be scaled based on elapsed time? 
        lastRewardBlock = block.timestamp;
    }

    /**
     * @dev Allows a user to enter the matrix by depositing vdUSH tokens. 
     * The user's vdUSH balance is added to their UserInfo struct, and they become marked as "in the matrix".
     * @param user The address of the user entering the matrix.
     */ 
    function passGoAndCollect(address user) external nonReentrant {
        require(isInMatrix[user], "Not in matrix");
        require(block.timestamp >= periodStart, "Matrix pending...");
        uint256 vdUSHBalance = vdUSH.balanceOf(user);
        refreshMatrix();
        int256 accumulatedUSH = int256(vdUSHBalance * accUshPerVdush / 1e18);
        uint256 pendingUSH = uint256(accumulatedUSH - userRewardDebt[user]);
        require (pendingUSH > 0, "Nothing to claim"); //TODO: check this
        userRewardDebt[user] = accumulatedUSH;
        
        //add to user's vdUSH 
        uint256 amountToLock = pendingUSH * vdLockPercentage / 100e18;
        vdUSH.deposit_for(user, 0, 0, amountToLock);
        //transfer remainder to user
        USH.safeTransfer(user, pendingUSH - amountToLock);
        emit RewardsClaimed(user, amountToLock, pendingUSH - amountToLock);
    }

    //owner funcs
    function setUSHPerSec(uint256 _ushPerSec) external onlyOwner {
        //require(block.number < periodStart, "Matrix already started");
        ushPerSec = _ushPerSec;
    }

    function setvdLockPercentage(uint256 _vdLockPercentage) external onlyOwner {
        //require(block.number < periodStart, "Matrix already started");
        require(_vdLockPercentage <= 100e18, "Percentage too high");
        vdLockPercentage = _vdLockPercentage;
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