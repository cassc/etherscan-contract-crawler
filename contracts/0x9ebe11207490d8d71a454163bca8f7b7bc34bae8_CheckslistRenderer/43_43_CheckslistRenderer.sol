// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ColorLib} from "zorb/ColorLib.sol";
import {Base64} from "base64/base64.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";
import {IMetadataRenderer} from "zora-drops-contracts/interfaces/IMetadataRenderer.sol";
import {ERC721Drop} from "zora-drops-contracts/ERC721Drop.sol";

contract CheckslistRenderer is IMetadataRenderer {
    string public name;
    string public description;
    string public contractImage;
    string public sellerFeeBasisPoints;
    string public sellerFeeRecipient;
    string public externalLink;
    ERC721Drop tokenContract;

    constructor(
        string memory _name,
        string memory _description,
        string memory _contractImage,
        string memory _sellerFeeBasisPoints,
        string memory _sellerFeeRecipient,
        string memory _externalLink,
        address payable _erc721DropAddress
    ) {
        tokenContract = ERC721Drop(_erc721DropAddress);
        name = _name;
        description = _description;
        contractImage = _contractImage;
        sellerFeeBasisPoints = _sellerFeeBasisPoints;
        sellerFeeRecipient = _sellerFeeRecipient;
        externalLink = _externalLink;
    }

    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(
            tokenContract.totalSupply() >= tokenId,
            "Token does not exist."
        );

        address ownerOf = tokenContract.ownerOf(tokenId);
        uint256 balanceOf = tokenContract.balanceOf(ownerOf);

        require(balanceOf <= 80, "Balance should not be greater than 80");

        string memory json;
        string memory idString = Strings.toString(tokenId);

        json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        name,
                        " #",
                        idString,
                        '", "title": "',
                        name,
                        " #",
                        idString,
                        '", "description": "',
                        description,
                        '", "image": "',
                        buildSVG(ownerOf, balanceOf),
                        '"}'
                    )
                )
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function contractURI() public view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "',
                                    name,
                                    's", "description": "',
                                    description,
                                    '", "image": "',
                                    contractImage,
                                    '", "seller_fee_basis_points": "',
                                    sellerFeeBasisPoints,
                                    '", "seller_fee_recipient": "',
                                    sellerFeeRecipient,
                                    '", "external_link": "',
                                    externalLink,
                                    '"}'
                                )
                            )
                        )
                    )
                )
            );
    }

    function buildSVG(
        address user,
        uint256 balanceOf
    ) public pure returns (string memory) {
        string memory checks = "";
        for (uint256 i = 0; i < balanceOf; i++) {
            checks = string(
                abi.encodePacked(checks, checkForIndex(uint8(i), true, user))
            );
        }
        for (uint256 i = balanceOf; i < 80; i++) {
            checks = string(
                abi.encodePacked(checks, checkForIndex(uint8(i), false, user))
            );
        }
        string memory encoded = Base64.encode(
            abi.encodePacked(
                '<svg viewBox="0 0 992 992" fill="none" xmlns="http://www.w3.org/2000/svg">'
                '<path fill="black" d="M0 0H992V992H0V0z"/>'
                '<path x="551.108" y="447.852" fill="#151515" d="M273.35 222.135H718.65V769.867H273.35V222.135z"/>',
                checks,
                "</svg>"
            )
        );
        return string(abi.encodePacked("data:image/svg+xml;base64,", encoded));
    }

    function checkForIndex(
        uint8 index,
        bool completed,
        address user
    ) internal pure returns (string memory) {
        uint32 translateX = uint16(index % 8) * 52;
        uint32 translateY = uint16(index / 8) * 52;
        bytes[5] memory gradient = ColorLib.gradientForAddress(user);

        uint colorIndex;

        if (index <= 12) {
            colorIndex = 0;
        } else if (index <= 32) {
            colorIndex = 1;
        } else if (index <= 57) {
            colorIndex = 2;
        } else if (index <= 72) {
            colorIndex = 3;
        } else {
            colorIndex = 4;
        }

        string memory color = completed
            ? string(abi.encodePacked(gradient[colorIndex]))
            : "#191919";
        return
            string(
                abi.encodePacked(
                    '<g transform="translate(',
                    Strings.toString(translateX),
                    ",",
                    Strings.toString(translateY),
                    ')">',
                    '<path d="M329.602 263.33C329.602 261.18 328.411 259.315 326.678 258.43C326.887 257.838 327.002 257.198 327.002 256.524C327.002 253.516 324.674 251.082 321.805 251.082C321.165 251.082 320.553 251.196 319.986 251.422C319.144 249.602 317.364 248.357 315.308 248.357C313.253 248.357 311.475 249.605 310.63 251.419C310.065 251.195 309.451 251.079 308.811 251.079C305.939 251.079 303.613 253.516 303.613 256.524C303.613 257.197 303.726 257.837 303.937 258.43C302.205 259.315 301.014 261.177 301.014 263.33C301.014 265.366 302.078 267.139 303.658 268.076C303.63 268.308 303.613 268.539 303.613 268.776C303.613 271.784 305.939 274.221 308.811 274.221C309.451 274.221 310.063 274.104 310.628 273.88C311.473 275.697 313.25 276.943 315.307 276.943C317.365 276.943 319.144 275.697 319.986 273.88C320.551 274.103 321.163 274.218 321.805 274.218C324.677 274.218 327.002 271.781 327.002 268.773C327.002 268.536 326.986 268.305 326.957 268.075C328.534 267.139 329.602 265.366 329.602 263.332V263.33ZM320.596 258.792L314.696 267.64C314.498 267.936 314.176 268.095 313.845 268.095C313.651 268.095 313.453 268.041 313.279 267.923L313.123 267.796L309.835 264.508C309.436 264.11 309.436 263.462 309.835 263.065C310.233 262.668 310.88 262.665 311.278 263.065L313.688 265.471L318.894 257.657C319.207 257.187 319.841 257.063 320.31 257.375C320.781 257.688 320.909 258.322 320.596 258.791V258.792Z" fill="',
                    color,
                    '"/></g>'
                )
            );
    }

    function initializeWithData(bytes memory initData) external pure {
        require(initData.length == 0, "not zero");
    }
}