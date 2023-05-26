// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Signable is Ownable {
    address private _signer;

    constructor() {
        _signer = _msgSender();
    }

    function signer() public view virtual returns (address) {
        return _signer;
    }

    function transferSigner(address newSigner) public virtual onlyOwner {
        require(newSigner != address(0), "Signable: new signer is the zero address");
        _signer = newSigner;
    }
}