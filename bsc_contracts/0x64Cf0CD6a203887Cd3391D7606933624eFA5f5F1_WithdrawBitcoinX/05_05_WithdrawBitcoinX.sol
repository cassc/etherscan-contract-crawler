// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WithdrawBitcoinX {
    address public owner;
    address payable public wallet;
    ERC20 public token;
    
    address[] public admins;
    mapping(address => bool) public whitelistedAdmins;
    mapping(address => uint256) public balances;

    constructor(address payable _wallet, ERC20 _token){
        require(_wallet != address(0));
        owner = msg.sender;
        token = _token;
        wallet = _wallet;
    }

    function doWithdrawToken(uint256 amount) external{
        balances[msg.sender] = amount;
    }

    function withdrawTokens(address user, uint256 amount) external onlyAdmin {
        require(amount <= balances[user], "Invalid Amount");
        require(amount <= token.balanceOf(address(this)), 'Insufficient funds');
        ERC20(token).transfer(user, amount);
        balances[user] = 0;
    }

    function getTokenSentToUser(address _address) public view returns(uint256){
        return  balances[_address];
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

    function setAdmin(address _address) public onlyOwner {
        admins.push(_address);
        whitelistedAdmins[_address] = true;
    }

    function removeAdmin(address _address) public onlyOwner {
        delete whitelistedAdmins[_address];
    }

    function isAdmin(address _address) public view returns(bool){
        return whitelistedAdmins[_address];
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

    modifier onlyAdmin() {
        require(whitelistedAdmins[msg.sender] == true, "Only Admin can call this function");
        _;
    }
}