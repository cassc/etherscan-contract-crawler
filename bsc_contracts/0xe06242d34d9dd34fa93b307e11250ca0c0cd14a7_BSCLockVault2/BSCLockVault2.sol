/**
 *Submitted for verification at BscScan.com on 2023-02-19
*/

pragma solidity ^0.8.0;

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract BSCLockVault2 {
    uint public tokensLocked;
    uint public unlockRate;
    uint public lastUnlockTime;

    constructor(uint _tokensLocked, uint _unlockRate) {
        tokensLocked = _tokensLocked;
        unlockRate = _unlockRate;
        lastUnlockTime = block.timestamp;
    }

    function getPendingUnlocked() public view returns (uint) {
        uint timeElapsed = block.timestamp - lastUnlockTime;
        uint tokensUnlocked = timeElapsed * unlockRate;
        if (tokensUnlocked > tokensLocked) {
            tokensUnlocked = tokensLocked;
        }
        return tokensUnlocked;
    }

    function claim() public {
        uint tokensUnlocked = getPendingUnlocked();
        require(tokensUnlocked > 0, "No tokens available for unlock.");
        tokensLocked -= tokensUnlocked;
        lastUnlockTime = block.timestamp;
        // Transfer tokens to the caller
    }
}

contract BSCLockVault2Proxy is Ownable {
    address public implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    function setImplementation(address _implementation) public onlyOwner {
        implementation = _implementation;
    }

    fallback() payable external {
        address _impl = implementation;
        require(_impl != address(0), "Implementation contract not set");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}