// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;


///@title JiraCentral - A collaboration between Llamaverse and PG
///@author WhiteOakKong
///@notice This contract coordinates off-chain JIRAX yield.

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IERC20Like {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract JiraCentral is Ownable {
    using Strings for uint256;

    mapping(address => bool) public approvedContracts;
    mapping(address => uint256) public userData;

    ///@notice event that is used to track the current generation rate for an address
    event currentRate(address user, uint256 rate);

    ///@notice event that is used to directly increase balance of an address.
    event increaseBalance(address user, uint256 amount);

    ///@notice restricts function access to only approved addresses
    modifier onlyApproved(address _address) {
        require(approvedContracts[_address] == true, "Contract not approved.");
        _;
    }

    ///@notice increases stored generation rate for the user, and emits an event
    ///@param _address the user to increase the rate for
    ///@param dailyAmount the amount to increase the rate by
    function _increaseGeneration(address _address, uint256 dailyAmount) external onlyApproved(msg.sender) {
        userData[_address] += dailyAmount;
        emit currentRate(_address, userData[_address]);
    }

    ///@notice decreases stored generation rate for the user, and emits an event
    ///@param _address the address of the user
    ///@param dailyAmount the amount to decrease the generation rate by
    function _decreaseGeneration(address _address, uint256 dailyAmount) external onlyApproved(msg.sender) {
        userData[_address] -= dailyAmount;
        emit currentRate(_address, userData[_address]);
    }

    ///@notice allows owner to adjust approved contracts that can utilize this contract
    ///@param _address address of the contract to be approved
    ///@param status boolean value of whether the contract is approved or not
    function setApproved(address _address, bool status) external onlyOwner {
        approvedContracts[_address] = status;
    }
}