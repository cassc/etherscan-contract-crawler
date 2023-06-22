/**
 *Submitted for verification at Etherscan.io on 2023-06-19
*/

// SPDX-License-Identifier: MIT

/**
 *⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 *⠀⠀⠀⠀⠈⢻⣿⠛⠻⢷⣄⠀⠀ ⣴⡟⠛⠛⣷⠀ ⠘⣿⡿⠛⠛⢿⡇⠀⠀⠀⠀
 *⠀⠀⠀⠀⠀⢸⣿⠀⠀ ⠈⣿⡄⠀⠿⣧⣄⡀ ⠉⠀⠀ ⣿⣧⣀⣀⡀⠀⠀⠀⠀⠀
 *⠀⠀⠀⠀⠀⢸⣿⠀⠀ ⢀⣿⠃ ⣀ ⠈⠉⠻⣷⡄⠀ ⣿⡟⠉⠉⠁⠀⠀⠀⠀⠀
 *⠀⠀⠀⠀⢠⣼⣿⣤⣴⠿⠋⠀ ⠀⢿⣦⣤⣴⡿⠁ ⢠⣿⣷⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 *
 *      - Defining Successful Future -
 *
 */

pragma solidity ^0.8.0;

/**
 *
 * @title DSF - TokenDistribution
 * @notice Contract for distributing tokens to multiple recipients.
 * This contract allows the owner or an allowed address to distribute tokens to a list of recipients in a single transaction.
 * @dev The TokenDistribution contract facilitates the distribution of tokens from the owner's or an allowed address to multiple recipients.
 * The owner can add or remove addresses from the list of allowed addresses.
 * The contract does not store user funds; instead, it transfers the tokens directly from the owner's address to the recipients.
 *
 */

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract TokenDistribution {
    address private _owner;
    address[] private _allowedAddresses;

    event AddressAdded(address indexed addedAddress);
    event AddressRemoved(address indexed removedAddress);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokensDistributed(address indexed tokenAddress, address[] recipients, uint256[] amounts);

    /**
     * @dev Modifier that allows only the contract owner to call a function.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the contract owner can call this function");
        _;
    }

    constructor() {
        _owner = msg.sender;
        _allowedAddresses.push(_owner);
    }

    /**
     * @dev Allows the contract owner to add an address that is allowed to distribute tokens.
     * @param addressToAdd The address to be added.
     */ 
    function addAllowedAddress(address addressToAdd) external onlyOwner {
        require(addressToAdd != address(0), "Invalid address");
        require(!isAddressAllowed(addressToAdd), "Address already allowed");
        
        _allowedAddresses.push(addressToAdd);
        emit AddressAdded(addressToAdd);
    }

    /**
     * @dev Allows the contract owner to remove an address from the list of allowed addresses.
     * @param addressToRemove The address to be removed.
     */
    function removeAllowedAddress(address addressToRemove) external onlyOwner {
        require(addressToRemove != address(0), "Invalid address");
        
        for (uint256 i = 0; i < _allowedAddresses.length; i++) {
            if (_allowedAddresses[i] == addressToRemove) {
                delete _allowedAddresses[i];
                break;
            }
        }

        emit AddressRemoved(addressToRemove);
    }

    /**
     * @dev Returns an array of all the allowed addresses.
     */
    function getAllowedAddresses() external view onlyOwner returns (address[] memory) {
        return _allowedAddresses;
    }

    /**
     * @dev Checks if an address is allowed to distribute tokens.
     * @param addressToCheck The address to be checked.
     * @return A boolean value indicating whether the address is allowed.
     */
    function isAddressAllowed(address addressToCheck) public view returns (bool) {
        for (uint256 i = 0; i < _allowedAddresses.length; i++) {
            if (_allowedAddresses[i] == addressToCheck) {
                return true;
            }
        }
        return false;
    }

    /**
     * @dev Distributes tokens to multiple recipients.
     * @param recipients An array of recipient addresses.
     * @param amounts An array of token amounts to be distributed to each recipient.
     * @param tokenAddress The address of the token smart contract.
     */
    function distributeTokens(address[] memory recipients, uint256[] memory amounts, address tokenAddress) external {
        require(tokenAddress != address(0), "Invalid token address");
        require(recipients.length == amounts.length, "Invalid input");
        require(isAddressAllowed(msg.sender), "Caller is not allowed to distribute tokens");
        require(checkSenderBalanceForTransfer(amounts, tokenAddress, msg.sender), "Insufficient balance to distribute tokens");

        IERC20 token = IERC20(tokenAddress);

        for (uint256 i = 0; i < recipients.length; i++) {
            token.transferFrom(msg.sender, recipients[i], amounts[i]);
        }
        
        emit TokensDistributed(tokenAddress, recipients, amounts);
    }

    /**
     * @dev Transfers ownership of the contract to a new address.
     * @param newOwner The address of the new owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        address previousOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    /**
     * @dev Calculates the sum of all elements in an array of uint256 values.
     * @param amounts An array of uint256 values.
     * @return The sum of all elements.
     */
    function getAmountsSum(uint256[] memory amounts) internal pure returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            sum += amounts[i];
        }
        return sum;
    }

    /**
     * @dev Checks if the sender has sufficient balance to transfer the specified amounts of tokens.
     * @param amounts An array of token amounts to be transferred.
     * @param tokenAddress The address of the token smart contract.
     * @param senderAddress The address of the sender.
     * @return A boolean value indicating whether the sender has sufficient balance.
     */
    function checkSenderBalanceForTransfer(uint256[] memory amounts, address tokenAddress, address senderAddress) public view returns (bool) {
        
        IERC20 token = IERC20(tokenAddress);

        uint256 totalAmount = getAmountsSum(amounts);
        if (token.balanceOf(senderAddress) >= totalAmount) {
            return true;
        }

        return false;
    }
}