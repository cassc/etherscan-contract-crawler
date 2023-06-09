// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract ToysTools {

    address payable public owner;
    mapping(uint256 => uint256) public packagePrices;
    mapping(address => uint256) public packageExpirationDates;
    bool private reentrancyLock; 

    event PackagePurchased(
        uint256 indexed packageId,
        address indexed buyer,
        uint256 expirationDate,
        string discordId
    );

    constructor() {
        owner = payable(msg.sender);

        packagePrices[1] = 0.05 ether;
        packagePrices[2] = 0.07 ether;
        packagePrices[3] = 0.1 ether;
    }

    function purchasePackage(uint256 packageId, string memory discordId) external payable {
        require(packageId >= 1 && packageId <= 3, "Invalid package ID");
        require(msg.value >= packagePrices[packageId], "Insufficient payment");

        uint256 expirationDate = block.timestamp + 30 days;
        packageExpirationDates[msg.sender] = expirationDate;

        emit PackagePurchased(packageId, msg.sender, expirationDate, discordId);
    }

    function adjustPackagePrice(uint256 packageId, uint256 newPrice) external {
        require(msg.sender == owner, "Only the contract owner can adjust the package price");
        require(packageId >= 1 && packageId <= 3, "Invalid package ID");
        require(newPrice > 0, "Price must be greater than zero");

        packagePrices[packageId] = newPrice;
    }

    function retrieveFunds() external {
        require(msg.sender == owner, "Only the contract owner can retrieve funds");
        require(!reentrancyLock, "Reentrancy attack detected");

        reentrancyLock = true;

        uint256 contractBalance = address(this).balance;
        owner.transfer(contractBalance);

        reentrancyLock = false;  
    }
}