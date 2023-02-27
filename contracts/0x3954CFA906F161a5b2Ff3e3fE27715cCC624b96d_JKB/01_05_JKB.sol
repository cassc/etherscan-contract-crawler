// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Infinite Canvas by Jhekub
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXOdlc;,'''',;:cox0NWMMMMMMMMMMMMWN0koc:;,'''',;:ldkKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXkl;.                .':o0NMMMMMMW0d:'.                .,lkXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOc.                        .,oKWWKo,.                        .cONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk;                              .,,.                             .;kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0;                                                                    ;0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.                                                                      .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNo.                                                                        .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.                                    ...                                   .dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0'                                     ...                                    '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo                                      ...                                     lWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;                                      ...                                     ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMWNKOkxdc.                                      ...                                     .cddkOKNWMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMWKxl;'.                                            ...                                           .';lx0WMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMW0o,.                                                 ...                                                .,o0WMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMNk;.                  ..                                ...                               ..                  .;kNMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMWO;                      ...                              ...                            ....                      ;kWMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMXo.                         ...                            ...                          ....                         .lXMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMK:                             ...                          ...                        ...                              ;KMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMK;                                ...                        ...                      ...                                 ;KMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMNc                                   ...                      ...                    ...                                    cNMMMMMMMMMMMM    //
//    MMMMMMMMMMMMk.                                     ...                    ...                  ...                                      .kMMMMMMMMMMMM    //
//    MMMMMMMMMMMWl                                        ...                  ...                ...                                         lWMMMMMMMMMMM    //
//    MMMMMMMMMMMX;                                          ...                ...              ...                                           ;XMMMMMMMMMMM    //
//    MMMMMMMMMMMX;                                            ...              ...            ...                                             ;XMMMMMMMMMMM    //
//    MMMMMMMMMMMNc                                              ...            ...          ...                                               :NMMMMMMMMMMM    //
//    MMMMMMMMMMMMx.                                               ...          ..         ...                                                .dMMMMMMMMMMMM    //
//    MMMMMMMMMMMMX;                                                 ...                 ...                                                  ;KMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMO.                                                  ..                .                                                   .kMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWk.                                                                                                                      .xWMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWO,                                                            ..                                                      'OWMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMKl.                                                        .:o.                                                    .cKMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMM0,       ......................................       ':;okl.        ......................................       ,0WMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMNx.                                                     .;o;.                                                        .xNMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMXl.                                                                                                                    .lXMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMNc                                                                                                                        cXMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMWo                                                   ...               ..                                                   oWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMO.                                                 ...        ..        ...                                                 .OMMMMMMMMMMMM    //
//    MMMMMMMMMMMWo                                                ...         ...          ...                                                lWMMMMMMMMMMM    //
//    MMMMMMMMMMMN:                                              ...           ...            ...                                              :XMMMMMMMMMMM    //
//    MMMMMMMMMMMX;                                            ...             ...              ...                                            ;XMMMMMMMMMMM    //
//    MMMMMMMMMMMNc                                          ...               ...                ...                                          :XMMMMMMMMMMM    //
//    MMMMMMMMMMMMd                                        ...                 ...                  ...                                        oWMMMMMMMMMMM    //
//    MMMMMMMMMMMMK,                                     ...                   ...                    ...                                     '0MMMMMMMMMMMM    //
//    MMMMMMMMMMMMWx.                                  ...                     ...                      ...                                  .dWMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMWd.                               ...                       ...                        ...                               .oNMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMWx.                            ...                         ...                          ...                            .xNMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMWO;                         ...                           ...                            ...                         ;OWMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMNx,                     ...                             ...                              ...                     ,xNMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMNk:.                 ..                               ...                                ..                 .;xNMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMWKd:'.                                              ...                                               .':dKWMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMN0xlc;'...                                      ...                                       ...';cox0NWMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXO'                                     ...                                      'kXNWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNc                                     ...                                      :NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMx.                                    ...                                     .dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:                                    ...                                     :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,                                    ..                                    '0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0,                                                                        ,OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMKc.                                                                     :KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk,                                                                  ,xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNx;.                           .cddc.                           .,xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOo,.                     .;dKWMMWKd:.                     .,lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0dc,..           .':okXWMMMMMMMMWXko:'.           ..;cd0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWX0Oxdoooodxk0KNMMMMMMMMMMMMMMMMMMNK0kxdoooodxO0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract JKB is ERC721Creator {
    constructor() ERC721Creator("Infinite Canvas by Jhekub", "JKB") {}
}