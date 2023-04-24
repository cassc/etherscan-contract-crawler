pragma solidity ^0.8.10;
import "../Note.sol";
import "../CNote.sol";
import "../ComptrollerInterface.sol";


contract AccountantErrors {
    error SenderNotAdmin(address sender); //emitted in admin only methods 
    error SenderNotCNote(address sender); // emitted in CNote only events
    error InvalidAddress(address addr);
    error ErrorMarketEntering(uint errCode);
    error AccountantInitializedAgain();
}


contract AccountantDelegatorStorage {
    address public pendingAdmin;
    address public admin; // admin address (Timelock)
    address public implementation; // implementation address

}

contract AccountantStorageV1 is AccountantDelegatorStorage{
    event AcctInit(address lendingMarketAddress);
	event AcctSupplied(uint amount, uint err);
    event AcctRedeemed(uint amount);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address admin);

    error SweepError(address treasury, uint amount); 

    Note public note; // note address
    CNote public cnote; // lending market address
    ComptrollerInterface public comptroller; // comptroller address
    address public treasury; // treasury address
}

abstract contract AccountantDelegatorInterface {
    event NewImplementation(address oldImplementation, address newImplementation);
    function setImplementation(address implementation_) public virtual;
}

abstract contract AccountantInterface is AccountantStorageV1 {
    function _setPendingAdmin(address newPendingAdmin) external virtual;
    function _acceptAdmin() external virtual;
    function supplyMarket(uint amount) external virtual returns(uint);
    function redeemMarket(uint amount) external virtual returns(uint);
    function sweepInterest() external virtual;
}