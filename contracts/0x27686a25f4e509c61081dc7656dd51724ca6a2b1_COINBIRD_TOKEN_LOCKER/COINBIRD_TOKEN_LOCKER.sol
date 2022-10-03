/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

// SPDX-License-Identifier: NONE
// This code is copyright protected.
// All rights reserved © coinbird 2022
// The unauthorized reproduction, modification, expansion upon or redeployment of this work is illegal.
// Improvement suggestions are more than welcome. If you have any, please let the coinbird know and they will be examined.

pragma solidity 0.8.17;

// https://coinbird.io - BIRD!
// https://twitter.com/coinbirdtoken
// https://github.com/coinbirdtoken
// https://t.me/coinbirdtoken

abstract contract ERC20_CONTRACT {
    function name() external virtual view returns (string memory);

    function symbol() external virtual view returns (string memory);
    
    function decimals() external virtual view returns (uint8);
    
    function totalSupply() external view virtual returns (uint256);

    function balanceOf(address account) external virtual view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (address);
}


abstract contract COINBIRD_CONNECTOR {
    function balanceOf(address account) external virtual view returns (uint256);
}


contract COINBIRD_TOKEN_LOCKER {
    COINBIRD_CONNECTOR BIRD_FINDER;

    uint private _coinbirdThreshold;

    struct COINBIRD_LOCKS {
        address contractAccessed;
        string contractName;
        string contractSymbol;
        uint contractDecimals;
        uint amountLocked;
        uint lockDuration;
    }

    // _ProtectedFromBIRD[] is a mapping used in retrieving lock data

    mapping(address => COINBIRD_LOCKS[]) private _ProtectedFromBIRD;

    // safetyBIRD[] is a mapping designed to prevent creating multiple locks on an individual contract with the same wallet

    mapping(address => mapping(address => bool)) private safetyBIRD;

    constructor() {
        BIRD_FINDER = COINBIRD_CONNECTOR(0x8792005de5D05bAD050C68D64e526Ce2062DFEFd);
    }

    // coinbirdBouncer() returns the amount of BIRD a wallet needs to hold in order to create a new lock or modify an existing one

    function coinbirdBouncer() public view returns (uint) {
        return _coinbirdThreshold;
    }

    // ownedBIRD() returns the amount of BIRD tokens the "user" address currently holds

    function ownedBIRD(address user) public view returns (uint) {
        return BIRD_FINDER.balanceOf(user);
    }

    // activeLocks() returns the number of locks that were created from the "user" address and are currently active

    function activeLocks(address user) public view returns (uint) {
        return _ProtectedFromBIRD[user].length;
    }

    // totalSupplyOfAccessedContract() returns the totalSupply of the "scanned" ERC20 contract

    function totalSupplyOfAccessedContract(ERC20_CONTRACT scanned) public view returns (uint) {
        return scanned.totalSupply();
    }

    // decimalsOfAccessedContract() returns the decimals of the "scanned" ERC20 contract

    function decimalsOfAccessedContract(ERC20_CONTRACT scanned) public view returns (uint) {
        return scanned.decimals();
    }

    // nameOfAccessedContract() returns the name of the "scanned" ERC20 contract

    function nameOfAccessedContract(ERC20_CONTRACT scanned) public view returns (string memory) {
        return scanned.name();
    }

    // symbolOfAccessedContract() returns the symbol of the "scanned" ERC20 contract

    function symbolOfAccessedContract(ERC20_CONTRACT scanned) public view returns (string memory) {
        return scanned.symbol();
    }

    // lockableTokensInAccessedContract() returns the amount of tokens the "user" address hold in the scanned ERC20 contract

    function lockableTokensInAccessedContract(ERC20_CONTRACT scanned, address user) public view returns (uint) {
        return scanned.balanceOf(user);
    }

    // lockBIRD() return the values stored in the _ProtectedFromBIRD mapping, position [locker][value]

    function lockBIRD(address locker, uint value) public view returns (address, string memory, string memory, uint, uint, uint) {
        require(value < _ProtectedFromBIRD[locker].length, "Invalid value entered.");
        return (
            _ProtectedFromBIRD[locker][value].contractAccessed,
            _ProtectedFromBIRD[locker][value].contractName,
            _ProtectedFromBIRD[locker][value].contractSymbol,
            _ProtectedFromBIRD[locker][value].contractDecimals,
            _ProtectedFromBIRD[locker][value].amountLocked,
            _ProtectedFromBIRD[locker][value].lockDuration);
    }

    // adjustLockerEntranceFee() allows the coinbird to modify the coinbirdBouncer() entry value. Doesn't affect the claimUnlockedTokens() function.

    function adjustLockerEntranceFee(uint BIRDamount) public {
        require(msg.sender == 0xf2Dd50445d4C15424b24F2D9c55407194dC47E5a, "Thy attempts to tamper with holy values beyond your grasp have failed.");
        require(BIRDamount >= 100000000000000000 && BIRDamount <= 4000000000000000000000, "Greedy coinbird, bad coinbird.");
        _coinbirdThreshold = BIRDamount;
    }

    // createNewLock() is a function used in order to create a new lock in the ERC20Contract specified in the input

    function createNewLock(address ERC20Contract, uint amount, uint time) public {
        require(ownedBIRD(msg.sender) >= coinbirdBouncer(), "You don't own enough BIRD. Buy more at: 0x8792005de5D05bAD050C68D64e526Ce2062DFEFd");
        require(safetyBIRD[msg.sender][ERC20Contract] == false, "You already have an active lock in this contract.");
        ERC20_CONTRACT contractBIRD = ERC20_CONTRACT(ERC20Contract);
        require(amount > 0 && time > 0, "Trivial.");
        require(contractBIRD.balanceOf(msg.sender) >= amount, "Amount entered exceeds amount owned.");
        safetyBIRD[msg.sender][ERC20Contract] = true;
        contractBIRD.transferFrom(msg.sender, address(this), amount);
        COINBIRD_LOCKS memory newLock = COINBIRD_LOCKS(ERC20Contract, contractBIRD.name(), contractBIRD.symbol(), contractBIRD.decimals(), amount, block.timestamp+time*86400);
        _ProtectedFromBIRD[msg.sender].push(newLock);
    }

    // increaseLockDuration() can be called whenever the msg.sender wishes to increase the duration of an active lock they previously created
    
    function increaseLockDuration(uint hatchling, uint time) public {
        require(ownedBIRD(msg.sender) >= coinbirdBouncer(), "You don't own enough BIRD. Buy more at: 0x8792005de5D05bAD050C68D64e526Ce2062DFEFd");
        require(safetyBIRD[msg.sender][_ProtectedFromBIRD[msg.sender][hatchling].contractAccessed] == true, "You do not have an active lock in this contract.");
        require(time > 0, "Trivial.");
        _ProtectedFromBIRD[msg.sender][hatchling].lockDuration += time*86400;
    }

    // increaseLockedAmount() can be called whenever the msg.sender wishes to increase the amount of tokens within an active lock they previously created

    function increaseLockedAmount(uint hatchling, uint amount) public {
        require(ownedBIRD(msg.sender) >= coinbirdBouncer(), "You don't own enough BIRD. Buy more at: 0x8792005de5D05bAD050C68D64e526Ce2062DFEFd");
        address protectionBIRD = _ProtectedFromBIRD[msg.sender][hatchling].contractAccessed;
        require(safetyBIRD[msg.sender][protectionBIRD] == true, "You do not have an active lock in this contract.");
        require(amount > 0, "Trivial.");
        ERC20_CONTRACT contractBIRD = ERC20_CONTRACT(protectionBIRD);
        require(contractBIRD.balanceOf(msg.sender) >= amount, "Amount entered exceeds amount owned.");
        contractBIRD.transferFrom(msg.sender, address(this), amount);
        _ProtectedFromBIRD[msg.sender][hatchling].amountLocked += amount;
    }

    // claimUnlockedTokens() can be called whenever the msg.sender wishes to retrieve tokens they had stored in a lock which has now expired

    function claimUnlockedTokens(uint hatchling) public {
        require(_ProtectedFromBIRD[msg.sender][hatchling].lockDuration < block.timestamp, "The lock is still active."); 
        address accessBIRD = _ProtectedFromBIRD[msg.sender][hatchling].contractAccessed;
        ERC20_CONTRACT contractBIRD = ERC20_CONTRACT(accessBIRD);
        require(safetyBIRD[msg.sender][accessBIRD] == true, "Reentrancy protection.");
        safetyBIRD[msg.sender][accessBIRD] = false;
        contractBIRD.transferFrom(address(this), msg.sender, _ProtectedFromBIRD[msg.sender][hatchling].amountLocked);
        uint dummyBIRD = _ProtectedFromBIRD[msg.sender].length - 1;
        COINBIRD_LOCKS memory killerBIRD = _ProtectedFromBIRD[msg.sender][dummyBIRD];
        _ProtectedFromBIRD[msg.sender][hatchling] = killerBIRD;
        _ProtectedFromBIRD[msg.sender].pop();
    }
}