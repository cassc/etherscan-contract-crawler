/**
* Airdrop Contract of LollipopCoin($LOLLI)
*
* Total supply of LOLLI: 420.69 trillion
* Allocation:
* [5%] for initial LP on Uniswap
* [7%] for CEX listing
* [88%] for airdrop
*
* How to claim?
* [1] On first come, first served basis.
* [2] Send any amount of ethers (including ZERO) to this contract to claim free LOLLIs.
* [3] Airdrop amount per address will be reduced by 0.00069% after each claim.
*
* Website: https://lollipopcoin.org
* Twitter: https://twitter.com/lollipopcoineth
*
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract GetLollipop is Ownable {
    using SafeERC20 for IERC20;
    using Address for address;

    // LollipopCoin
    IERC20 public immutable LollipopCoin;

    // How long the airdrop will last
    uint256 public constant AIRDROP_DURATION = 1 weeks;
    // Start time of the airdrop
    uint256 public startTime;

    // Initial airdrop amount per address is 2.69 billion LOLLIs
    uint256 public constant INITIAL_AIRDROP_AMOUNT = 2_690_000_000 ether;
    // Minimum airdrop amount per address is 100 million LOLLIs
    uint256 public constant MIN_AIRDROP_AMOUNT = 100_000_000 ether;
    // Airdrop amount will be reduced by 0.00069% after each claim
    uint256 public constant REDUCTION_RATE = 9_999_931;
    uint256 public constant REDUCTION_BASE = 10_000_000;
    // Current airdrop amount per address
    uint256 public airdropAmount = INITIAL_AIRDROP_AMOUNT;
    // Claimed count
    uint256 public claimedCount;
    // Claimed addresses
    mapping(address => uint256) public claimed;

    // Count of random recipients per claim
    uint256 public randomRecipientCount = 9;

    // Dead address
    address private constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    // Modifier to check if the msg.sender can claim LOLLIs
    modifier canClaim() {
        require(active(), "GetLollipop: Airdrop is not active");
        require(airdropAmount >= MIN_AIRDROP_AMOUNT, "GetLollipop: Airdrop is over");
        require(LollipopCoin.balanceOf(address(this)) >= airdropAmount, "GetLollipop: Claimed out");
        require(msg.sender == tx.origin && !msg.sender.isContract(), "GetLollipop: No contract allowed");
        require(claimed[msg.sender] == 0, "GetLollipop: Already claimed");
        _;
    }

    constructor(IERC20 _LollipopCoin) {
        LollipopCoin = _LollipopCoin;
    }

    // Send any amount of ethers to this contract to claim LOLLIs
    receive() external payable {
        claim();
    }

    // Claim LOLLIs
    function claim() public canClaim {
        LollipopCoin.safeTransfer(msg.sender, airdropAmount);
        claimed[msg.sender] = airdropAmount;
        randomAirdrop(airdropAmount / 10000, claimedCount++);
        airdropAmount = airdropAmount * REDUCTION_RATE / REDUCTION_BASE;
    }

    // Airdrop LOLLIs to random addresses after each claim
    function randomAirdrop(uint256 amount, uint256 nonce) private {
        address recipient;
        for (uint256 i = 0; i < randomRecipientCount; i++) {
            recipient = address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce + i)))));
            LollipopCoin.safeTransfer(recipient, amount);
        }
    }

    // Returns true if currently in the airdrop period
    function active() public view returns (bool) {
        return startTime != 0 && block.timestamp >= startTime && block.timestamp < startTime + AIRDROP_DURATION;
    }

    // Set the start time
    function setStartTime(uint256 _startTime) external onlyOwner {
        require(startTime == 0 || startTime > block.timestamp, "GetLollipop: Start time cannot be changed");
        require(_startTime > block.timestamp, "GetLollipop: Start time must be in the future");
        startTime = _startTime;
    }

    // Pause the airdrop in case of emergency
    function emergencyPause() external onlyOwner {
        require(active(), "GetLollipop: Airdrop is not active");
        startTime = 0;
    }

    // Update the count of random recipients per claim
    function updateRandomRecipientCount(uint256 _randomRecipientCount) external onlyOwner {
        randomRecipientCount = _randomRecipientCount;
    }

    // Burn all remaining LOLLIs in this contract after the end of the airdrop
    function burnRemaining() external onlyOwner {
        require(startTime != 0 && block.timestamp > startTime + AIRDROP_DURATION, "GetLollipop: Airdrop is not ended");
        LollipopCoin.safeTransfer(DEAD_ADDRESS, LollipopCoin.balanceOf(address(this)));
    }

    // Recover any ERC20 token sent to this contract by mistake except LollipopCoin
    function recoverERC20(IERC20 token) external onlyOwner {
        require(token != LollipopCoin, "GetLollipop: Cannot recover LollipopCoin");
        require(token.balanceOf(address(this)) > 0, "GetLollipop: No tokens to recover");
        token.safeTransfer(owner(), token.balanceOf(address(this)));
    }

    // Withdraw all ethers from this contract
    function withdrawEther() external onlyOwner {
        require(address(this).balance > 0, "GetLollipop: No ethers to withdraw");
        payable(owner()).transfer(address(this).balance);
    }
}