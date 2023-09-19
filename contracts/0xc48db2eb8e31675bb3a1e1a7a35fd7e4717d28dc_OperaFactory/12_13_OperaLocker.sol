pragma solidity ^0.8.17;

//SPDX-License-Identifier: MIT
import "IERC20.sol";

// import "Math.sol";

contract OperaLocker {
    address public owner;
    mapping(address => bool) public lockDisabled;

    mapping(address => mapping(address => uint256)) public accountsLockedTokens;
    mapping(address => mapping(address => uint256))
        public accountsLockedTimeOfToken;

    event tokenLocked(
        address account,
        address token,
        uint256 amount,
        uint256 locktime
    );
    event tokenWithdrawn(address account, address token, uint256 amount);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "only owner");
        _;
    }

    function getAddressLockedTokens(
        address user,
        address token
    ) public view returns (uint256) {
        return accountsLockedTokens[user][token];
    }

    function changeLockEnabled(bool locked, address addy) external onlyOwner {
        lockDisabled[addy] = locked;
    }

    function getAddressLockedTime(
        address user,
        address token
    ) public view returns (uint256) {
        return accountsLockedTimeOfToken[user][token];
    }

    function withdrawTokenAmount(
        address tokenAddress,
        uint256 amount
    ) external {
        if (!lockDisabled[tokenAddress]) {
            require(
                accountsLockedTimeOfToken[msg.sender][tokenAddress] > 0 &&
                    accountsLockedTimeOfToken[msg.sender][tokenAddress] <=
                    block.timestamp,
                "Tokens are not ready to be unlocked."
            );
        }

        require(
            accountsLockedTokens[msg.sender][tokenAddress] >= amount,
            "You did not lock this many tokens."
        );
        if (accountsLockedTokens[msg.sender][tokenAddress] == amount) {
            accountsLockedTimeOfToken[msg.sender][tokenAddress] = 0; //resetting timer for lock to indicate no tokens locked
        }
        accountsLockedTokens[msg.sender][tokenAddress] -= amount;
        IERC20 tokenToLock = IERC20(tokenAddress);
        uint256 balanceBefore = tokenToLock.balanceOf(address(this));
        tokenToLock.transfer(msg.sender, amount);
        uint256 balanceAfter = tokenToLock.balanceOf(address(this));
        require(
            balanceBefore - amount == balanceAfter,
            "Failed to transfer amount of tokens when withdrawing."
        );
        emit tokenWithdrawn(msg.sender, tokenAddress, amount);
    }

    function lockTokens(
        address tokenAddress,
        uint256 amount,
        uint256 locktimeInSeconds
    ) external {
        require(
            accountsLockedTimeOfToken[msg.sender][tokenAddress] == 0,
            "You already have this tocken locked."
        );
        // require(amount > 0, "Cannot Lock 0 tokens");
        IERC20 tokenToLock = IERC20(tokenAddress);
        uint256 balanceBefore = tokenToLock.balanceOf(address(this));
        tokenToLock.transferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = tokenToLock.balanceOf(address(this));
        require(
            balanceAfter - amount == balanceBefore,
            "Failed to transfer amount of tokens when locking."
        );
        accountsLockedTokens[msg.sender][tokenAddress] = amount;
        accountsLockedTimeOfToken[msg.sender][tokenAddress] =
            block.timestamp +
            locktimeInSeconds;
        emit tokenLocked(
            msg.sender,
            tokenAddress,
            accountsLockedTokens[msg.sender][tokenAddress],
            block.timestamp + locktimeInSeconds
        );
    }

    function increaseLockTime(
        address tokenAddress,
        uint256 increasedSeconds
    ) external {
        require(
            accountsLockedTimeOfToken[msg.sender][tokenAddress] > 0,
            "You have no tokens locked."
        );
        require(increasedSeconds > 0, "Cannot Lock 0 seconds");
        accountsLockedTimeOfToken[msg.sender][tokenAddress] += increasedSeconds;
        emit tokenLocked(
            msg.sender,
            tokenAddress,
            accountsLockedTokens[msg.sender][tokenAddress],
            accountsLockedTimeOfToken[msg.sender][tokenAddress]
        );
    }

    function increaseTokenAmount(
        address tokenAddress,
        uint256 amount
    ) external {
        require(
            accountsLockedTimeOfToken[msg.sender][tokenAddress] > 0,
            "You have no tokens locked."
        );
        require(amount > 0, "Cannot Lock 0 tokens");
        IERC20 tokenToLock = IERC20(tokenAddress);
        uint256 balanceBefore = tokenToLock.balanceOf(address(this));
        tokenToLock.transferFrom(msg.sender, address(this), amount);
        uint256 balanceAfter = tokenToLock.balanceOf(address(this));
        require(
            balanceAfter - amount == balanceBefore,
            "Failed to transfer amount of tokens when locking."
        );
        accountsLockedTokens[msg.sender][tokenAddress] += amount;
        emit tokenLocked(
            msg.sender,
            tokenAddress,
            accountsLockedTokens[msg.sender][tokenAddress],
            accountsLockedTimeOfToken[msg.sender][tokenAddress]
        );
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function emergencyRescue(address token, uint256 amount) external onlyOwner {
        IERC20 tokenToRescue = IERC20(token);
        tokenToRescue.transfer(owner, amount);
    }

    receive() external payable {}
}