// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import './interfaces/IPYESwapFactory.sol';
import './interfaces/IPYESwapPair.sol';

abstract contract FeeStore {
    uint public adminFee;
    address public adminFeeAddress;
    address public adminFeeSetter;
    address public factoryAddress;
    mapping (address => address) public pairFeeAddress;

    event AdminFeeSet(uint adminFee, address adminFeeAddress);

    function initialize(address _factory, uint256 _adminFee, address _adminFeeAddress, address _adminFeeSetter) internal {
        factoryAddress = _factory;
        adminFee = _adminFee;
        adminFeeAddress = _adminFeeAddress;
        adminFeeSetter = _adminFeeSetter;
    }

    function setAdminFee (address _adminFeeAddress, uint _adminFee) external {
        require(msg.sender == adminFeeSetter);
        require(_adminFee <= 100);
        adminFeeAddress = _adminFeeAddress;
        adminFee = _adminFee;
        emit AdminFeeSet(adminFee, adminFeeAddress);
    }

    function setAdminFeeSetter(address _adminFeeSetter) external {
        require(msg.sender == adminFeeSetter);
        adminFeeSetter = _adminFeeSetter;
    }
}