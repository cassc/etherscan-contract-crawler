// SPDX-License-Identifier: MIT
import "./Ownable.sol";


pragma solidity ^0.8.7;

contract NovaEscrow is Ownable{
    struct withdrawalRequest 
    {
        uint256 amount;
        bool requestApproved;
        bool requestRejected;
        bool withdrawalCompleted;
        uint256 withdrawalId;
        uint256 timestamp; 
    }

    mapping(uint256 => withdrawalRequest) public withdrawalRequests;

    uint256 public withdrawalId;

    address public AUDITOR;

    bool private isAuditorSet = false;

    modifier onlyAuditor(address _sender) {
        require(_sender == AUDITOR , "Invalid address");
        _;
    }

    function requestWithdrawal (uint256 _amount) public onlyOwner {
        require(_amount <= address(this).balance, "Withdrawal limit exceeded.");
        require(_amount > 0, "Withdrawal amount must be greater than 0");
        withdrawalRequests[withdrawalId]=withdrawalRequest(_amount,false,false,false,withdrawalId,block.timestamp);
        withdrawalId+=1;
    }

    function updateAuditor (address _newAuditorAddress) public onlyAuditor(msg.sender) {
        AUDITOR=_newAuditorAddress;
    }

    function setInitialAuditorAddress (address _auditorAddress) public onlyOwner {
        require(!isAuditorSet, "Auditor address already set.");
        AUDITOR=_auditorAddress;
        isAuditorSet = true;
    }

    function approveWithdrawal (uint256 _withdrawalId) public onlyAuditor(msg.sender) {
        require(withdrawalRequests[_withdrawalId].withdrawalCompleted == false, "Withdrawal already completed.");
        withdrawalRequests[_withdrawalId].requestApproved=true;
        withdrawalRequests[_withdrawalId].requestRejected=false;
    }

    function rejectWithdrawal (uint256 _withdrawalId) public onlyAuditor(msg.sender) {
        require(withdrawalRequests[_withdrawalId].withdrawalCompleted == false, "Withdrawal already completed.");
        withdrawalRequests[_withdrawalId].requestRejected=true;
        withdrawalRequests[_withdrawalId].requestApproved=false;
    }

    function withdraw(uint256 _withdrawalId,address _recipientAddress) public onlyOwner {
        require(withdrawalRequests[_withdrawalId].requestApproved == true, "Withdrawal not approved.");
        require(withdrawalRequests[_withdrawalId].withdrawalCompleted == false, "Withdrawal already completed.");

        (bool os, ) = payable(_recipientAddress).call{value: withdrawalRequests[_withdrawalId].amount}("");
        require(os);
        
        withdrawalRequests[_withdrawalId].withdrawalCompleted = true;
    }

    /// Fallbacks 
    receive() external payable { }
    fallback() external payable { }
}