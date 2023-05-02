// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract XimbiaLock {
    address public ximbiaWallet;
    address public bioticWallet;

    address public ximbiaToken;
    address public bioticToken;

    uint public ximbiaLockDuration = 30 days;
    uint public ximbiaPercentage = 10;
    uint public ximbiaAmount = 150_000 ether;
    uint[3] public bioticAmount = [24_000_000 ether, 10_000_000 ether, 10_000_000 ether];
    uint[3] public bioticLockDuration = [365 days, 730 days, 1095 days];

    struct Deposit {
        uint amount;
        uint totalInvested;
        uint amountPerCycle;
        uint unlockTime;
        uint lockDuration;
        address token;
    }

    struct DepositShow {
        uint amount;
        uint totalInvested;
        uint amountPerCycle;
        uint unlockTime;
        uint lockDuration;
        uint timeLeft;
        address token;
    }


    struct User {
        Deposit[] deposits;
        bool exists;
    }

    mapping(address => User) public users;

    constructor(address _ximbiaWallet, address _bioticWallet, address _ximbiaToken, address _bioticToken) {
        ximbiaWallet = _ximbiaWallet;
        bioticWallet = _bioticWallet;
        ximbiaToken = _ximbiaToken;
        bioticToken = _bioticToken;
    }

    function deposit() external {
        require(msg.sender == ximbiaWallet || msg.sender == bioticWallet, "Only Ximbia or Biotic wallets can deposit");
        require(users[msg.sender].exists == false, "User already exists");
        address token = msg.sender == ximbiaWallet ? ximbiaToken : bioticToken;
        uint toTransfer = 0;
        if(token == ximbiaToken) {
            uint amount = ximbiaAmount;
            uint amountPerCycle = (amount * ximbiaPercentage) / 100;
            users[msg.sender].deposits.push(Deposit(amount, amount, amountPerCycle, block.timestamp + ximbiaLockDuration, ximbiaLockDuration, token));
            toTransfer = amount;
        } else {
            for(uint i = 0; i < bioticAmount.length; i++) {
                uint amount = bioticAmount[i];
                users[msg.sender].deposits.push(Deposit(amount, amount, amount, block.timestamp + bioticLockDuration[i], bioticLockDuration[i], token));
                toTransfer += amount;
            }
        }

        users[msg.sender].exists = true;
        IERC20(token).transferFrom(msg.sender, address(this), toTransfer);
        
    }

    function withdraw() external {
        require(users[msg.sender].exists == true, "User does not exist");
        uint totalAmount = 0;
        for(uint i = 0; i < users[msg.sender].deposits.length; i++) {
            if(users[msg.sender].deposits[i].amount > 0 && users[msg.sender].deposits[i].unlockTime <= block.timestamp) {
                uint amountCycle = users[msg.sender].deposits[i].amountPerCycle;
                if(users[msg.sender].deposits[i].amount <= amountCycle) {
                    amountCycle = users[msg.sender].deposits[i].amount;
                }
                users[msg.sender].deposits[i].amount -= amountCycle;
                users[msg.sender].deposits[i].unlockTime += users[msg.sender].deposits[i].lockDuration;
                totalAmount += amountCycle;
            }
        }
        require(totalAmount > 0, "Nothing to withdraw");
        IERC20(users[msg.sender].deposits[0].token).transfer(msg.sender, totalAmount);
    }

    function getDeposits(address user) external view returns(Deposit[] memory) {
        return users[user].deposits;
    }


    function getDepositsShow(address user) external view returns(DepositShow[] memory) {
        DepositShow[] memory depositsShow = new DepositShow[](users[user].deposits.length);
        for(uint i = 0; i < users[user].deposits.length; i++) {
           uint timeLeft = users[user].deposits[i].unlockTime > block.timestamp ? users[user].deposits[i].unlockTime - block.timestamp : 0;
            depositsShow[i] = DepositShow(users[user].deposits[i].amount, users[user].deposits[i].totalInvested, users[user].deposits[i].amountPerCycle, users[user].deposits[i].unlockTime, users[user].deposits[i].lockDuration, timeLeft, users[user].deposits[i].token);
        }
        return depositsShow;
    }

    function getDepositsCount(address user) external view returns(uint) {
        return users[user].deposits.length;
    }

    function canWihdraw(address _user) external view returns(bool) {
        if(users[_user].exists == false) {
            return false;
        }
        for(uint i = 0; i < users[_user].deposits.length; i++) {
            if(users[_user].deposits[i].unlockTime <= block.timestamp && users[_user].deposits[i].amount > 0) {
                return true;
            }
        }
        return false;
    }
    
}