//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IStolenPool {
    function virtualDeposit(uint256 _amount) external;
    function attack(address _sender, uint256 _rabbitTier, uint256 _rabbitId) external;
    function updateConfig() external;
    function setStolenPoolOpenTimestamp() external;
    function setStolenPoolAttackIsOpen(bool _isOpen) external;
    function setAttackBurnPercentage(uint16 _attackBurnPercentage) external;
    function setIsApprovedDepositor(address _depositor, bool _isApproved) external;
}