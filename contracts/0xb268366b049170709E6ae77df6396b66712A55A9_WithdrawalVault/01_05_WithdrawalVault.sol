// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface ISLPCore {
    function addReward(uint256 amount) external;

    function removeReward(uint256 amount) external;

    function depositWithdrawal() external payable;

    function tokenPool() external view returns (uint256);
}

interface ISLPDeposit {
    function depositETH() external payable;

    function withdrawETH(address recipient, uint256 amount) external;
}

contract WithdrawalVault is OwnableUpgradeable {
    /* ========== EVENTS ========== */

    event RewardAdded(address indexed sender, uint256 amount);
    event RewardRemoved(address indexed sender, uint256 amount);
    event WithdrawalNodeIncreased(address indexed sender, uint256 number);
    event FlashWithdrawalNodeIncreased(address indexed sender, uint256 number);
    event SLPCoreSet(address indexed sender, address slpCore);
    event OperatorSet(address indexed sender, address operator);
    event RewardNumeratorSet(address indexed sender, uint256 rewardNumerator);
    event EthDeposited(address indexed sender, uint256 tokenAmount);

    /* ========== CONSTANTS ========== */

    uint256 public constant DEPOSIT_SIZE = 32 ether;
    uint256 public constant REWARD_DENOMINATOR = 1e18;

    /* ========== STATE VARIABLES ========== */

    ISLPCore public slpCore;
    ISLPDeposit public slpDeposit;
    address public operator;

    uint256 public withdrawalNodeNumber;
    uint256 public rewardNumerator;

    mapping(uint256 => bool) public rewardDays;

    uint256 public flashWithdrawalNodeNumber;

    function initialize(address _slpDeposit, address _operator, uint256 _rewardNumerator) public initializer {
        require(_slpDeposit != address(0), "Invalid SLP deposit address");
        require(_operator != address(0), "Invalid operator address");
        require(_rewardNumerator <= REWARD_DENOMINATOR, "Reward numerator too large");
        super.__Ownable_init();

        slpDeposit = ISLPDeposit(_slpDeposit);
        operator = _operator;
        rewardNumerator = _rewardNumerator;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function increaseWithdrawalNode(uint256 n) external onlyOperator {
        uint256 withdrawalAmount = n * DEPOSIT_SIZE;
        require(withdrawalAmount <= address(this).balance, "Not enough ETH");

        withdrawalNodeNumber += n;
        slpCore.depositWithdrawal{value: withdrawalAmount}();

        emit WithdrawalNodeIncreased(msg.sender, n);
    }

    function flashWithdrawalNode(uint256 n) external onlyOperator {
        uint256 withdrawalAmount = n * DEPOSIT_SIZE;
        require(withdrawalAmount <= address(slpDeposit).balance, "Not enough ETH");

        slpDeposit.withdrawETH(address(this), withdrawalAmount);
        withdrawalNodeNumber += n;
        flashWithdrawalNodeNumber += n;
        slpCore.depositWithdrawal{value: withdrawalAmount}();

        emit WithdrawalNodeIncreased(msg.sender, n);
        emit FlashWithdrawalNodeIncreased(msg.sender, n);
    }

    function addReward(uint256 _rewardAmount) external onlyOperator checkReward(_rewardAmount) {
        uint256 paidAt = getTodayTimestamp();
        require(!rewardDays[paidAt], "Paid today");
        rewardDays[paidAt] = true;

        require(_rewardAmount <= address(this).balance, "Not enough ETH");
        slpCore.addReward(_rewardAmount);
        slpDeposit.depositETH{value: _rewardAmount}();

        emit RewardAdded(msg.sender, _rewardAmount);
    }

    function removeReward(uint256 _rewardAmount) external onlyOperator checkReward(_rewardAmount) {
        uint256 rewardAt = getTodayTimestamp();
        require(!rewardDays[rewardAt], "Paid today");
        rewardDays[rewardAt] = true;

        slpCore.removeReward(_rewardAmount);

        emit RewardRemoved(msg.sender, _rewardAmount);
    }

    function setSLPCore(address _slpCore) external onlyOwner {
        require(_slpCore != address(0), "Invalid SLP core address");
        slpCore = ISLPCore(_slpCore);
        emit SLPCoreSet(msg.sender, _slpCore);
    }

    function setOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "Invalid operator address");
        operator = _operator;
        emit OperatorSet(msg.sender, _operator);
    }

    function setRewardNumerator(uint256 _rewardNumerator) external onlyOwner {
        require(_rewardNumerator <= REWARD_DENOMINATOR, "Reward numerator too large");
        rewardNumerator = _rewardNumerator;
        emit RewardNumeratorSet(msg.sender, _rewardNumerator);
    }

    function depositETH() external payable onlySlpDeposit {
        emit EthDeposited(msg.sender, msg.value);
    }

    /* ========== VIEWS ========== */

    function getTodayTimestamp() public view returns (uint256) {
        return (block.timestamp / (1 days)) * (1 days);
    }

    /* ========== MODIFIER ========== */

    modifier onlyOperator() {
        require(msg.sender == operator, "Caller is not operator");
        _;
    }

    modifier onlySlpDeposit() {
        require(msg.sender == address(slpDeposit), "Caller is not slpDeposit");
        _;
    }

    modifier checkReward(uint256 amount) {
        require(amount <= (slpCore.tokenPool() * rewardNumerator) / REWARD_DENOMINATOR, "Reward variation too large");
        _;
    }
}