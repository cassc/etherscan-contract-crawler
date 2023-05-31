// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBaseStrategy {

    // --- Functions ---
    function deposit(uint256 _amount) external returns(uint256);
    function withdraw(address _recipient, uint256 _amount) external returns(uint256);
    function harvest() external;
    function pause() external;
    function unpause() external;
    function balanceOf() external view returns(uint256);
    function balanceOfWant() external view returns(uint256);
    function balanceOfPool() external view returns(uint256);
    function setFeeRecipient(address _newFeeRecipient) external;
    function canDeposit(uint256 _amount) external view returns(uint256 capacity, uint256 chargedCapacity);
    function canWithdraw(uint256 _amount) external view returns(uint256 capacity, uint256 chargedCapacity);
}