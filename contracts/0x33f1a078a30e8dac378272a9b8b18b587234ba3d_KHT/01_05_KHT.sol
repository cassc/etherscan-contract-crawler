// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Kahtnipp.art
/// @author: manifold.xyz

import "./ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                           //
//                                                                                           //
//    pragma solidity ^0.8.0;                                                                //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                         MMmMMRawRr                                        //
//                             _  _ ____ _  _ ___ __ _ _ ___  ___                            //
//                             |-:_ |--| |--|  |  | \| | |--' |--'                           //
//                                                                                           //
//                                    https://kahtnipp.art                                   //
//                                                                                           //
//     01001011 01100001 01101000 01110100  (=`I'=)  01101110 01101001 01110000 01110000     //
//                                                                                           //
//                                           |\_/|                                           //
//                                           `o.o'                                           //
//                                           =(_)=                                           //
//                                             U                                             //
//                                                                                           //
//                                                                                           //
//              M.                                         .:M                               //
//               MMMM.                                   .:MMMM                              //
//               MMMMMMMM                             .:MMMMMMM                              //
//               :MMHHHMMMMHMM.  .:MMMMMMMMM:.      .:MMHHMHMM:                              //
//                :MMHHIIIHMMMM.:MMHHHHIIIHHMMMM. .:MMHIHIIHHM:                              //
//                 MMMHIIIIHHMMMIIHHMHHIIIIIHHMMMMMMHHHIIIIHHM:                              //
//                 :MMHIIIIIHMMMMMMMHHIIIIIIHHHMMMMMHHII:::IHM.                              //
//                  MH:I:::IHHMMMMMHHII:::IIHHMMMHHHMMM:I:IHMM                               //
//                  :MHI:HHIHMMHHIIHII::.::IIHMMHHIHHMMM::HMM:                               //
//                   MI::HHMMIIM:IIHII::..::HM:MHHII:::IHHMM:                                //
//                   MMMHII::..:::IHMMHHHMHHMMI:::...::IHM:                                  //
//                   :MHHI::....::::HMMMMMMHHI::.. ..:::HM:                                  //
//                    :MI:.:MH:.....:HMMMMHHMIHMMHHI:HH.:M                                   //
//                    M:.I..MHHHHHMMMIHMMMMHMMHHHHHMMH:.:M.                                  //
//                    M:.H..H  I:HM:MHMHI:IM:I:MM::  MMM:M:                                  //
//                    :M:HM:.M I:MHMIIMMIIHM I:MM::.:MMI:M.                                  //
//                    'M::MM:IMH:MMII MMHIMHI :M::IIHMM:MM                                   //
//                     MH:HMMHIHMMMMMMHMMIMHIIHHHHIMMHHMM                                    //
//                      MI:MMMMHI:::::IMM:MHI:::IMMMMHIM                                     //
//                      :IMHIHMMMMMM:MMMMMHHHHMMMHI:M                                        //
//                        HI:IMIHMMMM:MMMMMMHHHMI:.:M      .....                             //
//            ............M::..:HMMMMIMHIIHMMMMHII:M:::''''                                  //
//                ....:::MHI:.:HMMMMMMMMHHHMHHI::M:::::::''''''                              //
//               ''   ...:MHI:.::MMHHHMHMIHMMMMHH.MI..........                               //
//                  ''  ...MHI::.::MHHHHIHHMM:::IHM           '''                            //
//                     '  IMH.::..::HMMHMMMH::..:HM:                                         //
//                       :M:.H.IHMIIII::IIMHMMM:H.MH                                         //
//                        IMMMH:HI:MMIMI:IHI:HIMIHM:                                         //
//                      .MMI:.HIHMIMI:IHIHMMHIHI:MIM.                                        //
//                     .MHI:::HHIIIIIHHI:IIII::::M:IM.                                       //
//                    .MMHII:::IHIII::::::IIIIIIHMHIIM                                       //
//                    MHHHI::.:IHHII:::.:::IIIIHMHIIHM:                                      //
//                   MHHHII::..::MII::.. ..:IIIHHHII:IM.                                     //
//                  .MHHII::....:MHII::.  .:IHHHI::IIHMM.                                    //
//                  MMHHII::.....:IHMI:. ..:IHII::..:HHMM                                    //
//                  MHHII:::......:IIHI...:IHI::.....::HM:                                   //
//                 :MMH:::........ ...::..::....  ...:IHMM                                   //
//                 IMHIII:::..........     .........::IHMM.                                  //
//                 :MHIII::::......          .......::IHMM:                                  //
//                  MHHIII::::...             ......::IHMM:                                  //
//                  IMHHIII:::...             .....::IIHMM,                                  //
//                  :MHHIII:::I:::...     ....:::I:::IIHMM                                   //
//                   MMHHIII::IHI:::...........:::IIH:IHMM                                   //
//                   :MMHHII:IIHHI::::::.....:::::IH:IHMIM                                   //
//                    MMMHHII:IIHHI:::::::::::::IHI:IIHM:M.                                  //
//                    MMMHHIII::IHHII:::::::::IHI:IIIHMM:M:                                  //
//                    :MMHHHIII::IIIHHII::::IHI..IIIHHM:MHM                                  //
//                    :MMMHHII:..:::IHHMMHHHHI:IIIIHHMM:MIM                                  //
//                    .MMMMHHII::.:IHHMM:::IIIIIIHHHMM:MI.M                                  //
//                  .MMMMHHII::.:IHHMM:::IIIIIIHHHMM:MI.M                                    //
//                .MMMMHHMHHII:::IHHMM:::IIIIIHHHHMM:MI.IM.                                  //
//               .MMHMMMHHHII::::IHHMM::I&&&IHHHHMM:MMH::IM.                                 //
//              .MMHHMHMHHII:::.::IHMM::IIIIHHHMMMM:MMH::IHM                                 //
//              :MHIIIHMMHHHII:::IIHMM::IIIHHMMMMM::MMMMHHHMM.                               //
//              MMHI:IIHMMHHHI::::IHMM:IIIIHHHMMMM:MMMHI::IHMM.                              //
//              MMH:::IHMMHHHHI:::IHMM:IIIHHHHMMMM:MMHI:.:IHHMM.                             //
//              :MHI:::IHMHMHHII::IHMM:IIIHHHMMMMM:MHH::.::IHHM:                             //
//              'MHHI::IHMMHMHHII:IHMM:IIHHHHMMMM:MMHI:...:IHHMM.                            //
//               :MHII:IIHMHIHHIIIIHMM:IIHHHHMMMM:MHHI:...:IIHMM:                            //
//               'MHIII:IHHMIHHHIIHHHMM:IHHHMMMMM:MHHI:..::IIHHM:                            //
//                :MHHIIIHHMIIHHHIHHHMM:HHHHMMMMM:MHII::::IIIHHMM                            //
//                 MHHIIIIHMMIHHHIIHHMM:HHHHMMMM:MMHHIIHIIIIIHHMM.                           //
//                 'MHHIIIHHMIIHHIIIHMM:HHHMMMMH:MHHMHII:IIIHHHMM:                           //
//                  'MHHIIIHMMIHHHIHHMM:HHHMMMHH:MMIMMMHHHIIIHHMM:                           //
//                   'MHHIIHHMIHHHHHMMM:HHHMMMH:MIMMMMMMMMMMHIHHM:                           //
//                    'MHIIIHMMIHHHHHMM:HHHMMMH:IMMMMMHHIHHHMMHHM'                           //
//                     :MHHIIHMIHHHHHMM:HHHMMMM:MMHMMHIHMHI:IHHHM                            //
//                      MHHIIHM:HHHHHMM:HHHMMMM:MMMHIHHIHMM:HHIHM                            //
//                       MHHIHM:IHHHHMM:HHHHMM:MMHMIIHMIMMMHMHIM:                            //
//                       :MHIHMH:HHHHMM:HHHHMM:MMHIIHMIIHHMMHIHM:                            //
//                        MMHHMH:HHHHMM:HHHHMM:MHHIHMMIIIMMMIIHM'                            //
//                        'MMMMH:HHHHMM:HHHMM:MHHHIMMHIIII::IHM:                             //
//                         :MMHM:HHHHMM:HHHMM:MHIHIMMHHIIIIIHM:                              //
//                          MMMM:HHHHMM:HHHHM:MHHMIMMMHHHIHHM:MMMM.                          //
//                          :MMM:IHHHMM:HHHMM:MHHMIIMMMHHMM:MMMMMMM:                         //
//                          :MMM:IHHHM:HHHHMM:MMHHHIHHMMM:MMMMMMMMMM                         //
//                           MHM:IHHHM:HHHMMM:MMHHHHIIIMMIIMMMMMMMMM                         //
//                           MHM:HHHHM:HHHMMM:HMMHHHHHHHHHMMMMMMMMM:                         //
//                        .MI:MM:MHHMM:MHMMHMHHMMMMHHHHHHHMMMMMMMMM'                         //
//                       :IM:MMIM:M:MM:MH:MM:MH:MMMMMHHHHHMMMMMMMM'                          //
//                       :IM:M:IM:M:HM:IMIHM:IMI:MMMMMHHHMMMMMM:'                            //
//                        'M:MHM:HM:MN:HMIHM::M'   '::MMMMMMM:'                              //
//                           'M'HMM'M''M''HM'I'                                              //
//                                                                                           //
//                                                                                           //
//                                                                                           //
//                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////


contract KHT is ERC721Creator {
    constructor() ERC721Creator("Kahtnipp.art", "KHT") {}
}