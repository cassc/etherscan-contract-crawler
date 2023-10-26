// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FayreTokenLocker is Ownable {
    struct LockData {
        uint256 lockId;
        address owner;
        uint256 amount;
        uint256 start;
        uint256 expiration;
    }

    struct BonusData {
        uint256 requiredAmount;
        uint256 bonus;
    }

    event Lock(address indexed owner, uint256 indexed lockId, uint256 indexed amount, LockData lockData);
    event Withdraw(address indexed owner, uint256 indexed lockId, uint256 indexed amount, LockData lockData);
    event Bonus(address indexed owner, uint256 indexed lockId, uint256 indexed bonusAmount, LockData lockData);

    address public tokenAddress;
    mapping(uint256 => LockData) public locksData;
    mapping(address => LockData) public usersLockData;
    uint256 public minLockDuration;
    uint256 public tokensForBonusesAmount;
    BonusData[] public bonusesData;
    uint256 public currentLockId;

    function setTokenAddress(address newTokenAddress) external onlyOwner {
        tokenAddress = newTokenAddress;
    }

    function setMinLockDuration(uint256 newMinLockDuration) external onlyOwner {
        minLockDuration = newMinLockDuration;
    }

    function addTokensBonus(uint256 requiredAmount, uint256 bonus) external onlyOwner {
        for (uint256 i = 0; i < bonusesData.length; i++)
            if (bonusesData[i].requiredAmount == requiredAmount)
                revert("Bonus already present");

        bonusesData.push(BonusData(requiredAmount, bonus));
    }

    function removeTokensBonus(uint256 requiredAmount) external onlyOwner {
        uint256 indexToDelete = type(uint256).max;

        for (uint256 i = 0; i < bonusesData.length; i++)
            if (bonusesData[i].requiredAmount == requiredAmount)
                indexToDelete = i;

        require(indexToDelete != type(uint256).max, "E#16");

        bonusesData[indexToDelete] = bonusesData[bonusesData.length - 1];

        bonusesData.pop();
    }

    function depositTokensForBonuses(uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid amount");

        _transferAsset(msg.sender, address(this), amount);

        tokensForBonusesAmount += amount;
    }

    function withdrawTokensForBonuses(uint256 amount) external onlyOwner {
        require(amount > 0, "Invalid amount");

        require(amount <= tokensForBonusesAmount, "Not enough tokens");

        _transferAsset(address(this), msg.sender, amount);

        tokensForBonusesAmount -= amount;
    }

    function lock(uint256 amount) external {
        require(amount > 0, "Invalid amount");

        LockData storage lockData = usersLockData[msg.sender];

        if (lockData.lockId == 0) {
            lockData.lockId = currentLockId++;
            lockData.owner = msg.sender;
        }

        lockData.amount += amount;
        lockData.start = block.timestamp;
        lockData.expiration = lockData.start + minLockDuration;

        locksData[lockData.lockId] = lockData;

        _transferAsset(msg.sender, address(this), amount);

        emit Lock(msg.sender, lockData.lockId, amount, lockData);
    }

    function withdraw() external {
        LockData storage lockData = usersLockData[msg.sender];

        require(lockData.amount > 0, "Already withdrawed");
        require(lockData.expiration < block.timestamp, "Lock not expired");

        uint256 bonusAmount = 0;

        for (uint256 i = 0; i < bonusesData.length; i++)
            if (lockData.amount >= bonusesData[i].requiredAmount)
                if (bonusAmount < bonusesData[i].bonus)
                    bonusAmount = bonusesData[i].bonus;

        uint256 amountToTransfer = lockData.amount;

        lockData.amount = 0;

        locksData[lockData.lockId] = lockData;

        _transferAsset(address(this), msg.sender, amountToTransfer);

        if (bonusAmount > 0) {
            _transferAsset(address(this), msg.sender, bonusAmount);

            tokensForBonusesAmount -= bonusAmount;

            emit Bonus(msg.sender, lockData.lockId, bonusAmount, lockData);
        }

        emit Withdraw(msg.sender, lockData.lockId, amountToTransfer, lockData);
    }

    function _transferAsset(address from, address to, uint256 amount) private {
        if (from == address(this))
            require(IERC20(tokenAddress).transfer(to, amount), "Error during transfer");
        else
            require(IERC20(tokenAddress).transferFrom(from, to, amount), "Error during transfer");
    }
}