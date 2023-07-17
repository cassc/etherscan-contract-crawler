// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MinterAccess
 */
abstract contract MinterAccess is Ownable {
    mapping(address => bool) private _minters;

    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);

    modifier onlyMinters() {
        require(_minters[_msgSender()], "Mintable: Caller is not minter");
        _;
    }

    function isMinter(address account) external view returns (bool) {
        return _minters[account];
    }

    function addMinter(address minter) external onlyOwner {
        require(!_minters[minter], "Mintable: Already minter");
        _minters[minter] = true;
        emit MinterAdded(minter);
    }

    function removeMinter(address minter) external onlyOwner {
        require(_minters[minter], "Mintable: Not minter");
        _minters[minter] = false;
        emit MinterRemoved(minter);
    }
}