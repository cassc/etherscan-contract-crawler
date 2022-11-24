//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title FactoryNFTs
 * @author gotbit
 */

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import 'erc721a/contracts/ERC721A.sol';

contract FactoryERC721a is ERC721A {
    string public baseURI;

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI_,
        uint256 totalSupply_,
        address holder
    ) ERC721A(name, symbol) {
        baseURI = baseURI_;
        _mint(holder, totalSupply_);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }
}

contract FactoryERC1155 is ERC1155 {
    string public name;
    string public symbol;
    string public baseURI;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        uint256[] memory amounts,
        address holder
    ) ERC1155('') {
        name = name_;
        symbol = symbol_;
        baseURI = baseURI_;

        uint256 length = amounts.length;
        for (uint256 id; id < length; ++id) _mint(holder, id, amounts[id], '');
    }

    function uri(uint256 id) public view virtual override returns (string memory) {
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(id)))
                : '';
    }

    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits. Total: 5 * 0x20 = 0xa0.
            let m := add(mload(0x40), 0xa0)
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            // Assign the `str` to the end.
            str := sub(m, 0x20)
            // Zeroize the slot after the string.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
        }
    }
}