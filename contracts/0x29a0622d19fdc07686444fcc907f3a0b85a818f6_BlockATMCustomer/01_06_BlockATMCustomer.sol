// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <=0.8.17;

import "./BlockCommon.sol";

contract BlockATMCustomer is BlockCommon {

    address private immutable tokenAddress;

    mapping(address => bool) private  withdrawMap;

    mapping(address => bool) private ownerMap;

    address[] private withdrawList;

    address[] private ownerList;

    bool private activeFlag;

    constructor(address newTokenAddress,address[] memory newWithdrawList,address[] memory newOwnerList) checkTokenAddress(newTokenAddress) {
        tokenAddress = newTokenAddress;
        require(newWithdrawList.length > 0, "withdraw address is empty");
        for (uint i = 0; i < newWithdrawList.length; i++) {
            require(newWithdrawList[i] != address(0), "withdraw token is the zero address");
            withdrawMap[newWithdrawList[i]] = true;
        }
        withdrawList =  newWithdrawList;
        require(newOwnerList.length > 0, "owner address is empty");
        for (uint i = 0; i < newOwnerList.length; i++) {
            require(newOwnerList[i] != address(0), "owner is the zero address");
            ownerMap[newOwnerList[i]] = true;
        }
        ownerList = newOwnerList;
        activeFlag = true;
    }

    event TransferToken(address indexed from, address indexed to, address indexed token, uint256 amount,string orderId);

    event WithdrawToken(address indexed from, address indexed to, address indexed token, uint256 amount);

    event SetActiveFlag(bool indexed activeFlag);


    modifier onlyOwner() {
        require(ownerMap[msg.sender], "Not the owner");
        _; 
    }

    function transferToken(uint256 amount,string memory orderId) public returns (bool) {
        require(activeFlag, "The contract has already burned");
        uint256 finalAmount = super.transferCommon(tokenAddress,address(this),amount);
        emit TransferToken(msg.sender, address(this), tokenAddress, finalAmount,orderId); 
        return true;
    }

    function withdrawToken(uint256 amount,address withdrawAddress) public onlyOwner returns (bool) {
        // check withdrawAddress
        require(withdrawMap[withdrawAddress], "withdraw address not allowed");
        super.withdrawCommon(tokenAddress,withdrawAddress,amount);
        emit WithdrawToken(msg.sender, withdrawAddress, tokenAddress, amount);
        return true;
    }

    function getTokenAddress() public view returns (address) {
        return tokenAddress;
    }

    function getActiveFlag() public view returns (bool) {
        return activeFlag;
    }

    function getWithdrawAddressList() public view returns(address[] memory){
        return withdrawList;
    }

    function getWithdrawAddressFlag(address withdrawAddress) public view returns(bool){
        return withdrawMap[withdrawAddress];
    }

    function getOnwerAddressFlag(address ownerAddress) public view returns(bool){
        return ownerMap[ownerAddress];
    }

    function getOwnerAddressList() public view returns(address[] memory){
        return ownerList;
    }
    
    function setActiveFlag() public onlyOwner {
        require(activeFlag, "The contract has already burned");
        activeFlag = false;
        emit SetActiveFlag(activeFlag);
    }

}