pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MultiTokenTransfer is Ownable, Pausable {
    using SafeERC20 for IERC20;

    struct TokenAmount {
        address token;
        uint256 amount;
    }

    struct TokenAmountRecipient {
        address token;
        uint256 amount;
        address recipient;
    }

    mapping(address => bool) public whitelistedTokens;
    mapping(address => bool) public allowedUsers;

    event TokenTransferred(address indexed token, address indexed sender, address indexed recipient, uint256 amount);
    event WhitelistedTokenUpdated(address indexed tokenAddress, bool whitelisted);
    event AllowedUserUpdated(address indexed user, bool allowed);

    function isERC20(address tokenAddress) public view returns (bool) {
        try IERC20(tokenAddress).totalSupply() {
            return true;
        } catch {
            return false;
        }
    }

    function addWhitelistedTokenAddress(address tokenAddress) external onlyAllowedUser {
        require(tokenAddress != address(0), "Token address cannot be zero");
        require(isERC20(tokenAddress), "Invalid ERC20 token address.");

        whitelistedTokens[tokenAddress] = true;
        emit WhitelistedTokenUpdated(tokenAddress, true);
    }

    function removeWhitelistedTokenAddress(address tokenAddress) external onlyAllowedUser {
        require(tokenAddress != address(0), "Token address cannot be zero");

        whitelistedTokens[tokenAddress] = false;
        emit WhitelistedTokenUpdated(tokenAddress, false);
    }

    function addAllowedUser(address user) external onlyOwner {
        allowedUsers[user] = true;
        emit AllowedUserUpdated(user, true);
    }

    function removeAllowedUser(address user) external onlyOwner {
        allowedUsers[user] = false;
        emit AllowedUserUpdated(user, false);
    }

    function pause() external onlyAllowedUser {
        _pause();
    }

    function unpause() external onlyAllowedUser {
        _unpause();
    }

    fallback() external payable {
        revert("No incoming ETH transfers allowed");
    }

    receive() external payable {
        revert("No incoming ETH transfers allowed");
    }

    modifier onlyAllowedUser() {
        require(allowedUsers[msg.sender] || msg.sender == owner(), "Caller is not an allowed user or the owner");
        _;
    }

    function transferTokens(
        TokenAmount[] calldata tokenAmounts,
        address recipient
    ) external onlyAllowedUser whenNotPaused {
        require(recipient != address(0), "Recipient address cannot be zero");
        IERC20 token;

        for (uint256 i = 0; i < tokenAmounts.length; i++) {
            address tokenAddress = tokenAmounts[i].token;
            uint256 amount = tokenAmounts[i].amount;

            require(whitelistedTokens[tokenAddress], "Token not whitelisted");
            require(amount > 0, "Amount must be greater than zero");

            token = IERC20(tokenAddress);

            // Use safeTransferFrom without separate balance and allowance checks
            token.safeTransferFrom(msg.sender, recipient, amount);
            emit TokenTransferred(tokenAddress, msg.sender, recipient, amount);
        }
    }

    function transferMultipleTokensToMultipleRecipients(
        TokenAmountRecipient[] calldata transfers
    ) external onlyAllowedUser whenNotPaused {
        IERC20 token;
        for (uint256 i = 0; i < transfers.length; i++) {
            address tokenAddress = transfers[i].token;
            uint256 amount = transfers[i].amount;
            address recipient = transfers[i].recipient;

            require(
                recipient != address(0) && whitelistedTokens[tokenAddress],
                "Recipient address cannot be zero or token not whitelisted"
            );
            require(amount > 0, "Amount must be greater than zero");
            
            token = IERC20(tokenAddress);

            // Use safeTransferFrom without separate balance and allowance checks
            token.safeTransferFrom(msg.sender, recipient, amount);
            emit TokenTransferred(tokenAddress, msg.sender, recipient, amount);
        }
    }

    function withdrawERC20(address tokenAddress, uint256 amount) external onlyAllowedUser whenNotPaused {
        require(tokenAddress != address(0), "Token address cannot be zero");
        require(isERC20(tokenAddress), "Invalid ERC20 token address");

        IERC20 token = IERC20(tokenAddress);
        uint256 contractBalance = token.balanceOf(address(this));

        require(amount <= contractBalance, "Not enough tokens in the contract");

        token.safeTransfer(owner(), amount);
    }
}