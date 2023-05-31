/**
 *Submitted for verification at Etherscan.io on 2023-05-29
*/

// SPDX-License-Identifier: MIT
/******************************************************************************************************
KOAM (King Of All Memes)
Website: https://koamcoin.com
Twitter: https://twitter.com/koamcoin
Telegram: https://t.me/koamcoin
******************************************************************************************************/
pragma solidity 0.8.17;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title KOAM (KOAM) Token
 * @dev ERC20 Token implementation
 */
contract KOAM is IERC20 {
    string public constant name = "KOAM";
    string public constant symbol = "KOAM";
    uint8 public constant decimals = 18;
    uint256 private constant totalTokenSupply = 1_000_000_000 * (10**uint256(decimals));
    uint256 private constant LAUNCH_MAX_TXN_PERIOD = 24 * 60 * 60;  // Launch day 24 Hours
    uint256 private constant LAUNCH_MAX_TXN_AMOUNT = 2_000_001 * (10**uint256(decimals)); // MAX TX during launch day

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    address private owner;
 

    // Additional variables for links
    string public constant telegramLink = "https://t.me/koamcoin";
    string public constant websiteLink = "http://koamcoin.com/";
    string public constant twitterLink = "http://twitter.com/koamcoin";

    uint256 private constant launchTime = 1685380200; // Timestamp of launch time (GMT: Monday 29 May 2023 17:10:00)

    // Events
    event OwnershipRenounced(address indexed previousOwner);

    /**
     * @dev Modifier to check if the caller is the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    /**
     * @dev Constructor function
     */
    constructor() {
        owner = msg.sender;
        balances[msg.sender] = totalTokenSupply;
        emit Transfer(address(0), msg.sender, totalTokenSupply);
    }

    /**
     * @dev Total supply of tokens
     * @return The total supply
     */
    function totalSupply() external pure override returns (uint256) {
        return totalTokenSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param account The address to query the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address account) external view override returns (uint256) {
        return balances[account];
    }

    /**
     * @dev Transfers tokens from the sender's account to another address.
     * @param recipient The address to transfer to.
     * @param amount The amount to be transferred.
     * @return True if the transfer is successful, false otherwise.
     */
    
    function transfer(address recipient, uint256 amount) external override returns (bool) {
    require(amount <= balances[msg.sender], "Insufficient balance");
    require(recipient != address(0), "Invalid recipient");

    if (block.timestamp > launchTime + LAUNCH_MAX_TXN_PERIOD) {
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    } else {
        require(amount <= LAUNCH_MAX_TXN_AMOUNT, "Exceeded maximum buy limit in the day of launch : 2M KOAM");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
}


    /**
     * @dev Transfers tokens from one address to another.
     * @param sender The address to transfer from.
     * @param recipient The address to transfer to.
     * @param amount The amount to be transferred.
     * @return True if the transfer is successful, false otherwise.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance");
        require(recipient != address(0), "Invalid recipient");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @dev Approve the spender to spend the specified amount of tokens on behalf of the sender.
     * @param spender The address authorized to spend.
     * @param amount The maximum amount that can be spent.
     * @return True if the approval is successful, false otherwise.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Returns the remaining number of tokens that the spender can spend on behalf of the owner.
     * @param ownerAddress The address that owns the tokens.
     * @param spender The address that can spend the tokens.
     * @return The remaining number of tokens to spend.
     */
    function allowance(address ownerAddress, address spender) external view override returns (uint256) {
        return allowances[ownerAddress][spender];
    }

    /**
     * @dev Renounce ownership of the contract.
     * @notice This function renounces ownership permanently and cannot be undone.
     */
    function renounceOwnership() external onlyOwner {
        owner = address(0);
        emit OwnershipRenounced(msg.sender);
    }

    /**
     * @dev Returns the Telegram link.
     * @return The Telegram link.
     */
    function getTelegramLink() external pure returns (string memory) {
        return telegramLink;
    }

    /**
     * @dev Returns the website link.
     * @return The website link.
     */
    function getWebsiteLink() external pure returns (string memory) {
        return websiteLink;
    }

    /**
     * @dev Returns the Twitter link.
     * @return The Twitter link.
     */
    function getTwitterLink() external pure returns (string memory) {
        return twitterLink;
    }
}