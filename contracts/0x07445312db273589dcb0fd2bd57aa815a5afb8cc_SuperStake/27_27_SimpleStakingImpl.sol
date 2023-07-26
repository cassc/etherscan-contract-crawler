/**
 * SimpleStakingImpl
 * Handles staking, unstaking, collecting rewards and re-staking Hex
 * Holds the Hex pending staking in itself
 */
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IHex.sol";
//import "./IHedron.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "./DPT/TokenDividendTracker.sol";
contract SimpleStakingImpl is Ownable {
    // Block of 256 bits
    address public token;
    uint32 public stakingDays;
    uint64 public lastStakedStart;
    // Closed
    // Block of 256 bits
    address public dividendTracker;
    // Closed
    address public hedron;
    address public router;

    uint64 public launchTime;

    constructor(
        address stakingToken,
        uint32 daysToStake,
        address dividendTrackerToken,
        address hdrn,
        address rtr
    ) {
        token = stakingToken;
        stakingDays = daysToStake;
        lastStakedStart = uint64(IHex(token).currentDay());

        dividendTracker = dividendTrackerToken;
        hedron = hdrn;
        router = rtr;
        launchTime = uint64(block.timestamp) + 86400;
        
    }

    function updateFork(address newRtr) external onlyOwner {
        // Update router
        router = newRtr;

    }

    function afterReceivedHex() external onlyOwner {
        // Called after Hex has been received
        
        // We only ever have one stake in the list, but we get stakeCount anyway
        IHex stakingContract = IHex(token);
        // We check if there's a stake to resolve
        uint256 stakeNumber = stakingContract.stakeCount(address(this));
        if (stakeNumber > 0) {
            // Something was staked last time so it's time to unstake it
            // Unstake all of the stakes present, if there's more than one (there shouldn't be, but we have to assume)
            uint256 currentDay = stakingContract.currentDay();
            // Total stake output to accumulate
            uint256 stakeRewards = 0;
            for (uint i = 0; i < stakeNumber; i++) {
                // Get the pre-unlock balance of tokens
                uint256 oldBal = stakingContract.balanceOf(address(this));
                // Grab the stakeId from the stakeLists
                (uint40 stakeId, , , uint16 lockedDay, uint16 stakedDays, , ) = stakingContract.stakeLists(
                    address(this),
                    i
                );
                // If this is true, the stake is ready for unlock
                if(currentDay >= lockedDay + stakedDays) {
                    // Run the "good" stake unlocker to not be penalised
                    stakingContract.stakeGoodAccounting(address(this), i, stakeId);
                    // Get the tokens back
                    stakingContract.stakeEnd(i, stakeId);
                    // Accumulate the stake rewards
                    stakeRewards = stakeRewards + (stakingContract.balanceOf(address(this)) - oldBal);
                }
                
                
            }
            if(stakeRewards > 0) {
                // Pay out 1% of the stake output to the dividend tracker
                stakingContract.transfer(dividendTracker, stakeRewards / 100);
                // Tell it there's some tokens to calculate
                TokenDividendTracker(dividendTracker).afterReceivedHex(stakeRewards / 100);
                // Now need to restake our holdings
                uint256 stakeAmt = stakingContract.balanceOf(address(this));
                stakingContract.stakeStart(stakeAmt, stakingDays);
            }
            
        } else {
            // Give a day to fill pool
            if(block.timestamp > launchTime) {
                uint256 stakeAmt = stakingContract.balanceOf(address(this));
                stakingContract.stakeStart(stakeAmt, stakingDays);
            }
            
        }
        
    }

}