// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC721Render} from "./SudoBastardMiladys.sol";

import {Base64} from "./lib/Base64.sol";

contract SudoBastardMiladysRender is Owned(msg.sender), ERC721Render {
    string private name;
    string private description;
    string private image;

    constructor(
        string memory name_,
        string memory description_,
        string memory image_
    ) {
        name = name_;
        description = description_;
        image = image_;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return
            metadata(
                string(abi.encodePacked(name, toString(id))),
                description,
                string(abi.encodePacked(image, toString(id), ".png"))
            );
    }

    function setMetadata(
        string memory name_,
        string memory description_,
        string memory image_
    ) external onlyOwner {
        name = name_;
        description = description_;
        image = image_;
    }

    function metadata(
        string memory name_,
        string memory description_,
        string memory image_
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                '"name":"',
                                name_,
                                '","description":"',
                                description_,
                                '","image":"',
                                image_,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

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
}