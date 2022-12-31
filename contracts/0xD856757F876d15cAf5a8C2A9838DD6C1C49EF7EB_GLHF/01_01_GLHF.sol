// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract GLHF {
    address public lastSolvedBy;
    bytes32 public globalStorage;
    mapping(bytes2 => bool) public uniqueId;
    mapping(address => uint32) public userStorage;
    bool private _doorOpen;
    address private _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not Owner");
        _;
    }

    modifier doorOpen() {
        require(_doorOpen, "Door Closed");
        _;
    }

    constructor() {
        _owner = address(this);
        globalStorage = keccak256(abi.encodePacked(blockhash(block.number)));
    }

    function incAcc(uint32 acc_, uint8 inc_)
        public
        view
        onlyOwner
        returns (uint32)
    {
        assembly {
            let result := add(acc_, inc_)
            mstore(0x00, result)
            return(0x00, 32)
        }
    }

    function exit() public doorOpen {
        assembly {
            sstore(lastSolvedBy.slot, caller())
            sstore(_doorOpen.slot, 0)
        }
    }

    function enter(bytes calldata data_) public {
        assembly {
            function loadUserStorage() -> acc, usHash {
                mstore(0, caller())
                mstore(32, userStorage.slot)
                usHash := keccak256(0, 64)
                acc := sload(usHash)
            }
            function storeGlobalStorage() -> blkHshs {
                mstore(0, blockhash(number()))
                mstore(32, sload(globalStorage.slot))
                blkHshs := keccak256(0, 64)
                sstore(globalStorage.slot, blkHshs)
            }
            function checkUnique(id) {
                mstore(0, id)
                mstore(32, uniqueId.slot)
                let uIdHsh := keccak256(0, 64)
                let unique := sload(uIdHsh)
                if gt(unique, 0) {
                    revert(0, 0)
                }
                sstore(uIdHsh, 1)
            }
            let id := shl(0xF0, shr(0xC8, calldataload(data_.offset)))
            checkUnique(id)
            let counter := shr(0xF8, shl(0x20, calldataload(data_.offset)))
            for {
                let i := 0
            } lt(i, counter) {
                i := add(i, 1)
            } {
                let acc, usHash := loadUserStorage()
                let ptr := mload(0x40)
                mstore(ptr, calldataload(data_.offset))
                mstore(add(ptr, 0x04), acc)
                let inc := shr(0xF8, shl(0xF8, calldataload(data_.offset)))
                mstore(add(ptr, 0x24), inc)
                let success := call(gas(), address(), 0, ptr, 0x44, 0, 0)
                if iszero(success) {
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
                returndatacopy(ptr, 0, returndatasize())
                sstore(usHash, mload(ptr))
            }
            let blkHsh := storeGlobalStorage()
            let blk := shr(0xE0, shl(0xE0, blkHsh))
            let acc, usHash := loadUserStorage()
            if lt(acc, 0x0100) {
                revert(0, 0)
            }
            let exitFn := shr(0xE0, shl(0xD8, calldataload(data_.offset)))
            exitFn := xor(exitFn, blk)
            exitFn := xor(exitFn, shl(0x08, acc))
            exitFn := shl(0xE0, exitFn)
            let ptr := mload(0x40)
            mstore(ptr, exitFn)
            mstore(add(ptr, 0x04), 0)
            let exitAddress := shr(0x60, shl(0x38, calldataload(data_.offset)))
            exitAddress := xor(exitAddress, blkHsh)
            if eq(exitAddress, address()) {
                revert(0,0)
            }
            sstore(_doorOpen.slot, 1)
            let success := call(gas(), exitAddress, 0, ptr, 0x20, 0, 0)
            if iszero(success) {
                returndatacopy(0x00, 0x00, returndatasize())
                revert(0x00, returndatasize())
            }
            let ret := mload(ptr)
            if iszero(not(eq(ret, acc))) {
                revert(0,0)
            }
        }
    }
}