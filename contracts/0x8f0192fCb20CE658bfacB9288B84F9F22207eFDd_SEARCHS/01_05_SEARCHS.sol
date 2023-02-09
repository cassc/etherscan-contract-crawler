// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: search-marks
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
//        AFFILIATE MARKETING & E-COMMERCE Brought to you by (E-SEARCH MARKS LABS & PARTNERS)                                                                                                                                     //
//    '  sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss    //
//    '  sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss    //
//    '  sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssshhhhhhhssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssskkkkkkkksssssssssssssssssssssssss    //
//    '  ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssh:::::hsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssk::::::ksssssssssssssssssssssssss    //
//    '  ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssh:::::hsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssk::::::ksssssssssssssssssssssssss    //
//    '  ssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssh:::::hsssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssk::::::ksssssssssssssssssssssssss    //
//    '  sssssssssssssssssssseeeeeeeeeeeesssaaaaaaaaaaaaasrrrrrsssrrrrrrrrrssssssccccccccccccccch::::hshhhhhsssssssssssssssssssssssssssmmmmmmmssssmmmmmmmssssaaaaaaaaaaaaasrrrrrsssrrrrrrrrrssk:::::ksssskkkkkkkssssssssssssss    //
//    '  ssss::::::::::ssssee::::::::::::eesa::::::::::::ar::::rrr:::::::::rssscc:::::::::::::::h::::hh:::::hhhssssssssssssssssssssssmm:::::::mssm:::::::mmssa::::::::::::ar::::rrr:::::::::rsk:::::ksssk:::::kss::::::::::sss    //
//    '  ss:::::::::::::sse::::::eeeee:::::eaaaaaaaaa:::::r:::::::::::::::::rsc:::::::::::::::::h::::::::::::::hhsssssssssssssssssssm::::::::::mm::::::::::msaaaaaaaaa:::::r:::::::::::::::::rk:::::kssk:::::ss:::::::::::::ss    //
//    '  s::::::ssss:::::e::::::essssse:::::essssssssa::::rr::::::rrrrr::::::c:::::::cccccc:::::h:::::::hhh::::::hss---------------sm::::::::::::::::::::::mssssssssssa::::rr::::::rrrrr::::::k:::::ksk:::::ks::::::ssss:::::s    //
//    '  ss:::::ssssssssse:::::::eeeee::::::esaaaaaaa:::::ar:::::rsssssr:::::c::::::cssssscccccch::::::hsssh::::::hs-:::::::::::::-sm:::::mmm::::::mmm:::::msssaaaaaaa:::::ar:::::rsssssr:::::k::::::k:::::ksss:::::ssssssssss    //
//    '  ssss::::::sssssse:::::::::::::::::eaa::::::::::::ar:::::rsssssrrrrrrc:::::cssssssssssssh:::::hsssssh:::::hs---------------sm::::msssm::::msssm::::msaa::::::::::::ar:::::rsssssrrrrrrk:::::::::::kssssss::::::sssssss    //
//    '  sssssss::::::ssse::::::eeeeeeeeeeea::::aaaa::::::ar:::::rsssssssssssc:::::cssssssssssssh:::::hsssssh:::::hsssssssssssssssssm::::msssm::::msssm::::ma::::aaaa::::::ar:::::rsssssssssssk:::::::::::ksssssssss::::::ssss    //
//    '  ssssssssss:::::se:::::::essssssssa::::assssa:::::ar:::::rsssssssssssc::::::cssssscccccch:::::hsssssh:::::hsssssssssssssssssm::::msssm::::msssm::::a::::assssa:::::ar:::::rsssssssssssk::::::k:::::ksssssssssss:::::ss    //
//    '  s:::::ssss::::::e::::::::esssssssa::::assssa:::::ar:::::rsssssssssssc:::::::cccccc:::::h:::::hsssssh:::::hsssssssssssssssssm::::msssm::::msssm::::a::::assssa:::::ar:::::rssssssssssk::::::ksk:::::ks:::::ssss::::::s    //
//    '  s::::::::::::::sse::::::::eeeeeeea:::::aaaa::::::ar:::::rssssssssssssc:::::::::::::::::h:::::hsssssh:::::hsssssssssssssssssm::::msssm::::msssm::::a:::::aaaa::::::ar:::::rssssssssssk::::::kssk:::::s::::::::::::::ss    //
//    '  ss:::::::::::sssssee:::::::::::::ea::::::::::aa:::r:::::rssssssssssssscc:::::::::::::::h:::::hsssssh:::::hsssssssssssssssssm::::msssm::::msssm::::ma::::::::::aa:::r:::::rssssssssssk::::::ksssk:::::s:::::::::::ssss    //
//    '  sssssssssssssssssssseeeeeeeeeeeeeesaaaaaaaaaassaaarrrrrrrsssssssssssssssccccccccccccccchhhhhhhssssshhhhhhhsssssssssssssssssmmmmmmsssmmmmmmsssmmmmmmsaaaaaaaaaassaaarrrrrrrsssssssssskkkkkkkksssskkkkkksssssssssssssss    //
//    '  sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss    //
//    '  sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss    //
//    '  sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss    //
//    '  sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss    //
//    '  sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss    //
//    '  sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss    //
//    '  sssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss    //
//          $$$$ CREATED AND OWNED BY ESEARCH MARKS LABS                                                                                                                                                                          //
//                                                                                                                                                                                                                                //
//                                                                                                                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract SEARCHS is ERC721Creator {
    constructor() ERC721Creator("search-marks", "SEARCHS") {}
}