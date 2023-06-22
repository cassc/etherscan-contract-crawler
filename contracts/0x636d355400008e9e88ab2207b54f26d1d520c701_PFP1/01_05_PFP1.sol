// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: PhotoFilePhrens Vol.1
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                //
//                                                                                                                                //
//    clllllllllllllllllllllloolloolllloooloooooooooooooooooooollooooooooooooooooooooooooooooooooooooooooooooooooooooollooolll    //
//    cllllccllcclllllllllloooolllolllooooooooooloooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooll    //
//    lllllccllllllllllllllooooolloooooolooooooooooooooooooooooddooodoooooooodooodooooooooooooooooooooooooooooooooooooooollooo    //
//    lclllllllllllllllllllloloooooooooolloooooooodooooddooooooodddddoddodooooooodooododddoooooooooooooooooooooooooooooooooooo    //
//    lcclllllllllllcccloolllllooooooooooooooooooddddoodddddoododddddddddddddoddddodddddddoooooooooooooooooooooooooooooooooooo    //
//    lcccllllolllllllcloolloooooooooooooooooooodddoddooddddoodddddddooddddddddddddddddddddddooodooooooooooooooooooooooooooooo    //
//    llccllllllllcllooloolloooooooooooooooooooooddoddodddddddddddddoodddddddddddddddddddddddddddoddoooooooooooooooooooooooooo    //
//    llllloollllllllolloooooooooooooooooddddoooooddddddddddddddddddddddddddddddddddddddddddddddoodddddooooooooooooooooooooooo    //
//    lllllllllllooloolllooloooooooodoodddodddddddooddddodddddddddddddddddddddddddddddddddddddddooddddddoodooooooooooooooooooo    //
//    llllllloollolloolloooloooooooddddddoooddddddddddodddddddddddddddddddddddddddddddddddddddddddddddddodoooooooooooooooooooo    //
//    cclllcllolooooooloooooooooooooddddooodddddddddddddddddodddddddddddddddddddddddddddddddddddddddddddddoooooooooooooooooooo    //
//    cllllllllcloooooloooloooooooooddddoodddddddddddddddddddddddxxdddddxxdddddddddddddddddddddddddddddddddddodooooooooooooooo    //
//    lllllllllccloooloooooooddoooodddoddoddddddddddddddddddxddddddddxxxxxdddddxdddxxxddddddxdddddddddddddddddooddoooooooooooo    //
//    llccloooollloooooooooooddoooddddddddoodddddddddddddddddxddxddoddxxdxxxxddxddxxxxxddxxxxxdddddddddddddddddooddooooooooooo    //
//    lllllllooooooooooooooodddodddddddddddddddddddddddddxxxxxxddxxdddxxddxxxxdxxddxxxdddxxxxdxdddddddddooddooddddddoooooooooo    //
//    olcclooooooooollllooooddddddooddddddddooodddddxxxdddxxxxddddddxxxxdxxxxxxxxxxxxxxdxxxddxxxdxxdddddddddddoodddddooooooooo    //
//    lllclllllloooolcccclllllclllllloooddddollloddddxxxdddxxxdxxddddxxxxxxxxxxxxxxxxxdxxdddddxxxxxddddddddddddddddddooooooooo    //
//    lllloollllooolloooollllccc:ccccccllooddddolloodddddxxxxxxxxxxdodxxxxxxxdxxxxdxxddxxddxxdxxxxxdddddddddddddddddddoooooooo    //
//    olllloollloollloooodddddddoollllcccllllollloollloodxxxxxdxxxxxddxxddxxdddxxxxxxxxxxxxxxxxxxxxdddddddddddddddddddddoooooo    //
//    lllllloooooooooooooodddddddddoodoollllollooollllllllloooollooooodxxxxxxdxxxxxdxxxxxxxddxxxdxxddxdddddddddddddddddddooooo    //
//    lloollooooooodddddoddoodddddddddddddolllcllllodolodddddlc:::::::cldxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddddooddooooo    //
//    llollloooooooddddddddooddddddddddddddddxddolllloooolloooc:cccc::::cldddxxxxxxxxxxxxxxxxxxxxxxxdxxxxdddddddddddddddddddoo    //
//    oooolooooooodddddddddoodooodddxxdddxdddxxdxxddoollooolcc:::;:::c::::cdxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddddddddddooo    //
//    oooooloooooodddddddddddddddddddxxxddddddxxxxddxxdolodddlc:c::::::::::lxddxxxxxxxxxxxxxxxxxxxxddxxxxxxddddddddddddddddddo    //
//    ooooolloooooododdddddddddddddddxxxxdxddxxxxxddxxdddollool:::;::ccc::coxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxdddddddddddooddddo    //
//    oolooolooooolodddddddddddddddddxxxxxxdddxxxxxxxxdoodddolcc:::::::::::loodxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxddddddddddoooood    //
//    ollooooooooooodooddddddddddoodxxxxxxxxdddxxxxxxxxddxxxxdolc::::;::::clllooooddxxxxxxxxxdxxxdxxxxxxxdddddxdddddddddddoooo    //
//    ooollloooooddddooooodddddxdoodxxxxxxxxxdxxxxxxxxxxxxxxxddoc::::;;:::lllllodddooooodddxxdooooloddxxxdddddxddddddddddddddo    //
//    olllllooooooddddooooddddddxdoddxdxxxxddxxxxxxxxxxxxxxxxdddoc:::::ccldxdolllodxxddolloolc::::clooodxxddxdxxdddddddddoddoo    //
//    llloooooooooddddooodddddodxdodddodxxddddxxxxxdxxxxxxxxxxxddolc:cllddxxxxxxxoooooodoodoc:::::::odlldxxxxxdddddddddddddddd    //
//    lllooooooolodddddoodddddddxdodxxddxxxdddxxxdxxdxxxxxxxxxxxxddddddxdxxxxxxxxxxxdooooollc:::::::ldddodxxxxdddddddddddddddd    //
//    llooooooollllloddooddoddddddddddxxxxxdoodxxddxxxxxxddxxxxxxxxxxxxddxxxxxxxxxxxxxxxxdoc::::::::cddddddddddddddddddddddood    //
//    oolllooooooollooddoddddddddddxdddxxddddoddxxxxxxxxxxdxxxxddxxxxxxxxxxxxxxxxxxxxxxddxxoc::::::;coddxxxxxdddxdxddddddddddd    //
//    olllloloodddoddooooooddddddddxxdddooollooodxxxxddddxxxxxxdddxxxxxxxxxxxxxxxxxxxxxxxxxdoc:::::codddxxxxxxxxdddddddddddddd    //
//    lllloooooodddddddddddddddddxdddddxxdddddooooooollcllooodddddddxxxxxxxxxxxxxxxxxxxxxxxxddlc:clddddddxxxxxxxdddddddddddddd    //
//    olloolloooodddddddddddddddddxdddxxxdddxxxxxxddolc:::;;::cloooodxxdxxxxxxxxxxxxxxxxxxxxxddoodddxdddddxxxxddddddddddddddod    //
//    ooooolloddoooddddddddddddddxxddddddxxddxxxxxdolc::::::cc::lllcodxxxxxxxxxxxxddxxxxxxxxxxxxdxxxdxxxxxdxxxxxxxdddddddddddd    //
//    oooollllooddooooddddddddxdddxxxxxddxxddxxxxxdoolc:::::::::::ccllllooddddxxxxddxxxxxxxxxxxdxxxxxxxxxxxddddddddddddddddddd    //
//    oooooolloodddooooodoodddxxdddxxxxxddxxddxxxxxxxxdoocc:;;:::::::::::;:ccclloolodxxxxxxxxxxxxxxxxxxxxxxxdddddddddddddddddd    //
//    oooooooooddoodddooooododdxxxddxxxxdddxxxxxxdxxxxxddoolc:::::::cc:c::::::::::ccclloddxxxxxxxxxxdddxxxddxxxxdddddddddddddo    //
//    ooooooooooddddddolooddooddddxxxxxxxxdxxxxxxdoddxxxxdoool::;;::ooooollllc:::::::::::cclldddddxxxxdxxxxxxxdddddddddooddddd    //
//    lloooloooooddddddooddddddddxxddxxdxxdxxxxxxxddxxddxxddddl::;;:lxxxxxxdddollllcc:::::::::lllodddddxddxdddddddddddddddddoo    //
//    lloooloooloddoodddoodddddooddddxxxddooxxxxxxxxxxdxxxxxddocccc:coddxxxxxxxxdxdddolc::;;:::::clodddddxxxddddddddddddddddoo    //
//    looooooloooddooooddddddddddddddxxxxddddddxxxddxxddxxxxxxdl:::::looddxxxdddxxxxxxxdollllcc:::;coddddddxdddddddddddddooddo    //
//    llllooollooddddooooddddddddddddddxxxxxxxddxxxxxxxxxxxxxxdoc::::ldxxxxxxxxxxxxxxxxxxddddool:;:codddxdddddddddddddoooddooo    //
//    oolloooolllooddooooodddddddddddddddxxxxxdddxxxxxxxddxxxxxdl:::::ldxxxxxxdxxxxxxxxxxxdddddo::coddddxxdddddddddddddddddooo    //
//    lllooooooooloooolooooodddddddddddodddxxddxddxxxxxxxxxxddddl;;;:::oxxxxxxxxxxxxxxxxxxxdddoc:coddddddddddddddddddddddddooo    //
//    ollooooooodddodoooddoooddddddddddodddxxxxxddxxxxxxxdxxddddo:;;;;;:odxxxxxxxxxxxxxxddddoc::clddddddddddddddddddddddoooooo    //
//    ooollooolloooddoooodddddddooddddddoddxxxxxdxxxxdxxxxxxddddddolc::::odddxdxxxxxddddddol:::codddddddddddddddddddddddoooooo    //
//    oollooooooooooooddoooddddddddddddddoddxxxdoddxxdddddxxxxddddddc;::::loddddxxxxddddl::;;:loddddddddddddddddddddddddoooooo    //
//    llllooollooooooooodoodddoodddddxddoooodddxxxxdddxddddxxxxxddddl::::::clodddddoolcc::::cloddddddddddddddddddddddooooooooo    //
//    llcloooollooooooooooooooooddddddddddddddddxxxxdxxddddxxxxxxxdddoccc:::::::::::;;;;::coooodddxxdddddddddddddddddoddoooooo    //
//    llllllolllooooooddoooooooodddddddddddddddddddddddddddddddxxxxxxddolc:;;;::::::;:::codddooddddddddddddddddoddooddoooooooo    //
//    lloooloolllooooooddoooooooddddddddddoddddddddxddxxxddddddxddxxdddddoolc:::::ccllodddddddddddddddddddddddddddoooooooooooo    //
//    clloooooollloodooooooddooooddddooddddddddddddddddxxxdxxxdxxdddddddddddddoooodddddddddddddddddddddddddoooddddoooooooooooo    //
//    lllllllloolloooooooooodddooddddooddoooddxxdddddxxddddddxddxxxddddddddddddoodddddddddddddddddddddddddddoodooooooooooooooo    //
//    lllllllllooooooollloooooddooddddddddddooddddddddddddddddddxxxxxxddxdddddddodddddddddddddddddddddddddddddoooooooooooooooo    //
//    llolllllllloooooooolooloodolloodddddddddddddddddddxdddddxxxxxxxxxddddddddxdddddddddddddooddddddddddddooooooooooooooooooo    //
//    ccllooollclloooooooooooloooooooooodddddddodddddddddddddddddxxxdddddddddddddddddddddddddooooooddddooodooooooooooooooooooo    //
//    lccllllloloollooooooddoooloddddddddoddddddddddddddddddddddddddddddxdddddddddddddddddddddddddddooooooodoooooooooooooooooo    //
//    lllllcccllloollloooooddooooooddddddddddddddddddddddddddddxddddddxxddddddddddddddddddddddddoodooooooooooooooooooooooooooo    //
//    llllllcccclllllllllloooooooolloddddddddddddddddddddddddddddddddddddddddddddddoodddddddoddddddddoooooooooooolooooooolllll    //
//    cllollllllllllllllllloolloooolloooooddddooddddddddddddooddddddddddddddddddooddddddddddooddoooodddoooooooooooooololllllol    //
//    cclllllllllllollllllllooooooooooooooooddoodddddddddddddoddddddddddddddddddddddddddddddoodddooooooooooooooooooooooolllllo    //
//    ccclllllllllllllloooollloooooooddddddooooooooodddoodddddoodddddddddddddddddddddooooddddooooooooooooooooooooooooooollllll    //
//    llllcllllccllllccllooolllooooooooooooooooodddddddddooooddddddddddddddooddoooooddddddddooooooooooooooooollooooollllllllll    //
//    ccllllllllcclllllllloolllllloollooooooooooddddddoddooooooddooooooddddooddoodddoooooooooooooooooooooooooooollllolllllllll    //
//    ccclllllllllllllllllooollollllllooooollooooooooooooooddoodddooloooooooooodddooooooooooooooooooooooooooooolllllllllllllll    //
//    ccccllllllllllllcccllloolloooollloooolloolllooooooooooooooooooooooooooooooooooooooooooooooooooooooooolooolllllllllllllll    //
//    lllllcllllllllllllccllloolcllollllooooooooolooooodooooooooooooooooooooooooooooooooooolooolloooooooooooloolllllllllllllll    //
//    llllllcccllcclllllllccllllllllllloooooooooooooollooooooooooooooooooooooooooooooooooooolooooooollllllllllllllllllllllllll    //
//    ccclllcccclccllllllllllllllooollccllolllllllloooooooooooooooooooooooooooooooooooooolooooooooolllllllllllllllllllllllllll    //
//    ccccccccccllllllccllllllllllllollccllloollllllllollooolllooooooooooloooooollooooooooooloolllloolllllllllllllllllllllllll    //
//    ccccccccllllllllccclllclllccclllllllllooooollolloooolllllllooolooooollooooolloolllloolllllllllollllllllllllllllllllcclll    //
//    ccccccccccccccllllclllcclllllcllllllllllloollolloooollllloooolllooooooooooolloollllllllllllllllllllllllllllcllllllcccccc    //
//                                                                                                                                //
//                                                                                                                                //
//                                                                                                                                //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract PFP1 is ERC721Creator {
    constructor() ERC721Creator("PhotoFilePhrens Vol.1", "PFP1") {}
}