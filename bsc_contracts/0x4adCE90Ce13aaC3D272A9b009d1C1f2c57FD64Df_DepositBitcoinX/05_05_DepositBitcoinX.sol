// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DepositBitcoinX {
    address public owner;
    address payable public wallet;
    address payable public receiver;
    ERC20 public token;
    uint256 public totalDeposit;
    constructor(address payable _wallet, ERC20 _token){
        require(_wallet != address(0));
        owner = msg.sender;
        token = _token;
        wallet = _wallet;
        receiver = _wallet;
    }

    function depositTokens(uint256 amount) external {
        require(token.balanceOf(msg.sender) > 0 , "Insuficient BitcoinX Network Token to Deposit");
        totalDeposit += amount;
        ERC20(token).transferFrom(msg.sender, address(this), amount);
        ERC20(token).transfer(receiver, amount); 
    }

    function getUserTokenBalance(address _address) public view returns(uint256){
        return token.balanceOf(_address);
    }

    function withdrawFund(uint amount) external onlyOwner{
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");
    }
    
    function transferToken(address to, uint256 amount) public onlyOwner {
        uint256 tokenBalance = token.balanceOf(address(this));
        require(amount <= tokenBalance, "balance is low");
        token.transfer(to, amount);
    }     

    function setToken(ERC20 _token) public onlyOwner{
        token = _token;
    }

    function setWallet(address payable _wallet) public onlyOwner {
        wallet = _wallet;
    }

    function setReceiver(address payable _receiver) public onlyOwner {
        receiver = _receiver;
    }

    receive() external payable{
        _forwardFunds();
    } 

    function _forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function transferOwnership(address _address) public onlyOwner {
        require(_address != address(0), "Invalid Address");
        owner = _address;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can call this function");
        _;
    }
}