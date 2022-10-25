// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PauseOwnable.sol";

abstract contract Mintable is PauseOwnable {
    mapping(address => bool) minters;

    function addMinter(address _minter) external onlyOwner {
        minters[_minter] = true;
    }

    function removeMinter(address _minter) external onlyOwner {
        minters[_minter] = false;
    }

    function isMinter(address _minter) external view returns (bool) {
        return minters[_minter];
    }

    modifier onlyMinter() {
        require(minters[msg.sender], "Mintable: caller is not minter");
        _;
    }
}