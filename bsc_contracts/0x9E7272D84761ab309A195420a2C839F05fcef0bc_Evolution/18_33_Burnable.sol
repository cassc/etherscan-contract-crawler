// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import './SafeOwnableInterface.sol';

abstract contract Burnable is SafeOwnableInterface {

    event BurnerChanged(address burner, bool available);
    event BurnerLocked();

    mapping(address => bool) public burners;
    bool public burnerLocked;

    constructor(address[] memory _burners, bool _burnerLocked) {
        for (uint i = 0; i < _burners.length; i ++) {
            require(_burners[i] != address(0), "illegal burner");
            burners[_burners[i]] = true;
            emit BurnerChanged(_burners[i], true);
        }
        if (_burnerLocked) {
            require(_burners.length > 0, "no burner avaliable");
            emit BurnerLocked();
        }
        burnerLocked = _burnerLocked;
    }

    modifier BurnerNotLocked {
        require(!burnerLocked, "minter locked");
        _;
    }

    function addBurner(address _burner) external onlyOwner BurnerNotLocked {
        require(!burners[_burner], "already burner");
        burners[_burner] = true;
        emit BurnerChanged(_burner, true);
    }

    function delBurner(address _burner) external onlyOwner BurnerNotLocked {
        require(burners[_burner], "not a burner");
        delete burners[_burner];
        emit BurnerChanged(_burner, false);
    }

    function burnerLock() external onlyOwner BurnerNotLocked {
        burnerLocked = true;
        emit BurnerLocked();
    }

    modifier onlyBurner() {
        require(burners[msg.sender], "only burner can do this");
        _;
    }

    modifier onlyBurnerSignature(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) {
        address verifier = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)), _v, _r, _s);
        require(burners[verifier], "burner verify failed");
        _;
    }

    modifier onlyBurnerOrBurnerSignature(bytes32 _hash, uint8 _v, bytes32 _r, bytes32 _s) {
        if (!burners[msg.sender]) {
            address verifier = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)), _v, _r, _s);
            require(burners[verifier], "burner verify failed");
        }
        _;
    }

}