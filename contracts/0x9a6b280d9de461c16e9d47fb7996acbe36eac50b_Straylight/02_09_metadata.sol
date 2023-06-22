//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./turmitev4.sol";
import "solady/src/utils/LibString.sol";

/// @title Metadata
/// @notice Renders the dynamic metadata of every NFT via the Turmite v4.
/// @author @brachlandberlin / plsdlr.net
/// @dev Generates the metadata as JSON String and encodes it with base64 and data:application/json;base64,

contract Metadata is Turmite {
    string private network;

    constructor(string memory _network) {
        network = _network;
    }

    /// @dev generates the dynamic metadata
    /// @param tokenId the tokenId of the Turmite
    /// @param boardNumber the Board Number
    /// @param rule the rule of the turmite
    /// @param state current state
    /// @param turposx x position of the turmite
    /// @param turposy y position of the turmite
    /// @param orientation orientation of the turmite
    function fullMetadata(
        uint256 tokenId,
        uint8 boardNumber,
        bytes12 rule,
        bytes1 state,
        uint8 turposx,
        uint8 turposy,
        uint8 orientation
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        abi.encodePacked(
                            '{"name":"',
                            generateName(tokenId, boardNumber),
                            '", "description":"',
                            "Onchain Mutiplayer Art",
                            '", "image": "',
                            getSvg(boardNumber, turposx, turposy, true),
                            '",',
                            '"attributes": ',
                            generateAttributes(boardNumber, rule, state, turposx, turposy, orientation),
                            "}"
                        )
                    )
                )
            );
    }

    /// @dev generates the Name of the turmite as a string
    /// @param tokenId the tokenId of the Turmite
    /// @param boardNumber the Board Number
    function generateName(uint256 tokenId, uint8 boardNumber) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked("Turmite ", LibString.toString(tokenId), " World ", LibString.toString(boardNumber))
            );
    }

    /// @dev generates the dynamic attributes as JSON String, for param see fullMetadata()
    function generateAttributes(
        uint8 boardNumber,
        bytes12 rule,
        bytes1 state,
        uint8 turposx,
        uint8 turposy,
        uint8 orientation
    ) internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '[{"trait_type":"World","value":"',
                    LibString.toString(boardNumber),
                    '"},',
                    '{"trait_type":"Rule",',
                    '"value":"',
                    bytes12ToString(rule),
                    '"},',
                    '{"trait_type":"State",',
                    '"value":"',
                    LibString.toString(uint8(state)),
                    '"},',
                    '{"trait_type":"POS X",',
                    '"value":"',
                    LibString.toString(turposx),
                    '"},',
                    '{"trait_type":"POS Y",',
                    '"value":"',
                    LibString.toString(turposy),
                    '"},',
                    '{"trait_type":"Direction",',
                    '"value":"',
                    LibString.toString(orientation),
                    '"},{"trait_type":"Network","value":"',
                    network,
                    '"}]'
                )
            );
    }

    /// @dev helper function to create a String from a byte12
    /// @param _bytes12 the input value
    function bytes12ToString(bytes12 _bytes12) internal pure returns (string memory) {
        uint8 i = 0;
        bytes memory bytesArray = new bytes(24);
        for (i = 0; i < bytesArray.length; i++) {
            uint8 _f = uint8(_bytes12[i / 2] & 0x0f);
            uint8 _l = uint8(_bytes12[i / 2] >> 4);

            bytesArray[i] = toByte(_l);
            i = i + 1;
            bytesArray[i] = toByte(_f);
        }
        return string(bytesArray);
    }

    /// @dev helper function to convert from uint8 to byte1
    /// @param _uint8 the input value
    function toByte(uint8 _uint8) internal pure returns (bytes1) {
        if (_uint8 < 10) {
            return bytes1(_uint8 + 48);
        } else {
            return bytes1(_uint8 + 87);
        }
    }
}