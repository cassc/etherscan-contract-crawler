// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BlockX is ERC20, ERC20Burnable, Ownable {
    
    mapping(address => uint256) public userUnlockTime;
    
    constructor() ERC20("BlockX", "BCX") {
        _mint(msg.sender, 25000000 * 10 ** 18);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
    
    
    /**
    @dev Transfers tokens to an allowed address with a lock in period before which tokens can then be subsequently transfered - To be used at initial allocation of tokens to investors. Subsequent transfers should use the transfer method
    @param recipient The wallet address of the investor receiving the tokens
    @param amount The amount of tokens being alloted
    @param lockPeriodInDays The length of time in DAYS before which tokens cannot be transfered
   */
    function lockAndTransfer(
        address recipient,
        uint256 amount,
        uint256 lockPeriodInDays
    ) public onlyOwner() returns (bool) {
        require(lockPeriodInDays > 0, 'Lock in period is too short');
        uint256 lockInSeconds = block.timestamp + (lockPeriodInDays * 86400);
        if (lockPeriodInDays > 0) {
            userUnlockTime[recipient] = lockInSeconds;
            _transfer(_msgSender(), recipient, amount);
            return true;
        }
        return false;
    }
    
    /**
    @dev add list of locked address with lock in period
    @param addressesToLock list of wallet addresses that need to lock them
    @param lockPeriodInDays The length of time in DAYS before which tokens cannot be transfered
    */
    function lockAddresses(address[] memory addressesToLock, uint256 lockPeriodInDays) public onlyOwner() {
        require(lockPeriodInDays > 0, 'Lock in period is too short');
        uint256 lockInSeconds = block.timestamp + (lockPeriodInDays * 86400);
        for (uint256 i = 0; i < addressesToLock.length; i++) {
            userUnlockTime[addressesToLock[i]] = lockInSeconds;
        }
    }
    
    /**
    @dev unlock locked addresses
    @param unlocklist list of wallet addresses that need to unlock them
    */
    function unlockAddresses(address[] memory unlocklist) public onlyOwner() {
        for (uint256 i = 0; i < unlocklist.length; i++) {
            userUnlockTime[unlocklist[i]] = 0;
        }
    }
    
    function isLocked(address user) public view returns (bool) {
        uint256 _releaseTime = userUnlockTime[user];
        if (_releaseTime > 0) {
            if(block.timestamp < _releaseTime)
                return true;
        }            
        return false;
    }
    
    /**
    @dev List of checks before token transfers are allowed
    @param from The wallet address sending the tokens
    @param to The wallet address recieving the tokens
    @param amount The amount of tokens being transfered
   */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) view internal override {
        require(amount > 0, 'Amount must not be 0');
        if (_msgSender() != owner()) {
            require(!isLocked(from), 'Sender is not allowed to send the tokens yet'); 
        }
    }
}