// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.8.4;

contract SolarrWhitelist {
    address owner; // variable that will contain the address of the contract deployer

    mapping(address => uint) whitelistedAddresses; // variables that have been added to whitelist

    constructor() {
        owner = msg.sender; // setting the owner the contract deployer
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner!");
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner returns (bool) {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        owner = _newOwner;
        return true;
    }

    // add user to whitelist
    function addUser(address _addressToWhitelist, uint _type) public onlyOwner returns (bool success) {
        if ( !(whitelistedAddresses[_addressToWhitelist] == 1 && whitelistedAddresses[_addressToWhitelist] == 2)) {
            whitelistedAddresses[_addressToWhitelist] = _type; // add to whitelist
            success = true;
        }
    }

    // unwhitelisted user from whitelist
    function removeUser(address _addressToUnWhitelisted) public onlyOwner returns (bool success) {
        if (whitelistedAddresses[_addressToUnWhitelisted] == 1 || whitelistedAddresses[_addressToUnWhitelisted] == 2) {
            whitelistedAddresses[_addressToUnWhitelisted] = 0; // unwhitelisted from whitelist
            success = true;
        }
    }

    function isWhitelisted(address _address) public view returns (bool) {
        return (whitelistedAddresses[_address] == 1 || whitelistedAddresses[_address] == 2);
    }

    function isAccountWhitelisted(address _address) external view returns (bool) {
        return isWhitelisted(_address);
    }
}