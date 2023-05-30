// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.14;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

/**
*    ╦ ╦╔═╗╔═╗╔╦╗╦  ╔╗ ╦╔╦╗╔═╗╦ ╦╔═╗╔═╗
*    ║║║╠═╣║ ╦║║║║  ╠╩╗║ ║ ║  ╠═╣║╣ ╚═╗
*    ╚╩╝╩ ╩╚═╝╩ ╩╩  ╚═╝╩ ╩ ╚═╝╩ ╩╚═╝╚═╝
**/
contract WagmiBitches is ERC721A, Ownable {
    using Strings for uint256;

    string public baseURI = "ipfs://bafkreicno7wnskkrlzvd6ywck65m5hbxoxmx3flznsaxaiv7bvqod4arfe?";

    constructor() ERC721A("WAGMI BITCHES", "WAB") {}

    struct AirdropClaim {
        address wallet;
        uint256 amount;
    }

    function setBaseURI(string memory base) public onlyOwner {
        baseURI = base;
    }

    function tokenURI(uint256 tokenId) public view override(ERC721A) returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    function sendAirdrop(AirdropClaim[] calldata _claims) public onlyOwner {
        require(_claims.length > 0, "Airdrop wallet not set");

        unchecked {
            for(uint256 i; i < _claims.length; ++i) {
                AirdropClaim memory claim = _claims[i];
                _safeMint(claim.wallet, claim.amount);
            }
        }
    }
}