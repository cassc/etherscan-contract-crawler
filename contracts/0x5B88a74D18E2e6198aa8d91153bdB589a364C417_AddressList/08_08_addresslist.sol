// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/AccessControl.sol';

contract AddressList is AccessControl {
    bytes32 NFT_ROLE = keccak256('NFT_ROLE');

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(NFT_ROLE, DEFAULT_ADMIN_ROLE);
    }

    mapping(address => uint256) public allowAmount;
    mapping(address => uint256) public usedAmount;
    uint256 public totalAllowAmount;
    uint256 public totalUsedAmount;

    function addAllowAmount(address _address, uint256 _amount) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_amount > 0);
        allowAmount[_address] += _amount;
        totalAllowAmount += _amount;
    }

    function removeAllAllowAmount(address _address) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(allowAmount[_address] >= 1);
        totalAllowAmount -= allowAmount[_address];
        allowAmount[_address] = 0;
    }

    function useAllowAmount(address _address) public onlyRole(NFT_ROLE) {
        usedAmount[_address] ++;
        totalUsedAmount ++;
    }

    function checkRemainAmount(address _address) public view returns(uint256) {
        return allowAmount[_address] - usedAmount[_address];
    }

    function checkallowAmount(address _address) public view returns(uint256) {
        return allowAmount[_address];
    }

    function checkTotalallowAmount() public view returns(uint256) {
        return totalAllowAmount;
    }

    function checkTotalUsedAmount() public view returns(uint256) {
        return totalUsedAmount;
    }
}