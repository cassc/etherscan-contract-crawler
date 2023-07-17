// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: VICTORESTEVESeditions
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                                                                                            //
//                                         ?5YYYYYYYYYYYYYYYYYYYYYYYYYY:                                      //
//                                         [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@^                                      //
//                                     JGGP&@@@J~~~~~~~!!!!!!!!!!!!#@@@GGGGGGGGGGGP.                          //
//                                     [email protected]@@@@@@~                   [email protected]@@@@@@@@@@@@@@^                          //
//                             Y#BB####&@@@7:^^.       ........:::::^^^^^^^^^:^#@@@#BBB:                      //
//                             [email protected]@@&&&&&&&&~        .......:::::^^^            G&#&@@@@:                      //
//                             [email protected]@@7 .......       :^^^::::::::::::^^^^^^^^    ...:#@@&:                      //
//                         :^^^[email protected]@@!               :^^^::::....:::::^^^^^^^. ..    #@@&!^^^                   //
//                         [email protected]@@@@@@J^^^::::.       .:::................::::^^^^   .#@@@@@@&:                  //
//                         [email protected]@@BPPP7^^^:.::.       .:::::::............::::::::    YPPP&@@&:                  //
//                         [email protected]@@!   .^:::...        ::::^^^^^^^^:...........            #@@&:                  //
//                     [email protected]@@7   :::::.... ..    ............!?777777^:::.          .#@@&:                  //
//                     [email protected]@@@@@@7   :::::.......                5BGGGGGG~:::....       .#@@&:                  //
//                     [email protected]@@5777^   :::::::::...    !???????????PGGGGGGGYJJJ:...       .#@@&:                  //
//                     [email protected]@@!    .. ::::^^^^:...    YBGGGGGGGGGGGGGGGGGGGGGG^ ..       .#@@&:                  //
//                     [email protected]@@7       ........    ?YYYPGGGGGGGGGGGGGGGGGGGGGGG5YYY.      .#@@&:                  //
//                     [email protected]@@7        ...        YGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG:      .#@@&:                  //
//                     [email protected]@@7               ?P55!^~~~~~~5GGGGGGGGGGG!^~~~~~~PGGG:   G###@@@&:                  //
//                     [email protected]@@7               YBGG7~~~^:::5GGGGGGGGGGG!~~~::::5GGG:  .#@@@&##B:                  //
//                     [email protected]@@7   :^^^.       JGGG#&&@~   YGGG5555PGGG&&&&^   5GGG:  .#@@&^...                   //
//                     [email protected]@@7   ::::....    JGGG#&&&7:^:5GGG5555PGGG&&&&!::^5GGG:  .#@@&:                      //
//                     [email protected]@@7       :^:^.   JGGGGGGGGGGGGGGG5555GGGGGGGGGGGGGGGG:  .#@@&:                      //
//                     [email protected]@@7       ~777^...YGGGGGGGGGGGGGGG5555PPPPGGGGGGGGGGGG:  .#@@&:                      //
//                     [email protected]@@!       YBBB7^^^YGGGGGGGGGGGGGGG5Y555YY5PGGGGGGGGGGG:  .#@@&:                      //
//                     [email protected]@@PJJJ^   !???~^^^YGGGGGGGGGGGGGGGPPPPPPPPGGGGGGGGGGGG:  .#@@&:                      //
//                     [email protected]@@@@@@7   ....^^^^5BGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG:  .#@@&:                      //
//                     [email protected]@@7   ....^^^^7??75GGG7~~~7???????????PGGGGGGG?7?7.  .#@@&:                      //
//                         [email protected]@@!       :~^^^^^^5GGG^   :^^^^^^^^^^^5GGGGGGG!^^^   .#@@&:                      //
//                         [email protected]@@BGGB~   .:::^^^^!7!7^:^^............!7!!!!!!~^^^   .#@@&:                      //
//                         [email protected]&&@@@@7 ......^^^^^^^^^~^~.           ^^^^^^^^^^^^   .#@@&:                      //
//                         .:::[email protected]@@&###~   :^^^^^^^^^^^YPPPPPPPPPPP!^~~^^^^^^^^    #@@&:                      //
//                             Y&##@@@@!   ^!~~~^^^^^^^YPPPPPPPPPPP!^~~^^^^^^^^:::^#@@&:                      //
//                              .. [email protected]@@!   JGGG!^^^^^^^~~~~~~~~~~~~~^^^^^~^    [email protected]&&@@@@:                      //
//                                 [email protected]@@!   JGGG?!!!^^^^^^^^^^^^^^^^^^^^^^^^^~~~#@@@BGGG:                      //
//                                 [email protected]@@!   JGGGGGGG^                       [email protected]@@@@@@:                          //
//                         [email protected]@@!   JGGGGGGG7~~~.   !777777777777777#@@@P555.                          //
//                         [email protected]@@@@@@@@@@!   JGGGGGGGGGGG^   [email protected]@@@@@@@@@@@@@@@@@@:                              //
//                     [email protected]@@PJJJJJJJ:   JGGGGGGGGGGG^   7JJJJJJJ#@@@@@@@YJJJ.                              //
//                     [email protected]@@@@@@!           JGGGGGGGGGGG^           [email protected]@@@@@@:                                  //
//             7P555555#@@@Y!77^.......    JGGGGGGGGGGG^   ........!777#@@@P5555555.                          //
//             [email protected]@@@@@@@@@@!   .:::::::.   JGGGGGGGGGGG^   ::::::::    [email protected]@@@@@@@@@@:                          //
//         ?BGG&@@@Y^~~~~~~.       ::::.   YGGGGGGGGGGG^   ::::.       ^~~~~~^~#@@@BGBG.                      //
//         [email protected]@@@&&@7               .:::.   JGPPGGGGPPPP^   ::::                B&&&@@@@^...                   //
//         [email protected]@@J.::::::::::::::.   .::::::::...YGGG~...::::::::    ::::::::    ::::#@@@###B:                  //
//         [email protected]@@7   .^::::::::::.   .:::::::.   ?P5P^   .:::::::.   ::::::::.       G###@@@&:                  //
//         [email protected]@@?   .:::::::::::::::.       ::::.   ::::.       ::::::::::::::::     . .#@@&:                  //
//         [email protected]@@?   .:::::::::::::::. .......:::.   .:::. ......::::::::::::::::....   .#@@&:                  //
//         [email protected]@@?   .:::::::::::::::::::::::.   ::::    ::::::::::::::::::::::::::::   .#@@&.                  //
//         [email protected]@@?   .:::::::::::::::::::::::............::::::::::::::::::::::::::::   .#@@&?777.              //
//         [email protected]@@?   .::::::::::::::::::::::::::^    :^::::::::::::::::::::::::::::::   .&@@@@@@&:              //
//         [email protected]@@?   .::::::::::::::::::::::::::::...::::::::::::::::::::::::::::::::    7J?J&@@&:              //
//         [email protected]@@?   .::::::::::::::::::::::::::::^^^::::::::::::::::::::::::::::::::        #@@&:              //
//                                                                                                            //
//                                       Editions By VicToR EsTeVeS                                           //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract VEed is ERC1155Creator {
    constructor() ERC1155Creator("VICTORESTEVESeditions", "VEed") {}
}