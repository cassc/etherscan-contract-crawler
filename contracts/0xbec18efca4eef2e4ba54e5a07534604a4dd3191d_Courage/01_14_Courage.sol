//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CourageSvgs.sol";
import "./DataURIs.sol";
import "./ERC721ForAll.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Courage is ERC721ForAll("Carbonated Courage", "COUR") {
    using Strings for uint256;
    using DataURIs for string;

    // Hand-picked to be a pretty good one.
    uint256 private constant CONTRACT_IMAGE_SEED =
        469379910270314646414328754926797194489967926725;

    function contractURI() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "{\n"
                    '  "name": "Carbonated Courage",\n'
                    '  "description": "Courage you had it all along, even if you didn\'t know it.",\n',
                    '  "seller_fee_basis_points": 100,\n'
                    '  "fee_recipient": "0xa8Ffa84FE054da6BAb987a8984D4d35f54491A75",\n'
                    '  "image": "',
                    CourageSvgs.generateSvg(CONTRACT_IMAGE_SEED).toSvgURI(),
                    '"\n'
                    "}\n"
                )
            ).toJsonURI();
    }

    function _generateURI(uint256 tokenId)
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return generateJson(tokenId).toJsonURI();
    }

    function generateJson(uint256 tokenId)
        private
        pure
        returns (string memory)
    {
        string memory addr = tokenId.toHexString(20);
        string memory shortAddr = shortenAddress(addr);
        return
            string(
                abi.encodePacked(
                    "{\n"
                    '  "name": "Courage of ',
                    shortAddr,
                    '",\n'
                    '  "description": "Courage that ',
                    shortAddr,
                    " had all along, even if they didn't know it.\",\n"
                    '  "attributes": [\n'
                    "    {\n"
                    '      "trait_type": "Original owner",\n'
                    '      "value": "',
                    addr,
                    '"\n'
                    "    }\n"
                    "  ],\n"
                    '  "image": "',
                    CourageSvgs.generateSvg(tokenId).toSvgURI(),
                    '"\n'
                    "}\n"
                )
            );
    }

    function shortenAddress(string memory addr)
        private
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    slice(addr, 0, 5),
                    "\u2026",
                    slice(addr, 38, 42)
                )
            );
    }

    function slice(
        string memory s,
        uint256 start,
        uint256 end
    ) private pure returns (string memory) {
        bytes memory b = new bytes(end - start);
        for (uint256 i = 0; i < end - start; i++) {
            b[i] = bytes(s)[start + i];
        }
        return string(b);
    }
}