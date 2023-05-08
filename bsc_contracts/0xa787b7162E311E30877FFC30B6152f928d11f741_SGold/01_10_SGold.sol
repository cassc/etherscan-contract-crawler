/**
 *Submitted for verification on 2023-05-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Importing external contracts
import "./MultiSigWallet.sol";
import "./Ownable.sol";
import "./AggregatorV3Interface.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./SGoldDraw.sol";
import "./SafeMath.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";

contract SGold {
    // Token metadata
    string public name = "SGold";
    string public symbol = "SGOLD";
    uint8 public decimals = 18; 
    uint256 public totalSupply = 100000000 * 10 ** decimals; // maximum number of SGold token pool

    // Token distribution
    uint256 public pool;
    uint256 public monthlySupply = 500000 * 10 ** decimals; // monthly number of tokens added to the general pool of SGold
    uint256 public lastSupplyDate;

    // Ownership and account blocking
    address public owner;
    mapping(address => bool) public ownerships;
    mapping(address => bool) public blocked;
    mapping(address => mapping(address => uint256)) allowed;

    // Balances
    mapping(address => uint256) balances;

    // Get token balance of an address
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    /**
    * @dev Modifier that allows a function to be called only by the contract owner.
    *
    * This modifier checks if the caller of the function is the contract owner.
    * If the caller is not the owner, it reverts the transaction with an error message.
    * If the caller is the owner, it proceeds with the execution of the function.
    */
    modifier onlyOwner() {
    require(msg.sender == owner, "Only the contract owner can call this function");
    _;
    }

    // A function to retrieve the value of owner
    function getOwner() public view returns (address) {
        return owner;
    }

    AggregatorV3Interface private priceFeed;
    uint256 private sGoldPrice;

    constructor() {
    // Contract initialization...
    priceFeed = AggregatorV3Interface(0x86896fEB19D8A607c3b11f2aF50A0f239Bd71CD0);
    owner = msg.sender;
    updateSGoldPrice();
    pool = 30000000 * 10 ** decimals; // the starting number of SGold tokens released
    owner = msg.sender;
    balances[msg.sender] = pool;
    emit Transfer(address(0), msg.sender, pool);
    }

    // Function to update the SGold price based on Chainlink Aggregator
    function updateSGoldPrice() internal {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");

        sGoldPrice = uint256(price) * 10 ** (decimals - priceFeed.decimals());
    }

    // Function to get the current SGold price
    function getSGoldPrice() public view returns (uint256) {
        return sGoldPrice;
    }

    /**
     * @dev Updates the price from Chainlink.
     * @return The updated price of sGold.
     */
    function updatePrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");

        // Process the price
        uint256 updatedPrice = uint256(price) * 1e10; // Example conversion to sGold price (multiplier 1e10)

        // Perform further operations with the new price...

        return updatedPrice;
    }

    /**
    * @dev Emitted when the price feed contract address is updated.
    * @param newPriceFeed The new price feed contract address.
    */
    event PriceFeedSet(address indexed newPriceFeed);

   // Function to continuously update the SGold price every minute
    function updatePriceEveryMinute() public {
    require(msg.sender == owner, "Only owner can call this function");

        while (true) {
            updateSGoldPrice();
            // Delay for 1 minute
            uint256 endTime = block.timestamp + 60;
            while (block.timestamp < endTime) {
                // Wait for 1 minute
            }
        }
    }

    /**
    * @dev Sets the price feed address.
    * @param newPriceFeed The new address of the price feed.
    */
    function setPriceFeed(address newPriceFeed) public onlyOwner {
    require(newPriceFeed != address(0), "Invalid price feed address");

    priceFeed = AggregatorV3Interface(newPriceFeed);
    emit PriceFeedSet(newPriceFeed);
    }

    // Get the allowance for a spender to spend on behalf of an owner
    function allowance(address ownerAddr, address spender) public view returns (uint256) {
    return allowed[ownerAddr][spender];
    }

    /**
     * @dev Internal function to set the allowance for a spender.
    * @param tokenOwner The address of the token owner.
    * @param spender The address of the token spender.
    * @param amount The allowance amount to set.
    */
    function _approve(address tokenOwner, address spender, uint256 amount) internal {
    require(tokenOwner != address(0), "Invalid token owner address");
    require(spender != address(0), "Invalid spender address");

    allowed[tokenOwner][spender] = amount;
    emit Approval(tokenOwner, spender, amount);
    }

    /**
    * @dev Increases the allowance for the spender to spend on behalf of the caller.
    * @param spender The address of the spender.
    * @param addedAmount The additional allowance amount to add.
    * @return A boolean value indicating whether the operation was successful.
    */
    function increaseAllowance(address spender, uint256 addedAmount) public returns (bool) {
    _approve(msg.sender, spender, allowed[msg.sender][spender] + addedAmount);
    return true;
    }

    /**
    * @dev Decreases the allowance for the spender to spend on behalf of the caller.
    * @param spender The address of the spender.
    * @param subtractedAmount The subtracted allowance amount to subtract.
    * @return A boolean value indicating whether the operation was successful.
    */
    function decreaseAllowance(address spender, uint256 subtractedAmount) public returns (bool) {
    uint256 currentAllowance = allowed[msg.sender][spender];
    require(subtractedAmount <= currentAllowance, "Exceeds allowed amount");

    _approve(msg.sender, spender, currentAllowance - subtractedAmount);
    return true;
    }

    // Transfer tokens from sender to recipient
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");
        require(!blocked[msg.sender], "Account is blocked");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
    * @dev Transfers tokens from one account to another, if allowed by the spender.
    * @param sender The address from which tokens will be transferred.
    * @param recipient The address to which tokens will be transferred.
    * @param amount The amount of tokens to be transferred.
    * @return A boolean value indicating whether the operation was successful.
    */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
    require(amount <= balances[sender], "Insufficient balance");

    uint256 allowedAmount = allowance(sender, msg.sender);
    require(amount <= allowedAmount, "Exceeds allowed amount");

    balances[sender] -= amount;
    balances[recipient] += amount;

    emit Transfer(sender, recipient, amount);
    return true;
    }

    // Burn tokens by sender, reducing total supply and pool
    function burn(uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");

        balances[msg.sender] -= amount;
        pool -= amount;
        totalSupply -= amount;

        emit Burn(msg.sender, amount);
        return true;
    }

    /**
    * @dev Burns a specific amount of tokens from the specified account, if allowed by the spender.
    * @param account The address from which tokens will be burned.
    * @param amount The amount of tokens to be burned.
    * @return A boolean value indicating whether the operation was successful.
    */
    function burnFrom(address account, uint256 amount) public returns (bool) {
    require(amount <= balances[account], "Insufficient balance");

    uint256 allowedAmount = allowance(account, msg.sender);
    require(amount <= allowedAmount, "Exceeds allowed amount");

    balances[account] -= amount;
    pool -= amount;
    totalSupply -= amount;

    emit Burn(account, amount);
    return true;
    }

    // Supply monthly tokens to the owner
    function supplyMonthly() public returns (bool) {
        require(ownerships[msg.sender], "Only contract owner can call this function");
        require(block.timestamp - lastSupplyDate >= 30 days, "Monthly supply not yet due");

        uint256 newSupply = monthlySupply;
        if (pool + monthlySupply > totalSupply) {
            newSupply = totalSupply - pool;
        }

        pool += newSupply;
        balances[owner] += newSupply;
        lastSupplyDate = block.timestamp;

        emit Supply(newSupply);
        return true;
    }

    /**
     * @dev Transfers ownership of the contract to a new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) public {
        require(ownerships[msg.sender], "Only contract owner can call this function");
        require(newOwner != address(0), "Invalid new owner address");

        owner = newOwner;

        emit OwnershipTransferred(newOwner);
    }

    /**
     * @dev Adds ownership of the contract to a new owner
     * @param newOwner The address of the new owner
     */
    function addOwnership(address newOwner) public {
        require(ownerships[msg.sender], "Only contract owner can call this function");
        require(newOwner != address(0), "Invalid new owner address");

        ownerships[newOwner] = true;

        emit OwnershipAdded(newOwner);
    }

    /**
     * @dev Removes ownership of the contract from an owner
     * @param ownerToRemove The address of the owner to remove
     */
    function removeOwnership(address ownerToRemove) public {
        require(ownerToRemove != address(0), "Invalid owner address");
        require(ownerships[msg.sender], "Only contract owner can call this function");
        require(ownerToRemove != owner, "Cannot remove contract owner");

        ownerships[ownerToRemove] = false;

        emit OwnershipRemoved(ownerToRemove);
    }

    /**
      * @dev Blocks an account from making transfers
     */
    function blockAccount() public {
        require(balanceOf(msg.sender) > 0, "Account balance is zero");

        blocked[msg.sender] = true;

        emit AccountBlocked(msg.sender);
    }

    /**
     * @dev Unblocks an account from making transfers
     */
    function unblockAccount() public {
        blocked[msg.sender] = false;
    }

    // Events

    /**
     * @dev Emitted when tokens are transferred from one address to another
     * @param from The address tokens are transferred from
     * @param to The address tokens are transferred to
     * @param value The amount of tokens transferred
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when tokens are burned from an address
     * @param from The address tokens are burned from
     * @param value The amount of tokens burned
     */
    event Burn(address indexed from, uint256 value);
    
    /**
     * @dev Emitted when the total supply of tokens is updated
     * @param value The updated total supply of tokens
     */
    event Supply(uint256 value);
    
    /**
     * @dev Emitted when ownership of the contract is transferred to a new owner
     * @param newOwner The address of the new owner
     */
    event OwnershipTransferred(address indexed newOwner);
    
    /**
     * @dev Emitted when ownership of the contract is added to a new owner
     * @param newOwner The address of the new owner
     */
    event OwnershipAdded(address indexed newOwner);
    
    /**
     * @dev Emitted when ownership of the contract is removed from an owner
     * @param ownerToRemove The address of the owner being removed
      */
    event OwnershipRemoved(address indexed ownerToRemove);
    
    /**
     * @dev Emitted when an account is blocked from making transfers
     * @param account The address of the blocked account
     */
    event AccountBlocked(address indexed account);

    /**
    * @dev Emitted when the allowance of a token owner is set or updated.
    *
    * This event is emitted when the `approve` function is called to set or update the allowance of a token owner
    * for a specific spender. It provides information about the owner, spender, and the updated allowance value.
    *
    * @param owner The address of the token owner whose allowance is being set or updated.
    * @param spender The address of the spender for whom the allowance is being set or updated.
    * @param value The new allowance value for the spender.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}