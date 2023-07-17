// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/**===============================================================================
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@,,,,,,,,,@@@@@@@@@@@@@@,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,@@(((((,,,,,,,,,@@,,,,,@@((,,,,,,,,,,  @@,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,@@(((((,,,,,,,,,,,,,@@@@@((,,,,,,,,,,,,,,  @@,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,@@@((((,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,  @@@,,,,,,,,,,,,,,,
,,,,,,,,,,,,@@(((((((,,,,,,,,,,,,,,,,@@,,,,,,,,,,,,@@@@@@@@@@@,,,,,@@,,,,,,,,,,,,,
,,,,,,,,,,,,@@(((((((,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@    @@,,,@@,,,,,,,,,,,,,
,,,,,,,,,,@@(((((((,,,,@@@@@@@@@@@@@@,,@@@,,,,@@     @@@@@    @@,,,,,@@,,,,,,,,,,,
,,,,,,,,,,@@(((((((,,,,,,,,,,,,,,,,,,@@@@@,,,,@@   @@@@@@@    @@,,,,,@@,,,,,,,,,,,
,,,,,,,@@@(((((((((,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@@@@@@@@,,,,,,,,,@@@,,,,,,,,
,,,,,,,@@@(((((((((@@@@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@,,,,,,,,
,,,,,,,@@@((((((@@@(((((((@@@@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,@@@@@@@,,,,@@@,,,,,,,,
,,,,,,,@@@((((((@@@((@@(((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((@@,,@@@,,,,,,,,
,,,,,,,@@@((((((@@@((((@@@@@((((((((((((((((((((((((((((((((@@@@(((@@,,@@@,,,,,,,,
,,,,,,,@@@(((((((((@@(((((((@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@(((((((@@,,@@@,,,,,,,,
,,,,,,,@@@(((((((((**##############################################,,**@@@,,,,,,,,
,,,,,,,,,,@@(((((((((((,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,((@@,,,,,,,,,,,
,,,,,,,,,,,,@@(((((((((((((((((((((((((((((((((((((((((((((((((((((@@,,,,,,,,,,,,,
,,,,,,,,,,,,,,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
==================================================================================
🐸                               RENDERING LOGIC                                🐸
🐸                       THE PEOPLES' NFT MADE BY FROGS                         🐸
================================================================================*/

import "@openzeppelin/contracts/access/Ownable.sol";

contract Renderer is Ownable {

    // temp uri for the instant reveal process. This will be changed once all tokens
    // are revealed
    string public _baseTokenURI = "https://metadata.babypepes.repl.co/pepe/";

    constructor(){}

    /**
     🐸 @notice Get to metadata for a given token ID
     🐸 @param tokenId - Token ID for desired token
     🐸 @return metadata as a string
     */
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     🐸 @notice Get the baseTokenURI
     🐸 @return baseTokenURI as a string
     */
    function _baseURI() internal view returns (string memory) {
        return _baseTokenURI;
    }

    /**
     🐸 @notice Set the baseTokenURI
     🐸 @param baseTokenURI - URI for metadata
     */
    function setBaseURI(string memory baseTokenURI) public onlyOwner {
        _baseTokenURI = baseTokenURI;
    }

    /**
     🐸 @dev Converts a uint256 to its ASCII string decimal representation.
     */
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