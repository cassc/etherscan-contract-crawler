// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract ERC721TokenURI {

    string public baseTokenURI;

    function _setBaseTokenURI(string memory uri_) internal virtual {
        baseTokenURI = uri_;
    }

    function _toString(uint256 value_) internal pure virtual 
    returns (string memory _str) {
        assembly {
            let m := add(mload(0x40), 0xa0)
            mstore(0x40, m)
            _str := sub(m, 0x20)
            mstore(_str, 0)

            let end := _str

            for { let temp := value_ } 1 {} {
                _str := sub(_str, 1)
                mstore8(_str, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }

            let length := sub(end, _str)
            _str := sub(_str, 0x20)
            mstore(_str, length)
        }
    }
}