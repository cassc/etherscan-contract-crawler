// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ThirdBeans
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                      `                                                                                     //
//       `  `  `  `  `  ` `  ` `  `  ` `  ` `  ` `  ` `  ` ` ` ` ` `(NNNNNNNN` ` ` ` `  ` `  ` `  ` `  `      //
//                                                                  JMMMMMMMN                                 //
//       `  `   `  `  `    `   `  `  `    `    `    `   ggggggggggggMMMMMMMMNgggg   `  `    `    `    `  `    //
//            `      `  `    `    `    `    `    `    ` MMMMMMMMMMMMMMMMMMMMMMMMM       `    `    `    `      //
//       `         `                               .....MMMMMMMMMMMMMMMMMMMMMMMMM(.......,     `    `         //
//         `  `  `      `  `   `     `   `  `  `   .MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM]  `                 //
//     `             `       `  ` `    `   .........MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMML...,  ` `  ` `      //
//       `  `   `  `    `  `         `     (MMMMMMMMMMMMMMMMMMMMMMMMNMMNMMNMMNMMMMMMMMMMMMMMMF     `    `     //
//         `  `      `  `    `    `........(MMMMMMMMMMMMNMMNMMNMMNMMMMMMMMMMMMMMMMMMMMMMMMMMMF `              //
//      `        `        `    `  `MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNMMNMMNMMMMMMMF   `  `  `      //
//          `   `  `  `      `     MMMMMMMMMMMMMMMMMNMMNMMMMMMMMMMMMNMMNMMNMMNMMMMMMMMMMNMMMMF        `       //
//       `    `      `  ` `    MMM[email protected] `     `    //
//         `     `         `   MMM[email protected]  `  `      //
//     `  `   `    ` `  `    ` MMMMMMMMMMMMMMMMMMMM#[email protected]            //
//           `    `     `      MMMMMMMMMMMMMMMMMMMM#[email protected]  `  `      //
//      `  `   `     `    .ggggMMMMMNMMNMMNMMNMMNMM#[email protected]    `       //
//       `      `  `  ` ` .MMMMMMMMMMMMMMMMMMMMMMMM#[email protected]       `    //
//          `           ` .MMMMMMM[email protected] ` `        //
//     `   `  `  `  `     .MMMMMMMNMMNMMNMMNMMNMMNMMMMMMMMMMMNMMMMNMMMMMMMMM#[email protected]    `       //
//       `      `    `.....MMMMMMM[email protected]      `     //
//          `      `  ,MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM)   dMMMMMMM#[email protected]  `         //
//     `  `   `  `    ,MMMMMMMMMNMMNMMNMMNMMNMMNMMNMMNMMMMMM[...dMMMMMMM#[email protected]   ` `      //
//       `     `    ` ,MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM_   MMMMMMMMNMMM#llldMMMMMMMMMMMMMMMMF                //
//         `      `  `,MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM~   MMMMMMMMMMMM#=lldMMMMMMMMMMMMMMMMF  `  `  `  `    //
//     `    ` `  `    ,MMMMMMMNMMNMMNMMNMMNMMNMMNMMNMMNM~   MMMMMMMMMNMMMMMMMMMMNMMNMMNMMNMMMF    `    `      //
//       `            ,MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM_   MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMF      `         //
//              ` -MMMMMMMMMNMMMMMMMMMMMMMMMMMMMMMMM!~~?MMMMMMMMMNMMNMMMMMMNMMNMMMMMMMMMMP~~~`   `            //
//         `  `   (MMMMMMMMMMMMMMNMMNMMNMMNMMNMMNMMN    MMMMMMMMMMMMMMMNMMMMMMMMMNMMNMMNM]            `       //
//       `        (MMMMMMMMMMMMUUUUMMMMMMMMMMMMMMMMMggggMMMMMMMNMMMMMMMMMMNMMMMMMMMMMMMMM]     `   `          //
//                (MMMMMMNMMMMNllllMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNMMNMMMMMMMNMMNMMMMMMMM]              `     //
//            `   (MMMMMMMMMMMNllllMMMMNMMNMMNMMNMMMMMMMMMMMMMMMMMMMMMMMNMMMMMMMMMMNMY"""^        `           //
//       `        (MMMMNMMMMMMNll=lMMMMMMMMMMMMMMMNMMMMMMMMMMNMMNMMMMMMMMMMNMMMMMMMMM}       `      `  `      //
//          `     (MMMMMMMMNMMMl=llMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNMMNMMMMMMMNMMMMMM:         `              //
//            `   (MMMMMMMMMMMNllllMMMNMMNMMNMMNMMMMNMMNMMNMMMMMMMMMMMMMMNMMMMMMM         `       `           //
//       `        (MMMMMMMMMMMMssssMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNMMMM            `        `       //
//              ` (MMMMNMMMMMMMMMMMIlllMMMMMMMMMMNMMMMMMMMMNZl=lMMMNMMNMMMMMMMMNM      `         `      `     //
//         `  `   (MMMMMMMMNMMMMMMMIlllMMMMNMMNMMMMMNMMNMMMNZlllMMMMMMMMNMMNMMMMM        `  `      `          //
//       `        (MMMMMMMMMMMMMMMMMMMMR=l=dMMMMMMM#=l=l==llMMMMMMMMMMMMMMMMN       `         `       `       //
//                (MMMMMMNMMMMMMMMMMMMMRllldMMMMNMM#llllllllMMMMMMNMMNMMMMMMN          `         `            //
//            `    ```([email protected]#````       `     `         `   `     //
//       `            ,[email protected]=l=l=ldMMMMMNMMMMMNMMMMMMMM#     `  `           `                //
//          `         [email protected]^           `  `       `  `    `      //
//            `  `        .MMMNMMNMMNMMMMMMMMMMMMMMMMMNMMMMMNMMMMMMMF       `  `         `  `                 //
//       `         `      .""""""""MMMMMMMMMMMMMMMMMMMMMMNMMY"""""""5            `  `              `  `       //
//                                 MMMMMNMMMMMMMMMMMMMMMMMMM)             `  `          `     `  `            //
//         `  `       `            TMMMMMMMMMMMMMMMMMMMMMMMM\        `         `  `  `      `           `     //
//       `       `      `                                       `      `  `         `              `          //
//                 `         `                                `   `        `  `  `      `    `   `    `       //
//            `            `    `                                   `  `       `          `                   //
//       `           `  `                                  `   `     `   `         `          `    `    `     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract ThirdBeansNFT is ERC1155Creator {
    constructor() ERC1155Creator("ThirdBeans", "ThirdBeansNFT") {}
}