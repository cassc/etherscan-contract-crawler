/**
 *Submitted for verification at Etherscan.io on 2023-08-10
*/

pragma solidity ^0.8.18;

contract raffle {
    address payable public Owner;
    uint256 public Tax;
    bool public IsGameOn = false;
    uint256 public MinimumAmount;

    event NewParticipants(address Sender, uint256 Amount);
    event WinnerDeclared(address indexed Winner, uint256 Amount);
    event GameOn();
    event GameOff();

    constructor(uint _Tax, uint _MinimumAmount) {
        Owner = payable(msg.sender);
        Tax = _Tax;
        MinimumAmount = _MinimumAmount;
    }

    modifier IsOpen() {
        require(IsGameOn, "Deposits are currently closed");
        _;
    }

    modifier IsOwner() {
        require(msg.sender == Owner, "Only the owner can call this function");
        _;
    }

    receive() external payable IsOpen {
        require(msg.value >= MinimumAmount, "Minimum deposit amount not met");
        emit NewParticipants(msg.sender, msg.value);
    }

    function StartGame() external IsOwner {
        require(!IsGameOn, "Game is already in progress");
        IsGameOn = true;
        emit GameOn();
    }

    function EndGame() external IsOwner {
        require(IsGameOn, "Game has not started yet");
        IsGameOn = false;
        emit GameOff();
    }

    function ChangeMinimumAmount(uint256 Amount) external IsOwner {
        MinimumAmount = Amount;
    }

    function ChangeTaxPercentage(uint256 _Tax) external IsOwner {
        require(_Tax <= 100, "Invalid Tax amount");
        Tax = _Tax;
    }

    function DistributePrize(address payable winner) external IsOwner {
        uint256 ContractBalance = address(this).balance;
        require(address(this).balance > 0, "No Balance Left");

        uint256 TaxAmount = (ContractBalance * Tax) / 100;
        uint256 amount = ContractBalance - TaxAmount;

        (bool sent, ) = winner.call{value: amount}("");
        require(sent, "Failed to send Ether");

        (bool sent2, ) = Owner.call{value: TaxAmount}("");
        require(sent2, "Failed to send Ether");


        emit WinnerDeclared(winner, amount);
    }
}