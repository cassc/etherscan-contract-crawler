// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import './SafeOwnableInterface.sol';

abstract contract Mintable is SafeOwnableInterface {

    event MinterChanged(address minter, bool available);
    event MinterLocked();

    mapping(address => bool) public minters;
    bool public minterLocked;

    constructor(address[] memory _minters, bool _minterLocked) {
        for (uint i = 0; i < _minters.length; i ++) {
            require(_minters[i] != address(0), "illegal minter");
            minters[_minters[i]] = true;
            emit MinterChanged(_minters[i], true);
        }
        if (_minterLocked) {
            require(_minters.length > 0, "no minter avaliable");
            emit MinterLocked();
        }
        minterLocked = _minterLocked;
    }

    modifier MinterNotLocked {
        require(!minterLocked, "minter locked");
        _;
    }

    function addMinter(address _minter) external onlyOwner MinterNotLocked {
        require(!minters[_minter], "already minter");
        minters[_minter] = true;
        emit MinterChanged(_minter, true);
    }

    function delMinter(address _minter) external onlyOwner MinterNotLocked {
        require(minters[_minter], "not a minter");
        delete minters[_minter];
        emit MinterChanged(_minter, false);
    }

    function minterLock() external onlyOwner MinterNotLocked {
        minterLocked = true;
        emit MinterLocked();
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "only minter can do this");
        _;
    }

    modifier onlyMinterSignature(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) {
        address verifier = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)), _v, _r, _s);
        require(minters[verifier], "minter verify failed");
        _;
    }

    modifier onlyMinterOrMinterSignature(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) {
        if (!minters[msg.sender]) {
            address verifier = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)), _v, _r, _s);
            require(minters[verifier], "minter verify failed");
        }
        _;
    }

}