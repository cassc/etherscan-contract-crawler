// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract AdminConsole is Initializable {
    address public i_owner;
    address[] adminMembers;
    address _feeAccount;
    uint _feePercent;

    function initialize() public initializer {
        i_owner = msg.sender;
        _feeAccount = msg.sender;
        _feePercent =  500;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function addMember(address account) external {
        require(
            msg.sender == i_owner,
            "You do not have permission to add members"
        );
        adminMembers.push(account); //add event
    }

    function removeMember(address account) external {
        require(
            msg.sender == i_owner,
            "You do not have permission to add members"
        );
        for (uint i = 0; i < adminMembers.length; i++) {
            if (adminMembers[i] == account) {
                adminMembers[i] = adminMembers[adminMembers.length - 1];
                adminMembers.pop();
            }
        }
    }

    function isAdmin(address account) public view returns (bool) {
        for (uint i = 0; i < adminMembers.length; i++) {
            if (adminMembers[i] == account) {
                return true;
            }
        }
        return false;
    }

    function setFeeAccount(address account) public {
        require(msg.sender == i_owner, "You do not have set this value!");
        _feeAccount = account;
    }

    function getFeeAccount() public view returns (address) {
        return _feeAccount;
    }

    function setFeePercent(uint feePercent) public {
        require(msg.sender == i_owner, "You do not have set this value!");
        _feePercent = feePercent;
    }

    function getFeePercent() public view returns (uint) {
        return _feePercent;
    }
}