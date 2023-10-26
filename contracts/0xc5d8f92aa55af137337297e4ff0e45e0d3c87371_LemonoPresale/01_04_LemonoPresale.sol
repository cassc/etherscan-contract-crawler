// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title LemonoPresale
 * @dev A contract for token presale where users can buy tokens using USDC.
 */
contract LemonoPresale is Ownable {
    IERC20 public usdcToken; // The USDC token contract
    uint256 public tokenPrice; // Price per token in Wei
    uint256 public minPurchase; // Minimum purchase amount in Wei
    uint8 public usdcDecimals; // Number of decimals for the USDC token
    address public devAddress; // The address where 5% of USDC withdrawals will be sent
    bool public saleIsActive = true; // Indicates whether the sale is active
    bool public saleIsPermanent = false; // Indicates whether the sale is permanent

    // Mapping to track the total tokens purchased by each buyer
    mapping(address => uint256) public totalPurchased;

    // Array to store the addresses of all buyers
    address[] public buyers;

    event SaleStateToggled(bool saleIsActive);
    event EndPermanentSale();
    event TokensPurchased(address indexed buyer, uint256 quantity);
    event USDCWithdrawn(address indexed recipient, uint256 amount);
    event NATIVEWithdrawn(address indexed recipient, uint256 amount);

    /**
     * @dev Constructor to initialize the contract with the USDC token address and developer address.
     * @param _usdcToken The address of the USDC token contract.
     * @param _devAddress The address where 5% of USDC withdrawals will be sent.
     * @param _decimals USDC decimals differs on different chains.
     */
    constructor(address _usdcToken, address _devAddress, uint8 _decimals) {
        usdcToken = IERC20(_usdcToken);
        usdcDecimals = _decimals;
        tokenPrice = 7 * 10**(_decimals - 3);
        minPurchase = 25 * 10**_decimals;
        devAddress = _devAddress;
    }

    /**
     * @dev Modifier to ensure that the sale is active.
     */
    modifier isActive() {
        require(saleIsPermanent || saleIsActive, "Sale is not active");
        _;
    }

    /**
     * @dev Toggle the state of the sale (active/inactive). Only the owner can call this function.
     */
    function toggleSaleState() external onlyOwner {
        require(!saleIsPermanent, "Sale has ended permanently");
        saleIsActive = !saleIsActive;
        emit SaleStateToggled(saleIsActive);
    }

    /**
     * @dev End the sale permanently. Only the owner can call this function.
     */
    function endPermanentSale() external onlyOwner {
        require(saleIsActive, "Sale is already inactive");
        saleIsActive = false;
        saleIsPermanent = true;
        emit EndPermanentSale();
    }

    /**
     * @dev Buy tokens using a specified amount of USDC. The purchase amount is in whole USDC units.
     * @param usdcAmount The amount of USDC to spend on tokens.
     */
    function buyTokens(uint256 usdcAmount) external isActive {
        require(usdcAmount >= minPurchase, "Purchase amount is below the minimum");

        // Calculate the quantity of tokens based on the purchase amount and the number of decimals
        uint256 qty = usdcAmount / tokenPrice;

        // Transfer USDC from the sender to this contract
        usdcToken.transferFrom(msg.sender, address(this), usdcAmount);
        emit TokensPurchased(msg.sender, qty);

        // Update the total tokens purchased by the sender and add them to the buyers list if necessary
        totalPurchased[msg.sender] += qty;
        if (totalPurchased[msg.sender] == qty) {
            buyers.push(msg.sender);
        }
    }

    /**
     * @dev Get the total number of buyers.
     * @return The total number of buyers.
     */
    function getBuyersCount() external view returns (uint256) {
        return buyers.length;
    }

    /**
     * @dev Get information about a specific buyer's total purchases.
     * @param index The index of the buyer in the buyers array.
     * @return The buyer's address and total tokens purchased.
     */
    function getBuyerInfo(uint256 index) external view returns (address, uint256) {
        require(index < buyers.length, "Index out of range");
        address buyer = buyers[index];
        uint256 amountPurchased = totalPurchased[buyer];
        return (buyer, amountPurchased);
    }

    /**
     * @dev Get information about all buyers and their total purchases.
     * @return An array of buyer addresses and their respective total tokens purchased.
     */
    function getAllBuyersInfo() external view returns (address[] memory, uint256[] memory) {
        address[] memory allBuyers = new address[](buyers.length);
        uint256[] memory totalPurchases = new uint256[](buyers.length);

        for (uint256 i = 0; i < buyers.length; i++) {
            address buyer = buyers[i];
            uint256 amountPurchased = totalPurchased[buyer];
            allBuyers[i] = buyer;
            totalPurchases[i] = amountPurchased;
        }

        return (allBuyers, totalPurchases);
    }

    /**
     * @dev Withdraw all available USDC tokens from the contract. Only the owner can call this function.
     */
    function withdrawAllUSDC() external onlyOwner {
        uint256 contractBalance = usdcToken.balanceOf(address(this));
        require(contractBalance > 0, "No USDC balance to withdraw");

        // Calculate 5% of the contract balance
        uint256 devAmount = (contractBalance * 5) / 100;
        uint256 ownerAmount = contractBalance - devAmount;

        // Transfer 95% to the owner
        usdcToken.transfer(owner(), ownerAmount);
        emit USDCWithdrawn(owner(), ownerAmount);

        // Transfer 5% to the developer address
        usdcToken.transfer(devAddress, devAmount);
        emit USDCWithdrawn(devAddress, devAmount);
    }

    /**
     * @dev Withdraw all available native tokens sent by accident to contract. Only the owner can call this function.
     */
    function withdrawNative() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No NATIVE balance to withdraw");
        payable(owner()).transfer(contractBalance);
        emit NATIVEWithdrawn(owner(), contractBalance);
    }
}