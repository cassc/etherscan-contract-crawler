// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: C.R. Kunferman Photography
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                                                                        //
//              ..'',;;::::crkCRKCRKCRKCRKCRKCRK.                         //
//             ..'',;;;::::photoPHOTOPHOTOPHOTOPHOTO.                     //
//            ..',,,;:::::crkcrk----Christopher----;                      //
//            .',,,;;:::photoPHOTO---Richard----PHOTO.                    //
//           ..',,,;;::::crkcrk----Kunferman----CRKCRK'                   //
//           ..',,,;;:::photophotophotophotophotophoto:'                  //
//           .'',,,;;:::::::crkcrk-Photography-crkcrk,.                   //
//           .'',,;;;:::::::photophotophotophotophoto::;.                 //
//         ..',,,,,,;:::::::crkcrkcrkcrkcrkcrkcrkcrkcrk::;'.              //
//        .PHOTO,,,::::::::crkcrkcrkcrkcrkcrkcrkcrkcrkcrkcrk;'.           //
//        ;CRKCRKcrk::::::::::::crkcrkcrkcrkcrkcrkcrkcrkcrkcrk:,..        //
//        ;PHOTOcrkCRK:::::::::::;;:photophotophotophoto:;,,,,,,,'..      //
//        .CRKCRKCRKCRKphoto::::::::crkcrkcrkcrkcrk::;,.  ........        //
//         ,crkCRKCRKcrkcrkcrk:::::::;;photoPHOTO:::      ....            //
//          ,::::crkPHOTOCRKPHOTOCRKCRKphotocrkPHOTO:                     //
//           .::crkCRKCRKCRKCRKCRKPHOTOPHOTOCRKPHOTO:                     //
//          .;:crkCRKPHOTOPHOTOPHOTOPHOTOPHOTOPHOTO:                      //
//        .crkcrkcrkPHOTOPHOTOPHOTOPHOTOPHOTOPHOTO;.                      //
//    ',::crkphotocrkCRKPHOTOCRKPHOTOCRKPHOTOPHOTO,..                     //
//    CRKCRKPHOTOCRKCRKCRKCRKCRKCRKCRKCRKCRKPHOTOCRKPHOTOcrk;.            //
//    CRKCRKCRKPHOTOPHOTOCRKCRKCRKCRKCRKCRKPHOTOCRKCRKCRKCRKcrk:.         //
//    CRKCRKCRKCRKCRKPHOTOCRKCRKCRKCRKPHOTOCRKCRKCRKCRKCRKCRKcrk:.        //
//    CRKCRKCRKCRKPHOTOCRKPHOTOCRKCRKCRKPHOTOCRKCRKCRKCRKCRKCRKcrk.       //
//    CRKCRKCRKCRKCRKCRKPHOTOCRKCRKCRKPHOTOPHOTOCRKCRKCRKCRKCRKcrk.       //
//    CRKCRKCRKCRKCRKCRKPHOTOPHOTOCRKPHOTOCRKCRKCRKCRKCRKCRKCRKCRK.       //
//    CRKCRK--Christopher Richard Kunferman Photography--CRKCRKCRK.       //
//    CRKCRKCRKCRKCRKPHOTOPHOTOCRKCRKCRKCRKCRKCRKCRKCRKCRKCRKPHOTO.       //
//    CRKRKCRKCRKCRKCRKCRKcrkcrkcrkPHOTOCRKCRKCRKCRKCRKCRKCRKPHOTO.       //
//    CRKCRKCRKCRKPHOTOcrkcrkcrkcrkcrkCRKCRKCRKPHOTOCRKCRKPHOTOCRK.       //
//    CRKCRKPHOTOCRKPHOTOcrkPHOTOCRKCRKCRKCRKCRKCRKCRKCRKCRKCRKCRK.       //
//                                                                        //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


contract CRKPhoto is ERC721Creator {
    constructor() ERC721Creator("C.R. Kunferman Photography", "CRKPhoto") {}
}