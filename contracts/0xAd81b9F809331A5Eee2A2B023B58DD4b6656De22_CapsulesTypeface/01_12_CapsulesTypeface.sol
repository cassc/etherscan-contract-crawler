// SPDX-License-Identifier: GPL-3.0

/**
  @title Capsules Typeface

  @author peri

  @notice Capsules typeface stored on-chain using the TypefaceExpandable contract, allowing additional fonts to be added later.
 */

pragma solidity ^0.8.8;

import "./interfaces/ICapsuleToken.sol";
import "./TypefaceExpandable.sol";

contract CapsulesTypeface is TypefaceExpandable {
    /// Address of CapsuleToken contract
    ICapsuleToken public immutable capsuleToken;

    /// Mapping of style => weight => address that stored the font.
    mapping(string => mapping(uint256 => address)) private _patronOf;

    constructor(
        address _capsuleToken,
        address donationAddress,
        address operator
    ) TypefaceExpandable("Capsules", donationAddress, operator) {
        capsuleToken = ICapsuleToken(_capsuleToken);
    }

    /// @notice Returns the address of the patron that stored a font.
    /// @param font Font to check patron of.
    /// @return address Address of font patron.
    function patronOf(Font calldata font) external view returns (address) {
        return _patronOf[font.style][font.weight];
    }

    /// @notice Returns true if a unicode codepoint is supported by the Capsules typeface.
    /// @param cp Codepoint to check.
    /// @return ture True if supported.
    function supportsCodePoint(bytes3 cp) external pure returns (bool) {
        // Optimize gas by first checking outer bounds of byte ranges
        if (cp < 0x000020 || cp > 0x00ffe6) return false;

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
            cp == 0x000192 ||
            cp == 0x000262 ||
            cp == 0x00026a ||
            cp == 0x000274 ||
            cp == 0x000280 ||
            cp == 0x00028f ||
            cp == 0x000299 ||
            cp == 0x00029c ||
            cp == 0x00029f ||
            (cp >= 0x0002c2 && cp <= 0x0002c3) ||
            cp == 0x0002c6 ||
            cp == 0x0002dc ||
            cp == 0x000394 ||
            cp == 0x00039e ||
            cp == 0x0003c0 ||
            cp == 0x000e3f ||
            (cp >= 0x001d00 && cp <= 0x001d01) ||
            cp == 0x001d05 ||
            cp == 0x001d07 ||
            (cp >= 0x001d0a && cp <= 0x001d0b) ||
            cp == 0x001d0d ||
            cp == 0x001d18 ||
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
            cp == 0x00204e ||
            (cp >= 0x002058 && cp <= 0x00205b) ||
            (cp >= 0x00205d && cp <= 0x00205e) ||
            (cp >= 0x0020a3 && cp <= 0x0020a4) ||
            (cp >= 0x0020a6 && cp <= 0x0020a9) ||
            (cp >= 0x0020ac && cp <= 0x0020ad) ||
            (cp >= 0x0020b2 && cp <= 0x0020b6) ||
            cp == 0x0020b8 ||
            cp == 0x0020ba ||
            (cp >= 0x0020bc && cp <= 0x0020bd) ||
            cp == 0x0020bf ||
            cp == 0x00211e ||
            cp == 0x002126 ||
            (cp >= 0x002190 && cp <= 0x002199) ||
            (cp >= 0x0021ba && cp <= 0x0021bb) ||
            cp == 0x002206 ||
            cp == 0x00220f ||
            (cp >= 0x002211 && cp <= 0x002214) ||
            cp == 0x00221a ||
            cp == 0x00221e ||
            cp == 0x00222b ||
            cp == 0x002238 ||
            cp == 0x002243 ||
            cp == 0x002248 ||
            (cp >= 0x002254 && cp <= 0x002255) ||
            cp == 0x002260 ||
            (cp >= 0x002264 && cp <= 0x002267) ||
            (cp >= 0x00229e && cp <= 0x0022a1) ||
            cp == 0x0022c8 ||
            (cp >= 0x002302 && cp <= 0x002304) ||
            cp == 0x002310 ||
            cp == 0x00231b ||
            cp == 0x0023cf ||
            (cp >= 0x0023e9 && cp <= 0x0023ea) ||
            (cp >= 0x0023ed && cp <= 0x0023ef) ||
            (cp >= 0x0023f8 && cp <= 0x0023fa) ||
            (cp >= 0x002506 && cp <= 0x002507) ||
            cp == 0x00250c ||
            (cp >= 0x00250f && cp <= 0x002510) ||
            (cp >= 0x002513 && cp <= 0x002514) ||
            (cp >= 0x002517 && cp <= 0x002518) ||
            (cp >= 0x00251b && cp <= 0x00251c) ||
            (cp >= 0x002523 && cp <= 0x002524) ||
            (cp >= 0x00252b && cp <= 0x00252c) ||
            (cp >= 0x002533 && cp <= 0x002534) ||
            (cp >= 0x00253b && cp <= 0x00253c) ||
            (cp >= 0x00254b && cp <= 0x00254f) ||
            (cp >= 0x00256d && cp <= 0x00257b) ||
            (cp >= 0x002580 && cp <= 0x002590) ||
            (cp >= 0x002594 && cp <= 0x002595) ||
            (cp >= 0x002599 && cp <= 0x0025a1) ||
            (cp >= 0x0025b0 && cp <= 0x0025b2) ||
            cp == 0x0025b6 ||
            cp == 0x0025bc ||
            cp == 0x0025c0 ||
            cp == 0x0025ca ||
            (cp >= 0x0025cf && cp <= 0x0025d3) ||
            (cp >= 0x0025d6 && cp <= 0x0025d7) ||
            (cp >= 0x0025e0 && cp <= 0x0025e5) ||
            (cp >= 0x0025e7 && cp <= 0x0025eb) ||
            (cp >= 0x0025f0 && cp <= 0x0025f3) ||
            (cp >= 0x0025f8 && cp <= 0x0025fa) ||
            (cp >= 0x0025ff && cp <= 0x002600) ||
            cp == 0x002610 ||
            cp == 0x002612 ||
            (cp >= 0x002630 && cp <= 0x002637) ||
            (cp >= 0x002639 && cp <= 0x00263a) ||
            cp == 0x00263c ||
            cp == 0x002665 ||
            (cp >= 0x002680 && cp <= 0x002685) ||
            (cp >= 0x00268a && cp <= 0x002691) ||
            cp == 0x0026a1 ||
            cp == 0x002713 ||
            cp == 0x002795 ||
            cp == 0x002797 ||
            (cp >= 0x0029d1 && cp <= 0x0029d5) ||
            cp == 0x0029fa ||
            cp == 0x002a25 ||
            (cp >= 0x002a2a && cp <= 0x002a2c) ||
            (cp >= 0x002a71 && cp <= 0x002a72) ||
            cp == 0x002a75 ||
            (cp >= 0x002a99 && cp <= 0x002a9a) ||
            (cp >= 0x002b05 && cp <= 0x002b0d) ||
            (cp >= 0x002b16 && cp <= 0x002b19) ||
            (cp >= 0x002b90 && cp <= 0x002b91) ||
            cp == 0x002b95 ||
            cp == 0x00a730 ||
            cp == 0x00a7af ||
            (cp >= 0x00e000 && cp <= 0x00e02c) ||
            (cp >= 0x00e02e && cp <= 0x00e032) ||
            cp == 0x00e069 ||
            (cp >= 0x00e420 && cp <= 0x00e421) ||
            cp == 0x00fe69 ||
            cp == 0x00ff04 ||
            (cp >= 0x00ffe0 && cp <= 0x00ffe1) ||
            (cp >= 0x00ffe5 && cp <= 0x00ffe6));
    }

    /// @dev Mint pure color Capsule token to sender when sender sets font source.
    function _afterSetSource(Font calldata font, bytes calldata)
        internal
        override(Typeface)
    {
        _patronOf[font.style][font.weight] = msg.sender;

        capsuleToken.mintPureColorForFont(msg.sender, font);
    }
}