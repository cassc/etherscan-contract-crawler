// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DepositManager is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public realINJ;

    uint256 public constant lockingPeriod = 7 days;

    mapping(address => uint256) public depositBalance;
    mapping(address => uint256) public depositUnlockTimestamp;

    bool public competitionEnded;

    event Withdrawal(address indexed staker, uint256 withdrawalAmount, uint256 withdrawalTimestamp);

    event Deposit(address indexed staker, uint256 depositAmount, uint256 depositUnlockTimestamp, uint256 depositTimestamp);

    modifier onlyValidWithdrawal(uint256 withdrawalAmount) {
        require(withdrawalAmount > 0, "Cannot withdraw amount of 0");
        require(
            depositUnlockTimestamp[msg.sender] <= block.timestamp || competitionEnded,
            "Cannot withdraw before unlocking period pass if competition still active"
        );
        _;
    }

    constructor(IERC20 realINJ_) public {
        realINJ = realINJ_;
    }

    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot deposit amount of 0");
        require(!competitionEnded, "Cannot deposit on inactive competition");

        realINJ.safeTransferFrom(msg.sender, address(this), amount);

        depositBalance[msg.sender] = depositBalance[msg.sender].add(amount);
        depositUnlockTimestamp[msg.sender] = block.timestamp.add(lockingPeriod);

        emit Deposit(msg.sender, amount, depositUnlockTimestamp[msg.sender], block.timestamp);
    }

    function withdraw(uint256 withdrawalAmount) external nonReentrant onlyValidWithdrawal(withdrawalAmount) {
        depositBalance[msg.sender] = depositBalance[msg.sender].sub(withdrawalAmount, "Cannot withdraw more than deposits");

        realINJ.safeTransfer(msg.sender, withdrawalAmount);
        emit Withdrawal(msg.sender, withdrawalAmount, block.timestamp);
    }

    function withdrawAll() external nonReentrant onlyValidWithdrawal(depositBalance[msg.sender]) {
        uint256 withdrawalAmount = depositBalance[msg.sender];
        depositBalance[msg.sender] = 0;

        realINJ.safeTransfer(msg.sender, withdrawalAmount);
        emit Withdrawal(msg.sender, withdrawalAmount, block.timestamp);
    }

    function endCompetition() external onlyOwner {
        competitionEnded = true;
    }
}