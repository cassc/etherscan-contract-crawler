// SPDX-License-Identifier: NONE
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract LuckyStaking is Ownable {
    event Staked(address indexed staker, uint32 indexed stakeId, uint160 amount, uint64 unlockTime);
    event Unstaked(address indexed unstaker, uint32 indexed stakeId, uint256 amount);
    // The stake mapping
    mapping(address => Stake[]) stakes;
    // Uses one slot
    struct Stake {
        uint128 stakedAmount;
        uint32 stakeId;
        uint32 profitMultiplier;
        uint64 unlockTime;
    }
    // Array to keep those with stakes
    address[] private _stakers;
    // Open block - 256
    address private stakedToken;
    uint32 private profitDivisor = 100000;
    uint32 private currentMaxStakeId;
    // 64 bytes free

    constructor(address tokenStake) {
        stakedToken = tokenStake;
        currentMaxStakeId = 0;
    }
    
    function stakeTokens(uint128 amount, uint64 lockWeeks) external returns (uint32) {
        // Minimum unlock time 1 week
        require(lockWeeks > 0, "ToadStaking: Must be more than one week until unlock.");
        // Calculate how many weeks - 1 is 1 week
        uint64 unlockTime = uint64(block.timestamp + (lockWeeks * 60*60*24*7)); 
        // Profit weeks caps at 25 (2.3x chance)
        uint64 profitWeeks = lockWeeks-1;
        if(profitWeeks > 25) {
            profitWeeks = 25;
        }
        // There turns out to be a trick of 3/2 to be sqrt(unlockWeeks^3)
        // An int is fine anyway as we use divisor of 100000 as total
        uint32 profit = uint32(sqrt(profitWeeks**3)*1000 + 105000);

        // Need tokens to be in their wallet
        IERC20 tok = IERC20(stakedToken);
        require(tok.balanceOf(msg.sender) >= amount, "LuckyStaking: Must own enough tokens to stake.");
        // Take the tokens
        tok.transferFrom(msg.sender, address(this), amount);
        // Get the current max stake ID
        uint32 newId = currentMaxStakeId;
        currentMaxStakeId = currentMaxStakeId + 1;
        if(uint32(stakes[msg.sender].length) == 0) {
            _stakers.push(msg.sender);
        }
        // Create a new Stake object 
        stakes[msg.sender].push(Stake(amount, newId, profit, unlockTime));
        emit Staked(msg.sender, newId, amount, unlockTime);
        return newId;
    }
    

    function unstakeTokens(uint32 id, uint256 index) external {
        // Get the stake
        require(stakes[msg.sender].length > index, "LuckyStaking: Invalid index.");
        require(stakes[msg.sender][index].stakeId == id, "LuckyStaking: ID doesn't match index.");
        Stake memory unstake = stakes[msg.sender][index];
        // Make sure we can unlock
        require(unstake.unlockTime < block.timestamp, "LuckyStaking: Cannot unlock yet.");
        // Send the stake amount to the sender
        IERC20 tok = IERC20(stakedToken);
        uint256 amount = unstake.stakedAmount;
        // Clear the stake from the list
        if(stakes[msg.sender].length-1 != index) {
            // Copy the last stake to index
            stakes[msg.sender][index] = stakes[msg.sender][stakes[msg.sender].length-1];
        }
        stakes[msg.sender].pop();
        
        tok.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, id, amount);
    }

    function transferStakeOwnership(uint32 id, uint256 index, address newOwner) external {
        require(stakes[msg.sender].length > index, "LuckyStaking: Invalid index.");
        require(stakes[msg.sender][index].stakeId == id, "LuckStaking: ID doesn't match index."); 
        Stake memory stakeToTransfer = stakes[msg.sender][index];
        // Delete from sender
        // Clear the stake from the list
        if(stakes[msg.sender].length-1 != index) {
            // Copy the last stake to index
            stakes[msg.sender][index] = stakes[msg.sender][stakes[msg.sender].length-1];
        }
        stakes[msg.sender].pop();
        stakes[newOwner].push(stakeToTransfer);
    }

    function queryAllStakes() external view returns (address[] memory stakers, Stake[][] memory stakeStructs) {
        stakers = _stakers;
        stakeStructs = new Stake[][](_stakers.length);
        for(uint i = 0; i < _stakers.length; i++) {
            stakeStructs[i] = (stakes[_stakers[i]]);
        }
    }

    function queryHoldersStakes(address holder) public view returns (uint128[] memory amounts, uint32[] memory stakeIds, uint32[] memory stakeMultipliers, uint64[] memory unlockTimes) {
        // Get the stakes for a holder
        Stake[] memory stakesForHolder = stakes[holder];
        // Create storage
        amounts = new uint128[](stakesForHolder.length);
        stakeIds = new uint32[](stakesForHolder.length);
        stakeMultipliers = new uint32[](stakesForHolder.length);
        unlockTimes = new uint64[](stakesForHolder.length);
        for(uint i = 0; i < stakesForHolder.length; i++) {
            amounts[i] = stakesForHolder[i].stakedAmount;
            stakeIds[i] = stakesForHolder[i].stakeId;
            stakeMultipliers[i] = stakesForHolder[i].profitMultiplier;
            unlockTimes[i] = stakesForHolder[i].unlockTime;
        }
    }
    
    function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
        z = y;
        uint x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    } else if (y != 0) {
        z = 1;
    }
}

}