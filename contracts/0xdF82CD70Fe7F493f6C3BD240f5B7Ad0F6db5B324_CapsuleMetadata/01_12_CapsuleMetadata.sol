// SPDX-License-Identifier: GPL-3.0

/**
  @title CapsuleMetadata

  @author peri

  @notice Renders metadata for Capsule tokens.
 */

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/ITypeface.sol";
import "./interfaces/ICapsuleMetadata.sol";
import "./interfaces/ICapsuleRenderer.sol";
import "./interfaces/ICapsuleToken.sol";
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
        string memory pureText = "no";
        string memory lockedText = "no";
        if (capsule.isPure) pureText = "yes";
        if (capsule.isLocked) lockedText = "yes";

        bytes memory metadata = abi.encodePacked(
            '{"name": "Capsule ',
            Strings.toString(capsule.id),
            '", "description": "7,957 NFTs with unique colors and editable text rendered as SVGs on-chain. 7 pure colors are reserved for wallets that pay gas to store one of the 7 Capsules typeface fonts in the CapsulesTypeface contract.", "image": "',
            image
        );

        // Split encoding into two chunks to avoid stack too deep
        metadata = abi.encodePacked(
            metadata,
            '", "attributes": [{"trait_type": "Color", "value": "#',
            _bytes3ToHexChars(capsule.color),
            '"}, {"font": "',
            Strings.toString(capsule.font.weight),
            '"}, {"pure": "',
            pureText,
            '"}, {"locked": "',
            lockedText,
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

    /// @notice Format bytes3 type to 6 hexadecimal ascii bytes.
    /// @param b bytes3 value to convert to hex characters.
    /// @return o hex character bytes.
    // TODO write custom?
    function _bytes3ToHexChars(bytes3 b)
        internal
        pure
        returns (bytes memory o)
    {
        uint24 i = uint24(b);
        o = new bytes(6);
        uint24 mask = 0x00000f;
        o[5] = _uint8toByte(uint8(i & mask));
        i = i >> 4;
        o[4] = _uint8toByte(uint8(i & mask));
        i = i >> 4;
        o[3] = _uint8toByte(uint8(i & mask));
        i = i >> 4;
        o[2] = _uint8toByte(uint8(i & mask));
        i = i >> 4;
        o[1] = _uint8toByte(uint8(i & mask));
        i = i >> 4;
        o[0] = _uint8toByte(uint8(i & mask));
    }

    /// @notice Convert uint8 type to ascii byte.
    /// @param i uint8 value to convert to ascii byte.
    /// @return b ascii byte.
    function _uint8toByte(uint8 i) internal pure returns (bytes1 b) {
        uint8 _i = (i > 9)
            ? (i + 87) // ascii a-f
            : (i + 48); // ascii 0-9

        b = bytes1(_i);
    }
}