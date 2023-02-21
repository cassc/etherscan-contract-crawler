// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/Base64.sol";

library UnknownMetadata {
    /// @dev Render the JSON Metadata for a given Checks token.
    /// @param tokenId The id of the token to render.
    function tokenURI(
        uint256 tokenId
    ) public pure returns (string memory) {
        bytes memory metadata = abi.encodePacked(
            '{',
                '"name": "Unknown ', uint2str(tokenId), '",',
                '"description": "This brand may or may not be unknown.",',
                '"image": "https://unknownable.art/assets/u.png",',
                '"attributes": [',        '{',
                '"trait_type": "', "Burned", '",'
                '"value": "', "false", '"'
            '}', ']',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(metadata)
            )
        );
    }

        /// @dev Convert an integer to a string
    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            ++len;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}