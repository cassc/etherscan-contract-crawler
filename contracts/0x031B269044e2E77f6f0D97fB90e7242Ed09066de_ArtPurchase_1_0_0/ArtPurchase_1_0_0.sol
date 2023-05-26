/**
 *Submitted for verification at Etherscan.io on 2023-04-27
*/

// SPDX-License-Identifier: MIT

                                                                           
/*
  ArtPurchase 1.0.0  img.art

  88                                                                         
  ""                                                                  ,d     
                                                                      88     
  88  88,dPYba,,adPYba,    ,adPPYb,d8       ,adPPYYba,  8b,dPPYba,  MM88MMM  
  88  88P'   "88"    "8a  a8"    `Y88       ""     `Y8  88P'   "Y8    88     
  88  88      88      88  8b       88       ,adPPPPP88  88            88     
  88  88      88      88  "8a,   ,d88  888  88,    ,88  88            88,    
  88  88      88      88   `"YbbdP"Y8  888  `"8bbdP"Y8  88            "Y888  
                           aa,    ,88                                        
                            "Y8bbdP"                                         
  
*/

pragma solidity ^0.8.0;

contract ArtPurchase_1_0_0 {

    address payable public owner;
    uint256 public minimumPayment;
    uint256 public totalPurchaseLimit;
    uint256 public currentPurchases;
    uint256 public userPurchaseLimit;

    mapping(address => string[]) public userIDs; // Change to string array
    mapping(address => uint256) public hasPurchased;

    event Purchase(address indexed purchaser, uint256 value, uint256 purchaseCount, string userID);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    constructor(uint256 _minimumPaymentInWei, uint256 _totalPurchaseLimit, uint256 _userPurchaseLimit) {
        owner = payable(msg.sender);
        minimumPayment = _minimumPaymentInWei; // Wei
        totalPurchaseLimit = _totalPurchaseLimit;
        userPurchaseLimit = _userPurchaseLimit;
    }

    struct PurchaseStatus {
        uint256 minimumPayment;
        uint256 totalPurchaseLimit;
        uint256 currentPurchases;
        uint256 userPurchaseLimit;
        uint256 hasPurchased;
    }

    function getPurchaseStatus(address user) public view returns (PurchaseStatus memory) {
        return PurchaseStatus(minimumPayment, totalPurchaseLimit, currentPurchases, userPurchaseLimit, hasPurchased[user]);
    }


    function purchase(string memory userID, uint256 _purchaseCount) external payable {
        require(_purchaseCount > 0, "Purchase count must be greater than 0.");
        require(msg.value >= minimumPayment * _purchaseCount, "Total payment is below the minimum amount.");
        require(hasPurchased[msg.sender] + _purchaseCount <= userPurchaseLimit, "User purchase limit exceeded.");
        require(currentPurchases + _purchaseCount <= totalPurchaseLimit, "Total purchase limit reached.");

        hasPurchased[msg.sender] += _purchaseCount;
        userIDs[msg.sender].push(userID); // Add userID to the array for the sender's address
        currentPurchases += _purchaseCount;

        emit Purchase(msg.sender, msg.value, _purchaseCount, userID);
    }

    function updateMinimumPayment(uint256 _newMinimumPaymentInWei) external onlyOwner {
        minimumPayment = _newMinimumPaymentInWei; // Wei
    }

    function setTotalPurchaseLimit(uint256 _totalPurchaseLimit) external onlyOwner {
        totalPurchaseLimit = _totalPurchaseLimit;
    }

    function setUserPurchaseLimit(uint256 _userPurchaseLimit) external onlyOwner {
        userPurchaseLimit = _userPurchaseLimit;
    }

    function withdrawFunds(address payable _to) external onlyOwner {
        uint256 balance = address(this).balance;
        _to.transfer(balance);
    }

    function withdrawTokens(address _tokenAddress, address _to, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(_to, _amount);
    }

    function getUserID(address _user, uint256 _index) public view returns (string memory) {
        return userIDs[_user][_index];
    }

    function getUserIDCount(address _user) public view returns (uint256) {
        return userIDs[_user].length;
    }
}

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
}