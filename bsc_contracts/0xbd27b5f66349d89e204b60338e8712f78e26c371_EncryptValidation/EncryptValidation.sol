/**
 *Submitted for verification at BscScan.com on 2023-05-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
    uint public totalCostForVerify = 1; //300 + 9 decimal
    uint public claimAmountPublic = 2000000000;//2 + 9 decimal
    //uint public claimWaitTime = 86400 * 7; // 24 hours times 7 days
    uint public claimWaitTime = 1; // 24 hours times 7 days

    address public tokenAddress;
    mapping (address => uint) public lastClaimTime;
    address[] public validatedUsers;
    address[] public validatedTeam;
    address public owner;

    event UserVerified(address indexed user);

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

        validatedUsers.push(msg.sender);

        uint amount = totalCostForVerify;
        totalAmount += amount;

        uint halfAmount = amount / 2;
        uint ownerAmount = amount / 10;
        totalInPool += amount - halfAmount - ownerAmount;
        totalForTeam += ownerAmount;
        totalForBurns += halfAmount;
    }

    // function VerifyUser() public {
    //     // Get the balance of tokens in the sender's account
    //     uint256 senderBalance = IERC20(tokenAddress).balanceOf(msg.sender);
        
    //     // Verify that the sender has enough tokens to send
    //     require(senderBalance >= totalCostForVerify, "Not enough tokens to verify");
        
    //     bool approved = IERC20(tokenAddress).approve(address(this), totalCostForVerify);
    //     require(approved, "Token approval failed");
    

    //     // Transfer the tokens from the sender to your contract
    //     bool transferred = IERC20(tokenAddress).transferFrom(msg.sender, address(this), totalCostForVerify);
    //     require(transferred, "Token transfer failed");
        
    //     validatedUsers.push(msg.sender);

    //     uint amount = totalCostForVerify;
    //     totalAmount += amount;

    //     uint halfAmount = amount / 2;
    //     uint ownerAmount = amount / 10;
    //     totalInPool += amount - halfAmount - ownerAmount;
    //     totalForTeam += ownerAmount;
    //     totalForBurns += halfAmount;
        
    // }

    function publicClaim() public {
        require(validatedUsers.length > 0, "No users have validated.");
        require(lastClaimTime[msg.sender] + claimWaitTime <= block.timestamp, "You must wait before claiming again.");
        require(totalInPool > claimAmountPublic, "Not enough tokens in pool to claim.");
        uint i = 0;
        while (i < validatedUsers.length && claimAmountPublic > 0) {
            if (validatedUsers[i] == msg.sender) {
                lastClaimTime[msg.sender] = block.timestamp;
                payable(msg.sender).transfer(claimAmountPublic);
                IERC20(tokenAddress).transfer(msg.sender, claimAmountPublic);
            }
            i++;
        }
        require(claimAmountPublic == 0, "Claim amount was not available for this address.");
    }

    function ownerClaim() public onlyOwner {
        require(validatedTeam.length > 0, "No funds to claim.");
        
        for (uint i = 0; i < validatedTeam.length; i++) {
            payable(validatedTeam[i]).transfer(totalForTeam);
            IERC20(tokenAddress).transfer(validatedTeam[i], totalForTeam);
        }
    }

    function ownerBurn() public onlyOwner {
        IERC20(tokenAddress).transfer(address(0x000000000000000000000000000000000000dEaD), totalForBurns);
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

    function withdrawTokens(address _to, uint256 _amount) public onlyOwner {
        IERC20(tokenAddress).transfer(_to, _amount);
    }

    function getvalidatedUsers() public view returns (address[] memory) {
    return validatedUsers;
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

    function getLastClaimTime(address user) public view returns (uint256) {
        return lastClaimTime[user];
    }

     function getLastClaimTime() public view returns (uint) {
        return claimWaitTime;
    }

}