// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MigrateBitcoinx {
    address public owner;
    address payable public wallet;

    mapping(address => uint256) public userBalances;
    ERC20 public token;
    ERC20 public tokenTo;

    constructor(address payable _wallet, ERC20 _token, ERC20 _tokenTo){
        require(_wallet != address(0));
        wallet = _wallet;
        token = _token;
        tokenTo = _tokenTo;       
        owner = msg.sender;
    }

    function migrateTokens(uint256 amount) external {
        require(token.balanceOf(msg.sender) > 0 , "Insuficient Token");
        uint256 tokenBalance = tokenTo.balanceOf(address(this));
        require(amount <= tokenBalance, "balance is low in Smart Contract");
        userBalances[msg.sender] += amount;
        ERC20(token).transferFrom(msg.sender, address(this), amount);
        uint256 amountToSent = amount * 1000000000;
        ERC20(tokenTo).transfer(msg.sender, amountToSent);  
    }

    function getTokenBalanceByAddress(address _address) public view returns(uint256){
        return token.balanceOf(_address);
    }

    function getTokenInSmartContract() public view returns(uint256){
        return tokenTo.balanceOf(address(this));
    }

    function withdrawFund(uint amount) external onlyOwner{
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed.");
    }
    
    function transferToken(address to, uint256 amount) public onlyOwner {
        uint256 tokenBalance = tokenTo.balanceOf(address(this));
        require(amount <= tokenBalance, "balance is low");
        tokenTo.transfer(to, amount);
    }     

    function setToken(ERC20 _token) public onlyOwner{
        token = _token;
    }

    function setTokenTo(ERC20 _token) public onlyOwner{
        tokenTo = _token;
    }

    function setWallet(address payable _wallet) public onlyOwner {
        wallet = _wallet;
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