/**
 *Submitted for verification at BscScan.com on 2023-02-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function decimals() external view returns (uint8);
}

contract SpinToEarn {
    uint constant private MAX_SPIN_COUNT = 10;
    uint constant private SPIN_COST = 0.01 ether;
    uint constant private PRIZE_POOL_PERCENT = 70;
    uint constant private JACKPOT_PERCENT = 10;
    uint constant private DEV_FEE_PERCENT = 20;

    address public owner;
    uint public prizePool;
    uint public jackpotPool;
    uint public devFeePool;
    uint public spinCount;

    event SpinResult(address indexed user, uint indexed spinCount, uint indexed prizeAmount);

    constructor() {
        owner = msg.sender;
    }

    function spin() external payable {
        require(msg.value == SPIN_COST, "Spin cost is 0.01 ether");
        require(spinCount < MAX_SPIN_COUNT, "Maximum spin count reached");

        // Increment the spin count
        spinCount++;

        // Generate a random number
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, spinCount))) % 100;

        // Calculate the prize amount based on the random number
        uint prizeAmount = 0;

        if (randomNumber < JACKPOT_PERCENT) {
            // Add to the jackpot pool
            jackpotPool += SPIN_COST;
            prizeAmount = jackpotPool;
            jackpotPool = 0;
        } else {
            // Add to the prize pool
            prizePool += SPIN_COST * PRIZE_POOL_PERCENT / 100;
            prizeAmount = SPIN_COST * PRIZE_POOL_PERCENT / 100;
            prizePool -= prizeAmount;
        }

        // Add to the dev fee pool
        devFeePool += SPIN_COST * DEV_FEE_PERCENT / 100;

        // Send the prize to the user
        payable(msg.sender).transfer(prizeAmount);

        // Emit the spin result event
        emit SpinResult(msg.sender, spinCount, prizeAmount);
    }

    function addPoolReward(address tokenAddress, uint amount) external {
        require(msg.sender == owner, "Only owner can add pool reward");
        require(amount > 0, "Amount should be greater than 0");

        // Transfer the tokens to the contract
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        // Add the reward to the prize pool
        prizePool += amount;
    }

    function withdrawDevFee() external {
        require(msg.sender == owner, "Only owner can withdraw dev fee");
        require(devFeePool > 0, "No dev fee available to withdraw");

        // Send the dev fee to the owner
        payable(owner).transfer(devFeePool);
        devFeePool = 0;
    }
}