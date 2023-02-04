// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Mintable is Ownable {

    address private _minter;

    event MinterChanged(address indexed previousMinter, address indexed newMinter);

    constructor() {
        setMinter(_msgSender());
    }

    modifier onlyMinter() {
        _checkMinter();
        _;
    }

    function minter() public view returns (address) {
        return _minter;
    }

    function setMinter(address newMinter) public virtual onlyOwner {
        require(newMinter != address(0), "Mintable: new minter is the zero address");

        address oldMinter = _minter;
        _minter = newMinter;
        emit MinterChanged(oldMinter, newMinter);
    }

    function _checkMinter() internal view virtual {
        require(minter() == _msgSender(), "Mintable: caller is not the owner");
    }

}