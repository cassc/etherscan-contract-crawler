// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./GoTekERC20.sol";

contract GoTekERC721 is ERC721, Ownable {

    GoTekERC20 public wallet;

    constructor(string memory name_, string memory symbol_, address _walletAddress)
        ERC721(name_, symbol_) {
        wallet = GoTekERC20(_walletAddress);
    }

    //Owner to Phone
    mapping(address => uint256[]) public phones;

    //Phone to Balance
    mapping(uint256 => uint256) public balances;

    //Phone to Validity Time
    mapping(uint256 => uint256) public validity;

    mapping(uint256 => Transaction[]) public transactions;

    struct PhoneData {
        uint256 mobile;
        uint256 balance;
        uint256 time;
        uint256 current;
    }

    struct Transaction {
        uint256 amount;
        uint256 time;
    }

    function register(address owner, uint256 phone, uint256 balance) public {
        _mint(owner, phone);
        phones[owner].push(phone);
        balances[phone] = balance;
        validity[phone] = block.timestamp + 365 days;
        Transaction memory transaction = Transaction(balance, block.timestamp);
        transactions[phone].push(transaction);
    }

    function debit(address owner, uint256 phone, uint256 balance) public {
        require(balances[phone] > balance, "You do not have enough balance");
        balances[phone] -= balance;
    }

    function credit(address owner, uint256 phone, uint256 balance) public {

        wallet.burn(owner, balance);

        balances[phone] += balance;

        Transaction memory transaction = Transaction(balance, block.timestamp);
        transactions[phone].push(transaction);
    }

    function renew(address owner, uint256 phone, uint256 balance) public {
        if(validity[phone] > block.timestamp) {
            validity[phone] = validity[phone] + 365 days;
        } else {
            validity[phone] = block.timestamp + 365 days;
        }

        Transaction memory transaction = Transaction(balance, block.timestamp);
        transactions[phone].push(transaction);
    }

    function details(address owner) public view returns(PhoneData[] memory) {
        uint256[] memory ownerPhones = phones[owner];

        PhoneData[] memory newBalance = new PhoneData[](ownerPhones.length);

        for (uint256 i = 0; i < ownerPhones.length; i++) {
            uint256 phone = ownerPhones[i];
            PhoneData memory phoneData = PhoneData(phone, balances[phone], validity[phone], block.timestamp);
            newBalance[i] = phoneData;
        }
        return newBalance;
    }

    function getTransaction(uint256 phone) public view returns (Transaction[] memory){
        return transactions[phone];
    }
}