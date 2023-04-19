/**
 *Submitted for verification at BscScan.com on 2023-04-19
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract MultiOwnable {
    address[] public owners;
    mapping(address => bool) public ownerByAddress;

    event AddOwner(address owners);

    modifier onlyOwner() {
        require(ownerByAddress[msg.sender] == true, "Owner required");
        _;
    }

    // MultiOwnable constructor sets the first owner
    constructor() {
        _addOwner(msg.sender);
    }

    // Add a new owner
    function addOwner(address _newOwner) public onlyOwner {
        _addOwner(_newOwner);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getOwnersLength() public view returns (uint256) {
        return owners.length;
    }

    function _addOwner(address _newOwner) internal {
        require(_newOwner != address(0), "Address 0 can't be owner");
        require(ownerByAddress[_newOwner] == false, "Address is already owner");
        ownerByAddress[_newOwner] = true;
        owners.push(_newOwner);
        emit AddOwner(_newOwner);
    }
}

contract Depositable is MultiOwnable {
    uint public constant SHARE_PERCENT_DIVISOR = 1e18;

    IERC20 public immutable depositToken;
    uint public depositEndDate;

    uint public totalDeposited;
    mapping(address => uint) public depositOf;
    address[] public depositors;

    event Deposit(address indexed user, uint amount);
    event DepositEndDateChanged(uint newDepositEndDate);

    modifier whenNotDepositPaused() {
        require(block.timestamp <= depositEndDate, "Deposit period ended");
        _;
    }

    constructor(address _depositToken) {
        depositToken = IERC20(_depositToken);
        depositEndDate = block.timestamp + 4 weeks;
    }

    function deposit(uint _amount) external whenNotDepositPaused {
        require(_amount > 0, "Cannot deposit 0");
        require(depositToken.transferFrom(msg.sender, address(this), _amount), "Deposit transfer failed");

        if (depositOf[msg.sender] == 0) {
            depositors.push(msg.sender);
        }

        depositOf[msg.sender] += _amount;
        totalDeposited += _amount;
    }

    function getDepositorShare(address _depositor) public view returns (uint) {
        return depositOf[_depositor] * SHARE_PERCENT_DIVISOR / totalDeposited;
    }

    function getDepositors() external view returns (address[] memory) {
        return depositors;
    }

    function depositorsCount() external view returns (uint) {
        return depositors.length;
    }

    function getDepositorsWithBalance() external view returns (address[] memory, uint[] memory) {
        uint[] memory balances = new uint[](depositors.length);
        uint len = depositors.length;
        for (uint i = 0; i < len;) {
            balances[i] = depositOf[depositors[i]];
            unchecked {
                i++;
            }
        }
        return (depositors, balances);
    }

    function setDepositEndDate(uint _newDepositEndDate) external onlyOwner {
        depositEndDate = _newDepositEndDate;
        emit DepositEndDateChanged(_newDepositEndDate);
    }
}

contract Withdrawable is MultiOwnable {
    event WithdrawalToken(uint amount, address indexed token);
    event Withdrawal(uint amount);

    // Allow owner to withdraw all for given token
    function withdrawToken(address tokenAddr, uint withdrawAmount) public onlyOwner {
        uint amount = IERC20(tokenAddr).balanceOf(address(this));
        require(withdrawAmount > 0, "Can't withdraw 0");
        require(amount > withdrawAmount, "Can't withdraw more than token balance");

        bool success = IERC20(tokenAddr).transfer(msg.sender, withdrawAmount);
        require(success, "Transfer failed");

        emit WithdrawalToken(withdrawAmount, tokenAddr);
    }

    function withdrawBNB(uint amount) public onlyOwner {
        require(amount > 0, "Withdraw amount must be greater than 0");
        require(amount <= address(this).balance, "Can't withdraw more than contract balance");

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "BNB transfer failed");

        emit Withdrawal(amount);
    }

    // Allow owner to withdraw all BNB
    function withdrawAllBNB() external onlyOwner {
        uint amount = address(this).balance;
        withdrawBNB(amount);
    }
}

contract ParkPool is Depositable, Withdrawable {
    struct Rewards {
        uint claimable;
        uint claimed;
    }

    mapping(address => Rewards) public rewardsByAddress;
    uint public totalClaimedRewards;
    uint public totalClaimableRewards;

    uint public totalRewardsDeposited;
    struct RewardDeposit {
        address from;
        uint amount;
        uint timestamp;
    }
    RewardDeposit[] public rewardsDeposits;

    event RewardClaimed(address indexed to, uint amount);
    event RewardsDeposited(address indexed from, uint amount);

    constructor(address _depositToken) Depositable(_depositToken) {}

    // Accept BNB and allocate a share to each depositor
    function depositReward() external payable {
        require(msg.value > 0, "Cannot deposit 0 rewards");

        uint len = depositors.length;
        uint userRewards;
        for (uint i = 0; i < len;) {
            address userAddr = depositors[i];
            uint rewardAmount = calculateReward(userAddr, msg.value);

            Rewards storage reward = rewardsByAddress[userAddr];
            reward.claimable += rewardAmount;

            unchecked {
                i++;
                userRewards += rewardAmount;
            }
        }

        totalClaimableRewards += userRewards;
        totalRewardsDeposited += msg.value;
        rewardsDeposits.push(
            RewardDeposit(msg.sender, msg.value, block.timestamp)
        );

        emit RewardsDeposited(msg.sender, msg.value);
    }

    // Given a total reward amount and the address of a user,
    // calculate how much of the reward the user is entitled to
    // (based on his share of the pool)
    function calculateReward(address user, uint amount) public view returns (uint) {
        return amount * getDepositorShare(user) / SHARE_PERCENT_DIVISOR;
    }

    function getRewardsDeposits() external view returns (RewardDeposit[] memory) {
        return rewardsDeposits;
    }

    // Claim the claimable rewards for msg.sender
    // If the contract doesn't have enough funds, claim all the funds it has
    function claimReward() external {
        Rewards storage reward = rewardsByAddress[msg.sender];
        uint amount = reward.claimable;
        require(amount > 0, "User has nothing to claim");
        require(address(this).balance > 0, "Contract has no funds");

        if (address(this).balance < amount) {
            amount = address(this).balance;
        }

        reward.claimable -= amount;
        reward.claimed += amount;
        emit RewardClaimed(msg.sender, amount);

        totalClaimedRewards += amount;
        totalClaimableRewards -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Reward transfer failed");
    }
}