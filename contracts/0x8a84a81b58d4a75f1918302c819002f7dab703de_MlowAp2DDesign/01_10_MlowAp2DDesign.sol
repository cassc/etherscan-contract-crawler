// SPDX-License-Identifier: MIT

/// @title MLow // AP 2D Design
/// @author transientlabs.xyz

/*◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺
◹◺                                      ◹◺
◹◺    MLow // AP 2D Design              ◹◺
◹◺    ¯\_(ツ)_/¯                         ◹◺
◹◺    ¯\(ツ)/¯                           ◹◺
◹◺    ʅ(ツ)ʃ                             ◹◺
◹◺    乁(ツ)ㄏ                             ◹◺
◹◺    乁(ツ)∫                             ◹◺
◹◺    ƪ(ツ)∫                             ◹◺
◹◺    ¯\_₍ッ₎_/¯                         ◹◺
◹◺    乁₍ッ₎ㄏ                             ◹◺
◹◺    ¯\_(ツ)_/¯                         ◹◺
◹◺     ¯\(ツ)/¯                          ◹◺
◹◺     ʅ(ツ)ʃ                            ◹◺
◹◺     乁(ツ)ㄏ                            ◹◺
◹◺     乁(ツ)∫                            ◹◺
◹◺     ƪ(ツ)∫                            ◹◺
◹◺     ¯\_₍ッ₎_/¯                        ◹◺
◹◺     乁₍ッ₎ㄏ                            ◹◺
◹◺     ʅ₍ッ₎ʃ                            ◹◺
◹◺     ¯\_(シ)_/¯                        ◹◺
◹◺     ¯\_(ツ゚)_/¯                       ◹◺
◹◺     乁(ツ゚)ㄏ                           ◹◺
◹◺     ¯\_㋡_/¯                          ◹◺
◹◺     ┐_㋡_┌                            ◹◺
◹◺     ┐_(ツ)_┌━☆ﾟ.*･｡ﾟ                  ◹◺
◹◺    ¯\_(⌣̯̀ ⌣́)_/¯                    ◹◺
◹◺     ¯\_(ಠ_ಠ)_/¯                      ◹◺
◹◺     ¯\_(ತ_ʖತ)_/¯                     ◹◺
◹◺     ¯\_(ಸ ‿ ಸ)_/¯                    ◹◺
◹◺     ¯\_(ಸ◞౪◟ಸ)_/¯                    ◹◺
◹◺     ¯\_(　´∀｀)_/¯                     ◹◺
◹◺     ¯\_(Φ ᆺ Φ)_/¯                    ◹◺
◹◺     ¯\_(´◉◞౪◟◉)_/¯                   ◹◺
◹◺     ¯\_(´・ω・｀)_/¯                    ◹◺
◹◺     ¯\_(˶′◡‵˶)_/¯                    ◹◺
◹◺     ¯\_(ಥ‿ಥ)_/¯                      ◹◺
◹◺     ¯\_(；へ：)_/¯                      ◹◺
◹◺     ¯\_(ᗒᗩᗕ)_/¯                      ◹◺
◹◺     ¯\_( ´･ω･)_/¯                    ◹◺
◹◺     ¯\_(๑❛ᴗ❛๑)_/¯                    ◹◺
◹◺     ¯\_(´°̥̥̥̥̥̥̥̥ω°̥̥̥̥̥̥̥̥｀)_/¯    ◹◺
◹◺     ʅ（´◔౪◔）ʃ                         ◹◺
◹◺     ┐(￣ー￣)┌                          ◹◺
◹◺     ★｡･:*¯\_(ツ)_/¯*:･ﾟ★              ◹◺
◹◺                                      ◹◺
◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺◹◺*/

pragma solidity 0.8.19;

import {TLCreator} from "tl-creator-contracts/TLCreator.sol";

contract MlowAp2DDesign is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x154DAc76755d2A372804a9C409683F2eeFa9e5e9,
        "MLow // AP 2D Design",
        "APART",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}