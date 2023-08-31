// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract SigUtils is Ownable {
    address private _banker;

    function banker() public view returns (address) {
        return _banker;
    }

    // constructor(address banker_) {
    //     _banker = banker_;
    // }

    function setBanker(address banker_) public onlyOwner {
        _banker = banker_;
    }

    function splitSignature(bytes memory signature_) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(signature_.length == 65, "Invalid signature length");

        assembly {
            r := mload(add(signature_, 0x20))
            s := mload(add(signature_, 0x40))
            v := byte(0, mload(add(signature_, 0x60)))

            if lt(v, 27) {
                v := add(v, 27)
            }
        }

        return (r, s, v);
    }

    function recoverSigner(bytes32 hash_, bytes calldata signature_) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature_);
        return ecrecover(hash_, v, r, s);
    }

    function verifySignature(bytes32 hash_, bytes calldata signature_) public view returns (bool) {
        return recoverSigner(hash_, signature_) == _banker;
    }
}