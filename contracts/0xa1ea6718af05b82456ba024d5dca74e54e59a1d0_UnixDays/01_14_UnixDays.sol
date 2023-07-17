// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../libraries/DateTime.sol";
import { Base64 } from "base64-sol/base64.sol";

/// @title Unix Days
/// @author Jake Allen
contract UnixDays is ERC1155Supply, Ownable {
    using Strings for uint256;

    // SVG elements
    string private svgPart1 = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 800"><rect width="100%" height="100%" fill="#';
    string private svgPart2 = '"/></svg>';

    constructor() ERC1155("") {}
    
    /// @notice return token metadata
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(exists(tokenId), "Nonexistent token");

        string memory name = string(abi.encodePacked('Day ', tokenId.toString()));
        string memory description = '';
        string memory color = getHexColor(tokenId);
        string memory encodedSVG = getEncodedSVG(color);

        string memory base64 = Base64.encode(abi.encodePacked(
            '{"name":"', name, '", "description":"', description, '", "image":"data:image/svg+xml;base64,', encodedSVG, '", "attributes":[{"trait_type":"Color","value":"#', color,'"}]''}'
        ));

        return string(abi.encodePacked('data:application/json;base64,', base64));
    }

    /// @notice mint today's color
    function mint() external {
        uint256 daysSinceEpoch = getDaysSinceEpoch();
        // receiving address, tokenId, quantity, data (none)
        _mint(msg.sender, daysSinceEpoch, 1, "");
    }

    /// @notice number of days since unix epoch in UTC
    function getDaysSinceEpoch() public view returns (uint256) {
        (uint256 year, uint256 month, uint256 day) = BokkyPooBahsDateTimeLibrary
            .timestampToDate(block.timestamp);
        return BokkyPooBahsDateTimeLibrary._daysFromDate(year, month, day);
    }

    /// @notice get base64 encoded svg for a given color
    function getEncodedSVG(string memory color) public view returns (string memory) {
        return Base64.encode(abi.encodePacked(
            svgPart1,
            color,
            svgPart2
        ));
    }

    /// @notice get a hex color for a given day
    function getHexColor(uint256 day) public pure returns (string memory) {
        // get deterministic bytes
        bytes32 hashBytes = keccak256((abi.encodePacked(day)));
        // return string of first 3 bytes
        return string(bytes32ToHexString(hashBytes));
    }

    /// @notice get literal string representation of first 6 bytes of bytes32 string
    function bytes32ToHexString(bytes32 data) public pure returns (string memory) {
        bytes memory temp = new bytes(6);
        uint256 count;

        for (uint256 i = 0; i < 3; i++) {
            bytes1 currentByte = bytes1(data << (i * 8));
            
            uint8 c1 = uint8(
                bytes1((currentByte << 4) >> 4)
            );
            
            uint8 c2 = uint8(
                bytes1((currentByte >> 4))
            );
        
            if (c2 >= 0 && c2 <= 9) temp[count++] = bytes1(c2 + 48);
            else temp[count++] = bytes1(c2 + 87);
            
            if (c1 >= 0 && c1 <= 9) temp[count++] = bytes1(c1 + 48);
            else temp[count++] = bytes1(c1 + 87);
        }

        return string(temp);
    }
}