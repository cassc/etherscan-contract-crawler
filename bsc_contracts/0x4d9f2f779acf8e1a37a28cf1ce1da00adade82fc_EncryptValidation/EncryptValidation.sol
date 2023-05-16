/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract EncryptValidation {
    uint public totalAmount = 0;
    uint public totalInPool = 0;
    uint public totalForTeam = 0;
    uint public totalForBurns = 0;
    uint public totalCostForVerify = 300000000000; //300 + 9 decimal
    uint public claimAmountPublic = 2000000000;//2 + 9 decimal
    uint public claimWaitTime = 86400 * 7; // 24 hours times 7 days

    address public tokenAddress;
    mapping (address => uint) public lastClaimTime;
    address[] public validatedUsers;
    address[] public validatedTeam;
    address public owner;

    event UserVerified(address indexed user);
    event tokensBurnt(uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
        owner = msg.sender;
        validatedTeam.push(msg.sender);
    }

    function verifyUser() external {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), totalCostForVerify);
        
        uint amount = totalCostForVerify;
        totalAmount += amount;

        uint burnAmount = amount / 2;
        uint ownerAmount = amount / 10;
        totalInPool += amount - burnAmount - ownerAmount;
        totalForTeam += ownerAmount;
        totalForBurns += burnAmount;

        validatedUsers.push(msg.sender);
        emit UserVerified(msg.sender);
    }

    function publicClaim() public {
        require(lastClaimTime[msg.sender] + claimWaitTime <= block.timestamp, "You must wait before claiming again.");
        require(totalInPool > claimAmountPublic, "Not enough tokens in pool to claim.");
        
        uint i = 0;
        while (i < validatedUsers.length && claimAmountPublic > 0) {
            if (validatedUsers[i] == msg.sender) {
                lastClaimTime[msg.sender] = block.timestamp;
                IERC20(tokenAddress).transfer(msg.sender, claimAmountPublic);
                totalInPool -= claimAmountPublic;
            }
            i++;
        }
    }

    function ownerClaim() public onlyOwner {
        require(validatedTeam.length > 0, "No funds to claim.");

        IERC20(tokenAddress).transfer(owner, totalForTeam);
        totalForTeam = 0;
    }

    function ownerBurn() public onlyOwner {
        IERC20(tokenAddress).transfer(address(0x000000000000000000000000000000000000dEaD), totalForBurns);
        emit tokensBurnt(totalForBurns);
        totalForBurns = 0;
    }

    function changeClaimWaitTime(uint _newClaimWaitTime) public onlyOwner {
        claimWaitTime = _newClaimWaitTime;
    }

    function changeclaimAmountPublic(uint _newclaimAmountPublic) public onlyOwner {
        claimAmountPublic = _newclaimAmountPublic;
    }

    function changeTokenAddress(address _newTokenAddress) public onlyOwner {
        tokenAddress = _newTokenAddress;
    }

    function changeVerifyCost(uint _newAmount) public onlyOwner {
        totalCostForVerify = _newAmount;
    }

    function withdrawTokens(address tokenCA, address _to, uint256 _amount) public onlyOwner {
        IERC20(tokenCA).transfer(_to, _amount);
    }

    function addAddressTovalidatedUsers(address newAddress) public onlyOwner {
        validatedUsers.push(newAddress);
    }

    function removeAddressFromvalidatedUsers(address addressToRemove) public onlyOwner {
        for (uint i = 0; i < validatedUsers.length; i++) {
            if (validatedUsers[i] == addressToRemove) {
                delete validatedUsers[i];
                validatedUsers[i] = validatedUsers[validatedUsers.length - 1];
                validatedUsers.pop();
                break;
            }
        }
    }

    function getvalidatedUsers() public view returns (address[] memory) {
         return validatedUsers;
    }  

    function getValidationCost() public view returns (uint) {
         return totalCostForVerify;
    }

    function getIsValidatedUser(address checkUser) public view returns (bool) {
        bool isFound = false;
        for (uint i = 0; i < validatedUsers.length; i++) {
            if (validatedUsers[i] == checkUser) {
                    isFound = true;
            } 
        }
        return isFound;
    }
     function getCanClaim() public view returns (bool) {
         bool canClaim = false;
         if ( lastClaimTime[msg.sender] + claimWaitTime <= block.timestamp ) { 
             canClaim = true;
         } else {
             canClaim = false;
         }
         return canClaim;
    }  

    function getLastClaimTime(address user) public view returns (uint256) {
        return lastClaimTime[user];
    }

     function getClaimWaitTime() public view returns (uint) {
        return claimWaitTime;
    }

     function getTotalInPool() public view returns (uint) {
        return totalInPool;
    }

    function getBlockTime() public view returns (uint) {
        return block.timestamp;
    }
}