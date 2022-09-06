// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "lib/solmate/src/auth/Owned.sol";


contract BMRRenderer is Owned {

    address public immutable bmrnft;
    string public baseURI;

    constructor(address bmrnft_, string memory baseURI_) Owned(msg.sender) {
        bmrnft = bmrnft_;
        baseURI = baseURI_;
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : "";
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}