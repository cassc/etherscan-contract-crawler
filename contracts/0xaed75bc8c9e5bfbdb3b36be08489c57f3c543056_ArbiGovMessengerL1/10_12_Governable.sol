pragma solidity ^0.8.13;

abstract contract Governable {

    address public gov;
    address public pendingGov;

    constructor(address _gov){
        gov = _gov;
    }

    error OnlyGov();
    error OnlyPendingGov();

    modifier onlyGov() {
        if(msg.sender != gov) revert OnlyGov();
        _;
    }

    modifier onlyPendingGov() {
        if(msg.sender != gov) revert OnlyPendingGov();
        _;
    }

    function setPendingGov(address newPendingGov) external onlyGov {
        pendingGov = newPendingGov;
    }

    function claimPendingGov() external onlyPendingGov{
        gov = pendingGov;
        pendingGov = address(0);
    }
}