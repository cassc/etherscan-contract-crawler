// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
    PANDEMONIUM
    $CHAOS

    Website: https://pandemonium.wtf
    Twitter: https://twitter.com/Chaotic_DeFi
    Telegram: https://t.me/chaoticdefi
 */

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IPandemoniumToken is IERC20 {
    function mint(address to, uint amount) external returns (bool);
    function burn(uint amount) external returns (bool);
    function rebase() external returns (uint);
    function canRebase() external view returns (bool);
}

contract PandemoniumVault is Ownable {
    using SafeMath for uint;

    struct User {
        uint stakedAmount;
        uint vestingAmount;
        uint vestingTimestamp;
    }

    mapping (address => User) public users;

    uint public vestingPeriod = 4 hours;
    uint public lockPenalty = 20; // 20% of deposited amount

    IPandemoniumToken private token;
    address private lockFeeReceiver;

    event VestingPeriodUpdated(
        uint oldVestingPeriod,
        uint newVestingPeriod
    );

    event LockPenaltyUpdated(
        uint oldLockPenalty,
        uint newLockPenalty
    );

    event LockFeeReceiverUpdated(
        address oldLockFeeReceiver,
        address newLockFeeReceiver
    );

    event Staked(
        address indexed user,
        uint amount,
        uint fee
    );

    event Withdrawn(
        address indexed user,
        uint amount,
        uint timestamp
    );

    event Claimed(
        address indexed user,
        uint amount
    );

    constructor(
        address _token
    ) {
        token = IPandemoniumToken(_token);
    }

    /** EXTERNAL FUNCTIONS */

    function stake(uint amount) external returns (bool) {
        require(amount > 0, "Amount must be larger than zero");

        uint fee = amount.mul(lockPenalty).div(100);

        users[msg.sender].stakedAmount += amount.sub(fee);

        token.transferFrom(msg.sender, address(this), amount);
        token.transfer(lockFeeReceiver, fee);
        token.burn(amount.sub(fee));

        if (token.canRebase()) {
            token.rebase();
        }

        emit Staked(msg.sender, amount.sub(fee), fee);
        return true;
    }

    function withdraw(uint amount) external returns (bool) {
        require(amount <= users[msg.sender].stakedAmount, "Amount must be less than staked amount");

        users[msg.sender].stakedAmount -= amount;
        users[msg.sender].vestingAmount += amount;
        users[msg.sender].vestingTimestamp = block.timestamp;

        if (token.canRebase()) {
            token.rebase();
        }

        emit Withdrawn(msg.sender, amount, block.timestamp);
        return true;
    }

    function claim() external returns (bool) {
        require(
            users[msg.sender].vestingAmount > 0, 
            "Vesting amount is zero"
        );
        
        require(
            users[msg.sender].vestingTimestamp.add(vestingPeriod) < block.timestamp,
            "Vesting is not finished yet"
        );

        uint amount = users[msg.sender].vestingAmount;
        users[msg.sender].vestingAmount = 0;

        token.mint(msg.sender, amount);

        if (token.canRebase()) {
            token.rebase();
        }

        emit Claimed(msg.sender, amount);
        return true;
    }

    /** OWNER FUNCTIONS */

    function setVestingPeriod(uint period) external onlyOwner {
        emit VestingPeriodUpdated(vestingPeriod, period);
        vestingPeriod = period;
    }

    function setLockPenalty(uint penalty) external onlyOwner {
        emit LockPenaltyUpdated(lockPenalty, penalty);
        lockPenalty = penalty;
    }

    function setLockFeeReceiver(address receiver) external onlyOwner {
        emit LockFeeReceiverUpdated(lockFeeReceiver, receiver);
        lockFeeReceiver = receiver;
    }
}