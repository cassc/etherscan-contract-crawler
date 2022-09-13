// SPDX-License-Identifier: GPL-3.0

/**
  @title Capsules Typeface

  @author peri

  @notice Capsules Typeface stored on-chain using the Typeface contract. 7 "normal" fonts are supported, with weights 100-700. All characters require 2 or less bytes to encode.
 */

pragma solidity ^0.8.8;

import "./interfaces/ICapsuleToken.sol";
import "./Typeface.sol";

contract CapsulesTypeface is Typeface {
    /// Address of Capsules Token contract
    ICapsuleToken public immutable capsuleToken;

    constructor(
        Font[] memory fonts,
        bytes32[] memory hashes,
        address _capsuleToken
    ) Typeface("Capsules") {
        _setFontSourceHashes(fonts, hashes);

        capsuleToken = ICapsuleToken(_capsuleToken);
    }

    function supportsCodePoint(bytes3 cp) external pure returns (bool) {
        // Optimize gas by first checking outer bounds of byte ranges
        if (cp < 0x000020 || cp > 0x00e421) return false;

        return ((cp >= 0x000020 && cp <= 0x00007e) ||
            (cp >= 0x0000a0 && cp <= 0x0000a8) ||
            (cp >= 0x0000ab && cp <= 0x0000ac) ||
            (cp >= 0x0000af && cp <= 0x0000b1) ||
            cp == 0x0000b4 ||
            (cp >= 0x0000b6 && cp <= 0x0000b7) ||
            (cp >= 0x0000ba && cp <= 0x0000bb) ||
            (cp >= 0x0000bf && cp <= 0x0000c4) ||
            (cp >= 0x0000c6 && cp <= 0x0000cf) ||
            (cp >= 0x0000d1 && cp <= 0x0000d7) ||
            (cp >= 0x0000d9 && cp <= 0x0000dc) ||
            (cp >= 0x0000e0 && cp <= 0x0000e4) ||
            (cp >= 0x0000e6 && cp <= 0x0000ef) ||
            (cp >= 0x0000f1 && cp <= 0x0000fc) ||
            (cp >= 0x0000ff && cp <= 0x000101) ||
            (cp >= 0x000112 && cp <= 0x000113) ||
            (cp >= 0x000128 && cp <= 0x00012b) ||
            cp == 0x000131 ||
            (cp >= 0x00014c && cp <= 0x00014d) ||
            (cp >= 0x000168 && cp <= 0x00016b) ||
            cp == 0x000178 ||
            cp == 0x00018e ||
            cp == 0x000192 ||
            cp == 0x000262 ||
            cp == 0x00026a ||
            cp == 0x000274 ||
            (cp >= 0x000280 && cp <= 0x000281) ||
            cp == 0x00028f ||
            cp == 0x000299 ||
            cp == 0x00029c ||
            cp == 0x00029f ||
            (cp >= 0x0002c2 && cp <= 0x0002c3) ||
            cp == 0x0002c6 ||
            cp == 0x0002dc ||
            cp == 0x00039e ||
            cp == 0x0003c0 ||
            cp == 0x000e3f ||
            (cp >= 0x001d00 && cp <= 0x001d01) ||
            cp == 0x001d05 ||
            cp == 0x001d07 ||
            (cp >= 0x001d0a && cp <= 0x001d0b) ||
            (cp >= 0x001d0d && cp <= 0x001d0e) ||
            (cp >= 0x001d18 && cp <= 0x001d19) ||
            cp == 0x001d1b ||
            (cp >= 0x002013 && cp <= 0x002015) ||
            (cp >= 0x002017 && cp <= 0x00201a) ||
            (cp >= 0x00201c && cp <= 0x00201e) ||
            (cp >= 0x002020 && cp <= 0x002022) ||
            cp == 0x002026 ||
            cp == 0x002030 ||
            (cp >= 0x002032 && cp <= 0x002033) ||
            (cp >= 0x002039 && cp <= 0x00203a) ||
            cp == 0x00203c ||
            cp == 0x00203e ||
            cp == 0x002044 ||
            cp == 0x0020a8 ||
            cp == 0x0020ac ||
            cp == 0x0020b4 ||
            cp == 0x0020bd ||
            cp == 0x0020bf ||
            cp == 0x002184 ||
            (cp >= 0x002190 && cp <= 0x002199) ||
            (cp >= 0x0021ba && cp <= 0x0021bb) ||
            cp == 0x002206 ||
            cp == 0x00220f ||
            (cp >= 0x002211 && cp <= 0x002212) ||
            cp == 0x00221a ||
            cp == 0x00221e ||
            cp == 0x00222b ||
            cp == 0x002248 ||
            cp == 0x002260 ||
            (cp >= 0x002264 && cp <= 0x002265) ||
            (cp >= 0x002302 && cp <= 0x002304) ||
            cp == 0x00231b ||
            cp == 0x0023cf ||
            (cp >= 0x0023e9 && cp <= 0x0023ea) ||
            (cp >= 0x0023ed && cp <= 0x0023ef) ||
            (cp >= 0x0023f8 && cp <= 0x0023fa) ||
            cp == 0x0025b2 ||
            cp == 0x0025b6 ||
            cp == 0x0025bc ||
            cp == 0x0025c0 ||
            cp == 0x0025ca ||
            cp == 0x002600 ||
            cp == 0x002610 ||
            cp == 0x002612 ||
            cp == 0x002630 ||
            (cp >= 0x002639 && cp <= 0x00263a) ||
            cp == 0x00263c ||
            cp == 0x002665 ||
            (cp >= 0x002680 && cp <= 0x002685) ||
            (cp >= 0x002690 && cp <= 0x002691) ||
            cp == 0x0026a1 ||
            cp == 0x002713 ||
            (cp >= 0x002b05 && cp <= 0x002b0d) ||
            cp == 0x002b95 ||
            cp == 0x00a730 ||
            cp == 0x00a7af ||
            (cp >= 0x00e000 && cp <= 0x00e02b) ||
            cp == 0x00e069 ||
            (cp >= 0x00e420 && cp <= 0x00e421));
    }

    /// @notice Mint pure color Capsule token to sender when sender sets font source.
    function _afterSetSource(Font calldata font, bytes calldata)
        internal
        override(Typeface)
    {
        capsuleToken.mintPureColorForFont(msg.sender, font);
    }
}