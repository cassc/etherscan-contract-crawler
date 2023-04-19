pragma solidity ^0.8.10;

import "../EIP20Interface.sol";
import "../IProposal.sol"; 

contract TreasuryDelegatorStorage {
    address public pendingAdmin;
    address public admin;     // admin address (Timelock)
    address public implementation; // implementation address (TreasuryDelegate)
}

contract TreasuryStorageV1 is TreasuryDelegatorStorage {
    EIP20Interface public note; // note interface, for handling transfers and querying balance
    IProposal public unigov; // unigov Interface for handling proposals
    error SendFundError(uint amount);
    error SenderNotAdmin(address sender);
    error FailedInitialization();
    error InvalidAddress();
    error InsufficientFunds(uint balance, uint funds);
    error InvalidDenom(string denom);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address admin);
}

abstract contract TreasuryDelegatorInterface {
    event NewImplementation(address oldImplementation, address newImplementation);
    event Received(address sender, uint amount); 

    function setImplementation(address implementation_) public virtual;
    fallback() external payable virtual;
    receive() external payable virtual;
}

abstract contract TreasuryInterface is TreasuryStorageV1 {
    function _setPendingAdmin(address newPendingAdmin) external virtual;
    function _acceptAdmin() external virtual;

    function queryCantoBalance() external virtual view returns(uint);
    function queryNoteBalance() external virtual view returns(uint);
    function sendFund(address recipient, uint amount, string calldata denom) external virtual;
    function redeem(address cNote, uint cTokens) external virtual;
}