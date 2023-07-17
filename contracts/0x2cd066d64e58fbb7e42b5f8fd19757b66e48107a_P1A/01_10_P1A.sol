// SPDX-License-Identifier: MIT

/// @title P1A by P1A
/// @author transientlabs.xyz

/*????????????????????????????????????????????????????????????????????????????????????????????
??                                                                                          ??
??    ,-σ@δ▒            ▒δ@α-.                                                              ??
??                               -σ▒                            ▒σ-                         ??
??                           ,φ▒           ╝╝ⁿⁿ""""""ⁿⁿ≈╝           ░è-                     ??
??                        -φ        ╩ⁿ`                      "ⁿ╝        ▒-                  ??
??                      σ       ╩"                                "╝       σ                ??
??                   ,φ      ╩"                                      "╝      ▒,             ??
??                  φ      ╛                                            └      ▒            ??
??                ╔      "                                                └      ≥          ??
??               φ     ╩                                                    ╚     ▒         ??
??              ╝     '                                                      `              ??
??             ╩                                                                            ??
??            ╝                                                                             ??
??           ╔                                                                        ▒     ??
??                ╩                                                              ╞          ??
??          {                                                                          ε    ??
??                                                                                          ??
??                                                                                @         ??
??                                                                                @         ??
??                                                                                ╚         ??
??          @                                                                               ??
??                ε                                                              )          ??
??           ╚                                                                              ??
??                 φ                                                            φ           ??
??            '     ▒                                                          @     '      ??
??             └     ▒                                                        φ     Γ       ??
??              `      ε                                                    ,╩     `        ??
??                ╚     ▒                                                  φ                ??
??                 └      δ                                              φ      "           ??
??                   ╘      ▒µ                                        -δ      ╩             ??
??                     └       ▒╓                                  «φ       "               ??
??                       `╝       ░σ-                         ,-#▒       ╝`                 ??
??                          "╚         ░δσ╔-,          ,-╔σφ▒         ╝`                    ??
??                              "╝                                ╝"                        ??
??                                  `"╘╩                    ≥╧"                             ??
??                                           ```""""``                                      ??
??                                                                                          ??
????????????????????????????????????????????????????????????????????????????????????????????*/

pragma solidity 0.8.19;

import {TLCreator} from "tl-creator-contracts/TLCreator.sol";

contract P1A is TLCreator {
    constructor(
        address defaultRoyaltyRecipient,
        uint256 defaultRoyaltyPercentage,
        address[] memory admins,
        bool enableStory,
        address blockListRegistry
    )
    TLCreator(
        0x12Ab97BDe4a92e6261fca39fe2d9670E40c5dAF2,
        "P1A",
        "X",
        defaultRoyaltyRecipient,
        defaultRoyaltyPercentage,
        msg.sender,
        admins,
        enableStory,
        blockListRegistry
    )
    {}
}