// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: The Merge
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    [email protected]@[email protected]@[email protected]@[email protected]@@@@[email protected]@@@@@@[email protected]@@@@[email protected]@[email protected]@[email protected]@H    //
//    [email protected]@[email protected]@@[email protected]@[email protected]@@[email protected]@[email protected]@@[email protected]@@[email protected]@@@[email protected]@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@@H    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@M%[email protected]@@[email protected]@@[email protected]@@@@@[email protected]@@@@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@@[email protected]\` [email protected]@@@[email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@@[email protected]@[email protected]@@[email protected]@[email protected]@M^  .~([email protected]@@[email protected]@[email protected]@@[email protected]@@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@@@@[email protected]@[email protected]@HHM^```_:([email protected]@@@[email protected]@@[email protected]@[email protected]@[email protected]@    //
//    [email protected]@[email protected]@[email protected]@[email protected]@M'````(<[email protected]@@@[email protected]@[email protected]@[email protected]@    //
//    [email protected]@@@[email protected]@[email protected]@[email protected]#'      .~~([email protected]@@[email protected]@[email protected]@[email protected]@@@[email protected]    //
//    [email protected]@@[email protected]@[email protected]@[email protected]@HH#` .   ` ~~([email protected]@@[email protected]@@@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@`` .~.``[email protected]@@@[email protected]@[email protected]@[email protected]@    //
//    [email protected]@[email protected]@[email protected]@[email protected]@D`` ...~.`_:[email protected]@[email protected]@[email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@@[email protected]@[email protected]@Mt``....~~~_([email protected]@@[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]@M^``. ..~(([email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]@@@#!``. ([email protected]@[email protected]@@[email protected]    //
//    [email protected]@[email protected]@[email protected][email protected]@@[email protected]@H    //
//    [email protected]@[email protected][email protected]@[email protected]    //
//    [email protected]@@[email protected]@HN,[email protected]@[email protected]    //
//    [email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected] `[email protected]@[email protected]@[email protected]    //
//    [email protected]@HHHHHHHN.``[email protected]@gHHHHpbWMMMN#[email protected]@H    //
//    HHHHHHHHHHHHHHHHHHHM,`.`[email protected]    //
//    HHHHHHHHHHHHHHHHHHHHHp`` ..(llpbbVyffpNMMMN#HHHHHHHHHHHHHHHH    //
//    HHHHHHHHHHHHHHHHHHHHHHh-~.~_1lpbWyyyVMMMM#[email protected]    //
//    #####H#H#H##HHHHHHHHHHHN,.~~(=ppyyyWMMMN#HHHHHHHHHHHHHHHHHHH    //
//    N#M#############HHHHHHH#HL.._=WWyyqMMMM#HHHHHHHHHHHHHHHHHHH#    //
//    N######################HH#N,.(WVVdMMMNN#HHH#H#H#############    //
//    N#######################H##M,_VWMMMMMN#HHHH###M#############    //
//    NM#NNNNN#NNNNNNNN#########NNNmqMMMMMN###NNNN#####N#####NNNN#    //
//    NNNNNNNNNNNNNNNNNNNNN##NNNNNMMMMMMMNNNNNNNNNNNNNNNNNNNNNNN#N    //
//    MMMNMNNNNNNNNNNNNNNNNNNNNNMNMNMMNMMNMNNNNMNNMNNMNNNNNNNNNNNN    //
//    MMNMMNMNNNNMMNMNNMNMNNMMNMNMNNNNMNNMMNMNMNMNMMNMMMMMNNNNNNNN    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract TM is ERC1155Creator {
    constructor() ERC1155Creator() {}
}