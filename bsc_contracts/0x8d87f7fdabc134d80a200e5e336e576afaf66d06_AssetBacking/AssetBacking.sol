/**
 *Submitted for verification at BscScan.com on 2023-02-23
*/

// SPDX-License-Identifier: MIT
//approvare tramite contratto token questo contratto


pragma solidity ^0.8.18;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract AssetBacking {
    address public owner;
    IERC20 public token;
    uint256 public totalSupply;
    uint256 public contractBalance;

    constructor() {
        owner = msg.sender;
        token = IERC20(0xbf433345a79CF6e9270350848F88Db16d46D4f54);
        totalSupply = token.totalSupply();
    }

    function getExchangeRate() public view returns (uint256) {
        require(contractBalance > 0, "Contract balance is zero");
        uint256 rate = contractBalance / (totalSupply / (10**12));
        return rate;
    }

    function transferToOwner() public {
    uint256 balance = token.balanceOf(msg.sender) / (10**12);
    uint256 balances = token.balanceOf(msg.sender);
    require(balance > 0, "Insufficient balance");

    // Calcola il tasso di cambio tra il saldo del contratto e la quantità totale di token.
    uint256 exchangeRate = getExchangeRate();

    // Moltiplica il tasso di cambio per i token dell'utente.
    uint256 transferAmount = exchangeRate * balance;

    // Trasferisce i token all'owner del contratto.
    token.transferFrom(msg.sender, owner, balances);

    // Aggiorna la quantità totale di token disponibili.
    totalSupply = totalSupply - balances;

    // Scala i BNB inviati dal balance del contratto.
    contractBalance = contractBalance - transferAmount;

    // Invia la quantità corrispondente di BNB all'utente.
    payable(msg.sender).transfer(transferAmount);
    }



    function deposit() public payable {
        require(msg.sender == owner, "Only the owner can deposit");
        contractBalance = address(this).balance;
    }

    function getContractBalance() public view returns (uint256) {
        return contractBalance;
    }

    function getContractSupply() public view returns (uint256) {
        return totalSupply;
    }

    function getTokenBalance() public view returns (uint256) {
    return token.balanceOf(msg.sender);
    }

    function setContractSupply(uint256 _newSupply) public {
    require(msg.sender == owner, "Only the owner can withdraw");
    totalSupply = _newSupply * (10**12);
    }

   function withdraw(uint256 amount) public {
    require(msg.sender == owner, "Only the owner can withdraw");
    require(amount <= address(this).balance, "Insufficient balance");
    payable(owner).transfer(amount);
    }
 
}