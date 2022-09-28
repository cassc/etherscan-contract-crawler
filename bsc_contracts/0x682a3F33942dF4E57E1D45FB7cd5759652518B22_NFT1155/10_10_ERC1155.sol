//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NFT1155
 * @author gotbit
 */

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract NFT1155 is ERC1155(''), Ownable {
    string public baseURI;

    constructor() {
        _mint(msg.sender, 0, 20, '');
        _mint(msg.sender, 1, 20, '');
        _mint(msg.sender, 2, 20, '');
        _mint(msg.sender, 3, 20, '');
    }

    function mint(
        address who,
        uint256 tokenId,
        uint256 amount
    ) external onlyOwner {
        _mint(who, tokenId, amount, '');
    }

    function setURI(string memory _uri) external onlyOwner {
        baseURI = _uri;
    }

    function uri(uint256 id) public view override returns (string memory) {
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(id)))
                : '';
    }

    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}