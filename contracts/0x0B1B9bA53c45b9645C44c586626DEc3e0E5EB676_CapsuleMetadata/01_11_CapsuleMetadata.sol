// SPDX-License-Identifier: GPL-3.0

/**
  @title CapsuleMetadata

  @author peri

  @notice Renders metadata for Capsule tokens.
 */

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/ICapsuleMetadata.sol";
import "./utils/Base64.sol";

contract CapsuleMetadata is ICapsuleMetadata {
    /// @notice Returns base64-encoded json containing Capsule metadata.
    /// @dev `image` is passed as an argument to allow Capsule image rendering to be handled by an external contract.
    /// @param capsule Capsule to return metadata for.
    /// @param image Image to be included in metadata.
    function metadataOf(Capsule memory capsule, string memory image)
        external
        pure
        returns (string memory)
    {
        string memory pureText = "false";
        if (capsule.isPure) pureText = "true";

        bytes memory metadata = abi.encodePacked(
            '{"name": "Capsule ',
            Strings.toString(capsule.id),
            '", "description": "7,957 tokens with unique colors and editable text rendered as SVGs on-chain. 7 pure colors are reserved for wallets that pay gas to store one of the 7 Capsules fonts in the CapsulesTypeface contract.", "image": "',
            image,
            '", "attributes": [{"trait_type": "Color", "value": "',
            _bytes3ToColorCode(capsule.color),
            '"}, {"Pure": "',
            pureText,
            '"}, {"Font": "',
            Strings.toString(capsule.font.weight),
            '"}]}'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(metadata)
                )
            );
    }

    /// @notice Format bytes3 as html hex color code.
    /// @param b bytes3 value representing hex-encoded RGB color.
    /// @return o Formatted color code string.
    function _bytes3ToColorCode(bytes3 b)
        internal
        pure
        returns (string memory o)
    {
        bytes memory hexCode = bytes(Strings.toHexString(uint24(b)));
        o = "#";
        // Trim leading 0x from hexCode
        for (uint256 i = 2; i < 8; i++) {
            o = string.concat(o, string(abi.encodePacked(hexCode[i])));
        }
    }
}