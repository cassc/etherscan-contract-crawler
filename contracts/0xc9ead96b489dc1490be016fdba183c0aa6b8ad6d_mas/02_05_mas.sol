// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: マStudio
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////
//                                                                    //
//                                                                    //
//    MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM#MMMMMM    //
//    MMMMMMMMMMMMMMMMMMMMMMMMHHHHHHMMMMMMMMMMMMMMMMMMMMMMMHMMMMMM    //
//    [email protected]@[email protected]@[email protected]@HMMMMMMMMMMMMMMM#MHHmMMMM    //
//    [email protected]@[email protected]@[email protected]@[email protected]@HHHMMMMMMMMMMMMMMHMHMMMH    //
//    [email protected]@@[email protected]@[email protected]@[email protected]@[email protected]@HMMMMNMMMMMM#MmMMHNH    //
//    [email protected]@[email protected]@[email protected]@[email protected]@[email protected]@@HMHHHMMMMMMMMMMMMMHMMH    //
//    [email protected]@H#[email protected]@[email protected]@[email protected]@[email protected]#HMMHHMMq    //
//    [email protected]@[email protected]@[email protected]    //
//    [email protected]@[email protected]#[email protected]@HMMHMmqMmHmmqHMmmHMHMMMMMMMNM#HMH    //
//    [email protected]@[email protected]@[email protected]@    //
//    MMM#[email protected]@#[email protected]@@    //
//    [email protected]@@[email protected]@MMM    //
//    [email protected]@HMMSdRltl==<(t,1= [email protected]@HMHMMMMM9    //
//    [email protected]@[email protected]=>.`.C`.([email protected]    //
//    [email protected]@HMMKUNylz!``..! ,"!,8dY"^`(UHHqqqMP([email protected]    //
//    [email protected]<.````````.!````..`[email protected]    //
//    gHMMMMMMMRdNMMMMMM-.``.```````.```.`JHkqqHMHmmMHmMHMMNHkXQgM    //
//    [email protected]=._```````.``````.`.HHqqHMMMmMMmHHmMHqmHHHN    //
//    HUWHXXZUkHQkdd"!`.```.``.````.``.``[email protected]    //
//    SwXXu0ZZXWHHh_...``....```.```.`.....([email protected]@MMM    //
//    XUOlWXwWWQgMNp...JMD?~ .``.`.``.`.`.(#MHMHMHHHHH#HNMmqHgMMMM    //
//    dHkkHNMMMMMMMMp(MM~.``.``...`..`..Jg#dMHHHHMWMMWt,[email protected]@H    //
//    [email protected]@@@[email protected]```.`/(3Wh...+gMMIlHHMNJMp?:[email protected]    //
//    NN#[email protected]@[email protected]`.;.K;>9mdMMM9lv1W3+dHdMp!,+<,[email protected]    //
//    [email protected]`.SJ??dMM9O=>..(2???HMMe,(?<WWkHHkqqH    //
//    @[email protected]@MMqqHMMM#3```.4>?d9I=v!``..S>>??7MNm;??WYYHHNHqH    //
//    HMMpWHMMNHMMMMNHbMD1;<.. `.b11?k=>..` {,m&x???7WNkTT<+v .TMM    //
//    [email protected]@MMMHM9TMHMP>zgJ17^.Ruz???x.```{`.1=zOTTO?Mka..````(H    //
//    [email protected]@H5==vTzdHHD;<1. ` (D;<7OI?Z+, <``.(+-~`.=/(4WHg,.``X    //
//    ?HHWWHHM6===?1<dN#<`  ., .C:+J=<;;z``-<``,```` ?4,` zWHHWW+j    //
//    dHDzyyyK==??<j(H#^   ` .,c(7=?~-..,_```. ```.```` =-.?dOHHHH    //
//                                                                    //
//                                                                    //
////////////////////////////////////////////////////////////////////////


contract mas is ERC721Creator {
    constructor() ERC721Creator(unicode"マStudio", "mas") {}
}