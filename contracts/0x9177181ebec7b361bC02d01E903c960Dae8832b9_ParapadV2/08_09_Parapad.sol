// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Parapad is Ownable {
    using SafeERC20 for IERC20;

    address public usdtAddress;
    address public paradoxAddress;

    IERC20 internal para;
    IERC20 internal usdt;

    mapping(address => bool) public _claimed;

    uint256 internal constant PARADOX_DECIMALS = 10 ** 18;
    uint256 internal constant USDT_DECIMALS = 10 ** 6;

    uint256 internal constant EXCHANGE_RATE = 3;
    uint256 internal constant EXCHANGE_RATE_DENOMINATOR = 100;

    uint256 internal constant MONTH = 4 weeks;

    /** MAXIMUM OF $1000 per person */
    uint256 internal constant MAX_AMOUNT = 1000 * USDT_DECIMALS;

    mapping(address => Lock) public locks;

    struct Lock {
        uint256 total;
        uint256 paid;
        uint256 debt;
        uint256 startTime;
    }

    constructor(address _usdt, address _paradox) {
        usdtAddress = _usdt;
        usdt = IERC20(_usdt);

        paradoxAddress = _paradox;
        para = IERC20(_paradox);
    }

    function getClaimed(address _user) external view returns (bool) {
        return _claimed[_user];
    }

    function buyParadox(uint256 amount) external {
        require(!_claimed[msg.sender], "Limit reached");
        require(amount <= MAX_AMOUNT, "Wrong amount");
        // get exchange rate to para
        uint256 rate = (amount * EXCHANGE_RATE_DENOMINATOR * PARADOX_DECIMALS) /
            (USDT_DECIMALS * EXCHANGE_RATE);
        require(rate <= para.balanceOf(address(this)), "Low balance");
        // give user 20% now
        uint256 rateNow = (rate * 20) / 100;
        uint256 vestingRate = rate - rateNow;

        if (locks[msg.sender].total == 0) {
            // new claim
            locks[msg.sender] = Lock({
                total: vestingRate,
                paid: amount,
                debt: 0,
                startTime: block.timestamp
            });

            if (amount == MAX_AMOUNT) _claimed[msg.sender] = true;
        } else {
            // at this point, the user still has some pending amount they can claim
            require(amount + locks[msg.sender].paid <= MAX_AMOUNT, "Too Much");

            locks[msg.sender].total += vestingRate;
            if (amount + locks[msg.sender].paid == MAX_AMOUNT)
                _claimed[msg.sender] = true;
            locks[msg.sender].paid += amount;
        }

        usdt.safeTransferFrom(msg.sender, address(this), amount);
        para.safeTransfer(msg.sender, rateNow);
    }

    // New Function
    function pendingVestedParadox(
        address _user
    ) external view returns (uint256) {
        Lock memory userLock = locks[_user];

        uint256 monthsPassed = (block.timestamp - userLock.startTime) / 4 weeks;
        /** @notice 5% released each MONTH after 2 MONTHs */
        uint256 monthlyRelease = (userLock.total * 5) / 100;
        uint256 release;
        for (uint256 i = 0; i < monthsPassed; i++) {
            if (i >= 2) {
                if (release >= userLock.total) {
                    release = userLock.total;
                    break;
                }
                release += monthlyRelease;
            }
        }

        return release - userLock.debt;
    }

    // New Function
    function claimVestedParadox() external {
        Lock storage userLock = locks[msg.sender];
        require(userLock.total > userLock.debt, "Vesting Complete");

        uint256 monthsPassed = (block.timestamp - userLock.startTime) / 4 weeks;
        /** @notice 5% released each MONTH after 2 MONTHs */
        uint256 monthlyRelease = (userLock.total * 5) / 100;

        uint256 release;
        for (uint256 i = 0; i < monthsPassed; i++) {
            if (i >= 2) {
                if (release >= userLock.total) {
                    release = userLock.total;
                    break;
                }
                release += monthlyRelease;
            }
        }

        uint256 reward = release - userLock.debt;
        userLock.debt += reward;
        para.transfer(msg.sender, reward);
    }

    function withdrawTether(address _destination) external onlyOwner {
        usdt.safeTransfer(_destination, usdt.balanceOf(address(this)));
    }

    /** @notice EMERGENCY FUNCTIONS */
    function updateClaimed(address _user) external onlyOwner {
        _claimed[_user] = !_claimed[_user];
    }

    function updateUserLock(
        address _user,
        uint256 _total,
        uint256 _paid,
        uint256 _startTime
    ) external onlyOwner {
        Lock storage lock = locks[_user];
        lock.total = _total;
        lock.paid = _paid;
        lock.startTime = _startTime;
    }

    function withdrawETH() external onlyOwner {
        address payable to = payable(msg.sender);
        to.transfer(address(this).balance);
    }

    function withdrawParadox() external onlyOwner {
        para.safeTransfer(msg.sender, para.balanceOf(address(this)));
    }
}