// SPDX-License-Identifier: NONE

/**
 * LuckyToad v3 Jackpot Manager
 * Holds a list of winners to be dealt with
 */

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LuckyJackpots is Ownable {
    event WinPending(address indexed seller, uint256 ethWinnings, uint256 randomNumber);
    event JackpotWin(address indexed winner, uint256 winnings, uint256 randomSeedUsed);
    event ClaimManually(address indexed winner, uint256 winnings);
    struct WinToProcess {
        uint256 randomNumber;
        uint256 ethWinnings;
        address seller;
    }
    struct ManuallyClaimableWin {
        uint256 ethWinnings;
        address winner;
    }

    modifier onlyProcessingBot() {
        require(msg.sender == processingBot, "LuckyJackpot: Only the bot can execute this.");
        _;
    }
    modifier onlyHeadContract() {
        require(msg.sender == topContract, "LuckyJackpot: Only the bot can execute this.");
        _;
    }


    modifier reentrancyGuard() {
        require(!_reentrancySemaphore, "LuckyJackpot: Pls do not rentrancy us.");
        _reentrancySemaphore = true;
        _;
        _reentrancySemaphore = false;
    }
    address private processingBot;
    
    bool private _reentrancySemaphore = false;

    WinToProcess[] private pendingWins;

    ManuallyClaimableWin[] private failedSends;

    address private topContract;

    constructor(address bot) {
        topContract = msg.sender;
        processingBot = bot;
    }
    /// @notice Changes the processing bot address. Only settable by CA owner.
    /// @param newBot the new bot to set
    function changeProcessingBot(address newBot) public onlyOwner {
        processingBot = newBot;
    }
    function changeTopContract(address newContract) public onlyOwner {
        topContract = newContract;
    }

    /// @notice Generates a pseudo-random number - don't rely on for crypto
    function generateNumber() private view returns (uint256 result) {
        result = uint256(keccak256(abi.encode(blockhash(block.number-1))));
    }
    /// @notice Adds a pending win from a sell - only callable by contract and the value of ETH should be sent
    /// @param seller the seller, so we can exclude them

    function addPendingWin(address seller) external payable onlyHeadContract {
        uint256 rng = generateNumber();
        pendingWins.push(WinToProcess(rng, msg.value, seller));
        emit WinPending(seller, msg.value, rng);
    }

    /// @notice Get the lists of pending wins
    function getPendingWins() public view returns (uint256[] memory rngs, uint256[] memory winnings, address[] memory sellers) {
        rngs = new uint256[](pendingWins.length);
        winnings = new uint256[](pendingWins.length);
        sellers = new address[](pendingWins.length);
        for(uint i = 0; i < pendingWins.length; i++) {
            rngs[i] = pendingWins[i].randomNumber;
            winnings[i] = pendingWins[i].ethWinnings;
            sellers[i] = pendingWins[i].seller;
        }
    }


    function processPendingWin(uint256 index, address receipient, uint256 processingCost) public onlyProcessingBot reentrancyGuard {
        processWinInternal(index, receipient, processingCost);
        // Check if it's the very end of the list
        if(index != pendingWins.length-1) {
            // It's not, so move the end to the index we wish to erase
            pendingWins[index] = pendingWins[pendingWins.length-1];
        }
        // Pop the end - if our pending win is the end, it's okay, if not we made a copy of the end
        pendingWins.pop();
    }

    function processWinInternal(uint256 index, address winner, uint256 processingCost) private {
        uint256 winAmount = pendingWins[index].ethWinnings;
        (bool success,) = winner.call{gas: 50000, value: winAmount-processingCost}("");
        payable(msg.sender).transfer(processingCost);
        if(success) {
            emit JackpotWin(winner, winAmount-processingCost, pendingWins[index].randomNumber);
        } else {
            failedSends.push(ManuallyClaimableWin(winAmount-processingCost, winner));
            emit ClaimManually(winner, winAmount-processingCost);
        }
    }
    /// @notice Process a list of indexes and winners. Ensure the indexes are ascending. 
    function processPendingWins(uint256[] calldata indexes, address[] calldata recipients, uint256[] calldata processingCosts) external onlyProcessingBot reentrancyGuard {
        require(indexes.length == recipients.length && indexes.length == processingCosts.length, "LuckyJackpot: Length of arrays must match.");
        for(uint i = 0; i < indexes.length; i++) {
            processWinInternal(indexes[i], recipients[i], processingCosts[i]);
        }
        // Need to be a little more careful here, as we have multiple indexes to remove
        uint indexLen = indexes.length-1;
        for(uint i = 0; i < indexes.length; i++) {
            // i is, from the end, how many
            if(indexes[indexLen-i] != pendingWins.length) {
                // Copy the end to the current index, if necessary
                pendingWins[indexes[indexLen-i]] = pendingWins[pendingWins.length-1];
            }
            // Delete the end
            pendingWins.pop();
        }
    }

    /// @notice Claim the first win for this address
    function manualClaim(address winner) public reentrancyGuard {
        // Find the first win in failedSends
        for(uint i = 0; i < failedSends.length; i++) {
            if(failedSends[i].winner == winner) {
                (bool success,) = winner.call{value: failedSends[i].ethWinnings}("");
                require(success, "LuckyJackpot: Send failed.");
                // Delete the winner
                if(i != failedSends.length-1) {
                    failedSends[i] = failedSends[failedSends.length-1];
                }
                failedSends.pop();
                break;
            }
        }
    }

    function withdrawGas(uint256 amount) public onlyProcessingBot {
        // Withdraw the gas fee to be spent on running a sell
        payable(processingBot).transfer(amount);
    }

    function withdrawFees(uint256 amount) public onlyOwner {
        // Withdraw excess fees for owner
        payable(owner()).transfer(amount);
    }
}