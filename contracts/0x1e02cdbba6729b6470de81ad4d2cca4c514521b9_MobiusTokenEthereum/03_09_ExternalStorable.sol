// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

import './Ownable.sol';
import '../lib/Strings.sol';

contract ExternalStorable is Ownable {
    using Strings for string;
    address private _storage;

    event StorageChanged(address indexed previousValue, address indexed newValue);

    modifier onlyStorageSetup() {
        require(_storage != address(0), contractName.concat(': Storage not set'));
        _;
    }

    function setStorage(address value) public onlyOwner {
        require(value != address(0), "storage is a zero address");
        emit StorageChanged(_storage, value);
        _storage = value;
    }

    function getStorage() public view onlyStorageSetup returns (address) {
        return _storage;
    }
}