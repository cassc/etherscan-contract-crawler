// SPDX-License-Identifier: UNLICENCED
// Implementation Copyright 2021, the author; All rights reserved
//
// This contract is an on-chain implementation of a concept created and
// developed by John F Simon Jr in partnership with e•a•t•works and
// @fingerprintsDAO
pragma solidity 0.8.10;

import "./IEveryIconRepository.sol";
import "@divergencetech/ethier/contracts/random/PRNG.sol";
import "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @title Every Icon library
/// @author @divergenceharri (@divergence_art)
library EveryIconLib {
    using DynamicBuffer for bytes;
    using PRNG for PRNG.Source;
    using Strings for uint256;

    /// @dev A set of contracts containing base icons from which designs are
    /// built. Each MUST hold exactly 32 icons, with the first 104 being
    /// "design" icons and the next 28 being the "random" ones.
    struct Repository {
        IEveryIconRepository[4] icons;
    }

    /// @notice Returns the i'th "design" icon from the Repository.
    function designIcon(Repository storage repo, uint256 i)
        internal
        view
        returns (uint256[4] memory)
    {
        require(i < 100, "Invalid design icon");
        return repo.icons[i / 32].icon(i % 32);
    }

    /// @notice Returns the i'th "random" icon from the Repository.
    function randomIcon(Repository storage repo, uint256 i)
        internal
        view
        returns (uint256[4] memory)
    {
        require(i < 28, "Invalid random icon");
        return repo.icons[3].icon(i + 4);
    }

    /// @dev Masks the block in which an icon was minted to encode it in the
    /// bottom row of the image.
    uint256 internal constant MINTING_BLOCK_MASK = 2**32 - 1;

    /// @notice Constructs icon from parameters, returning a buffer of 1024 bits
    function startingBits(
        Repository storage repo,
        Token memory token,
        uint256 mintingBlock,
        uint256 ticks
    ) internal view returns (uint256[4] memory) {
        uint256[4] memory di0 = designIcon(repo, token.designIcon0);
        uint256[4] memory di1 = designIcon(repo, token.designIcon1);
        uint256[4] memory ri = randomIcon(repo, token.randIcon);
        uint256[4] memory icon;

        // Start by combining inputs to get the base token
        //
        // The original JavaScript piece, which this contract mimics, inverts
        // bits for the 'ticking' of the icons. It's easier to correct for this
        // by inverting all of the incoming values and performing inverted
        // bitwise operations here, hence the ~((~x & ~y) | ~z) patterns.
        if (token.combMethod == 0) {
            for (uint256 i = 0; i < 4; i++) {
                icon[i] = ~((~di0[i] & ~di1[i]) | ~ri[i]);
            }
        } else if (token.combMethod == 1) {
            for (uint256 i = 0; i < 4; i++) {
                icon[i] = ~((~di0[i] & ~di1[i]) ^ ~ri[i]);
            }
        } else if (token.combMethod == 2) {
            for (uint256 i = 0; i < 4; i++) {
                icon[i] = ~((~di0[i] | ~di1[i]) ^ ~ri[i]);
            }
        } else {
            // Although this won't be exposed to collectors, it allows for
            // testing of individual base icons via a different, inheriting
            // contract.
            for (uint256 i = 0; i < 4; i++) {
                icon[i] = di0[i];
            }
        }

        // After combining icons, we clear the last row of the image and replace
        // it with a big-endian representation of the block number in which the
        // token was minted. We chose big-endian representation (in contrast to
        // 'ticks') to remain consistent with Solidity's handling of integers
        mintingBlock = mintingBlock & MINTING_BLOCK_MASK;
        icon[3] = (icon[3] & (~MINTING_BLOCK_MASK)) | mintingBlock;

        // Finally, we add 'ticks'. For a starting icon this will be equal to
        // zero, but the 'peekSVG' function is designed to see how far the icon
        // would have got based on the assumed iteration rate of 100 ticks per
        // second.
        //
        // This step is complicated by the fact that the icon animation is
        // effectively little-endian. We therefore need to increment from the
        // highest bit down.
        unchecked {
            // Although all values only ever contain a single bit, they're
            // defined as uint256 instead of bool to shift without the need for
            // casting.
            uint256 a;
            uint256 b;
            uint256 sum; // a+b
            uint256 carry;
            uint256 mask;

            // Breaking the loop based on a lack of further carry (instead of
            // only looping over each word once) allows for overflow should the
            // icon reach the end. This will never happen (see [1] for an
            // interesting explanation!), but conceptually it is a core part of
            // the artwork – otherwise it would be impossible for "every" icon
            // to be generated!
            //
            // [1] Schneider B. Applied Cryptography: Protocols, Algorithms, and
            //     Source Code in C; pp. 157–8.
            for (uint256 i = 0; ticks + carry > 0; i = (i + 1) % 4) {
                mask = 1 << 255;
                for (uint256 j = 0; j < 256 && ticks + carry > 0; j++) {
                    a = ticks & 1;
                    b = (icon[i] >> (255 - j)) & 1;
                    sum = a ^ b ^ carry;
                    icon[i] = (icon[i] & ~mask) | (sum << (255 - j));

                    carry = a + b + carry >= 2 ? 1 : 0;
                    ticks >>= 1;
                    mask >>= 1;
                }
            }
        }

        return icon;
    }

    /// @notice Metadata defining a token's icon.
    struct Token {
        uint8 designIcon0;
        uint8 designIcon1;
        uint8 randIcon;
        uint8 combMethod;
    }

    /// @notice Returns a static SVG from a 1024-bit buffer. This is used for thumbnails
    /// and in the OpenSea listing, before the viewer clicks into the animated version of
    /// a piece.
    function renderSVG(uint256[4] memory icon)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory svg = DynamicBuffer.allocate(2**16); // 64KB
        svg.appendSafe(
            abi.encodePacked(
                "<svg width='512' height='512' xmlns='http://www.w3.org/2000/svg'>",
                "<style>",
                "rect{width:16px;height:16px;stroke-width:1px;stroke:#c4c4c4}",
                ".b{fill:#000}",
                ".w{fill:#fff}",
                "</style>"
            )
        );

        uint256 x;
        uint256 y;
        bool bit;
        for (uint256 i = 0; i < 1024; i++) {
            x = (i % 32) * 16;
            y = (i / 32) * 16;
            bit = (icon[i / 256] >> (255 - (i % 256))) & 1 == 1;

            svg.appendSafe(
                abi.encodePacked(
                    "<rect x='",
                    x.toString(),
                    "' y='",
                    y.toString(),
                    "' class='",
                    bit ? "b" : "w",
                    "'/>"
                )
            );
        }

        svg.appendSafe("</svg>");
        return svg;
    }

    /// @notice Returns a random Token for an NFT which has not had its icon set
    /// by the cut-off point. Deterministically seeded from tokenId and
    /// mintingBlock.
    function randomToken(uint256 tokenId, uint256 mintingBlock)
        public
        pure
        returns (Token memory)
    {
        PRNG.Source src = PRNG.newSource(
            keccak256(abi.encodePacked(tokenId, mintingBlock))
        );

        return
            EveryIconLib.Token({
                designIcon0: uint8(src.readLessThan(100)),
                designIcon1: uint8(src.readLessThan(100)),
                randIcon: uint8(src.readLessThan(28)),
                combMethod: uint8(src.readLessThan(3))
            });
    }
}