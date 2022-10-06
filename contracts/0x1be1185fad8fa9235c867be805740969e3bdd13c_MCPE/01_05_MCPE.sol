// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Misscoolpics Editions
/// @author: manifold.xyz

import "./ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//                       ,,    ,,          ,,                                                                                           //
//    `7MM"""YMM       `7MM    db   mm     db                                                                                           //
//      MM    `7         MM         MM                                                                                                  //
//      MM   d      ,M""bMM  `7MM mmMMmm `7MM  ,pW"Wq.`7MMpMMMb.  ,pP"Ybd                                                               //
//      MMmmMM    ,AP    MM    MM   MM     MM 6W'   `Wb MM    MM  8I   `"                                                               //
//      MM   Y  , 8MI    MM    MM   MM     MM 8M     M8 MM    MM  `YMMMa.                                                               //
//      MM     ,M `Mb    MM    MM   MM     MM YA.   ,A9 MM    MM  L.   I8                                                               //
//    .JMMmmmmMMM  `Wbmd"MML..JMML. `Mbmo.JMML.`Ybmd9'.JMML  JMML.M9mmmP'                                                               //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//     ,,                                       ,,                                               ,,             ,,                      //
//    *MM                     `7MMM.     ,MMF'  db                                             `7MM             db                      //
//     MM                       MMMb    dPMM                                                     MM                                     //
//     MM,dMMb.`7M'   `MF'      M YM   ,M MM  `7MM  ,pP"Ybd ,pP"Ybd  ,p6"bo   ,pW"Wq.   ,pW"Wq.  MM `7MMpdMAo.`7MM  ,p6"bo  ,pP"Ybd     //
//     MM    `Mb VA   ,V        M  Mb  M' MM    MM  8I   `" 8I   `" 6M'  OO  6W'   `Wb 6W'   `Wb MM   MM   `Wb  MM 6M'  OO  8I   `"     //
//     MM     M8  VA ,V         M  YM.P'  MM    MM  `YMMMa. `YMMMa. 8M       8M     M8 8M     M8 MM   MM    M8  MM 8M       `YMMMa.     //
//     MM.   ,M9   VVV          M  `YM'   MM    MM  L.   I8 L.   I8 YM.    , YA.   ,A9 YA.   ,A9 MM   MM   ,AP  MM YM.    , L.   I8     //
//     P^YbmdP'    ,V         .JML. `'  .JMML..JMML.M9mmmP' M9mmmP'  YMbmd'   `Ybmd9'   `Ybmd9'.JMML. MMbmmd' .JMML.YMbmd'  M9mmmP'     //
//                ,V                                                                                  MM                                //
//             OOb"                                                                                 .JMML.                              //
//                                                                                                                                      //
//                                                                                                                                      //
//                                                                                                                                      //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MCPE is ERC721Creator {
    constructor() ERC721Creator("Misscoolpics Editions", "MCPE") {}
}