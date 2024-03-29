// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: ANIMAL-HOOD
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                            //
//                                                                                            //
//     █████╗ ███╗   ██╗██╗███╗   ███╗ █████╗ ██╗      ██╗  ██╗ ██████╗  ██████╗ ██████╗      //
//    ██╔══██╗████╗  ██║██║████╗ ████║██╔══██╗██║      ██║  ██║██╔═══██╗██╔═══██╗██╔══██╗     //
//    ███████║██╔██╗ ██║██║██╔████╔██║███████║██║█████╗███████║██║   ██║██║   ██║██║  ██║     //
//    ██╔══██║██║╚██╗██║██║██║╚██╔╝██║██╔══██║██║╚════╝██╔══██║██║   ██║██║   ██║██║  ██║     //
//    ██║  ██║██║ ╚████║██║██║ ╚═╝ ██║██║  ██║███████╗ ██║  ██║╚██████╔╝╚██████╔╝██████╔╝     //
//    ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═════╝      //
//                                                                                            //
//                                                                                            //
//                                                                                            //
//        !░ ╟▌     █▀██▓▓▒ ╟██⌐   .░░║████▌░┤│└╙╙▀▀█▓▄▄ ▌ '.░░▒▒█████████████████████████    //
//        '~ ╫▌     █░░└╙██████⌐   ¡░░░████▌░░░░░░░░█∩`╙▀█▓▄▄¡░▒╠██████░▒▒╚╬██████████████    //
//          .█▌ ...j█∩'  █  ███   '¡░░║████▌░'│░░░░░█░.  ▌ └╙██▓▒██████▓▄╦ê╬╬╬╬▓█████╬╬╬╬╬    //
//        ▓▓▓██▄╓  j█░   █  ▓███████████████▄▄,'!░░░▓∩│┌;▌░░░▌░╬██████████████████████████    //
//        '  ╫▌╙╙▀▀██Æ▄▄,█  ███████████████▌   └╙▀▀╪█│││░▌░░░▌░░╠█████████████████▒⌐╠╟████    //
//           ╟▌    ▐█⌐  └█▀▀███   ¡░│░░████▌       .▌░░░░█░░░▒░░╠█████████████▓╬██▒⌐│█████    //
//           ╟▌    ▐█    █  ███   '░░░▐████▌       ¡▌▄▄▄░█░░░▒░░╠███████████╣▓▓▓╣╬▓█▓█████    //
//           j▌    ╞█    █⌐ ███   '░░░║█████      '¡▌░░░│█▀▀╣▒▄░▒█████████▓▓▓▓▓▓▓╣▓███████    //
//        .  j▌.   ╞█    ╫¬ ███   '░░░╟█████#═w▄▄;¡░▌░╣╣▓█▓╬▒▒░│╬████████▓▓▓╣█╬▌╠█╣██╬████    //
//        ▀▀Æ▓█▄▄▄µ▓█    ╫⌐'███   '░░░▐████▌░░~'¡░││▓░╟▓██▓▓╬▒░░▒███████▓▓▓▓╣█████▓██╬████    //
//          ¡║▌ '  ╟█╙╙▀▀▓▄▄███   '░░░▐█▓▀▀▀░░'."²░>╡Å╣▓▓██▓╬▌░░▒██████▓▓▓▓▓╬█████▓██▓████    //
//         ..▐▌    ▐█    ╫⌐└███   '¡░┘   ,»Γ,≥µ''¡(;╡≤╠▒╠╬╠╠░▒!│░╠╬╬╬╬▓▓▓▓▓▓▓▓▓▓▓▓▓██▓████    //
//         ¡'▐█    ╟█    ╫⌐'███    └Ç ,é└ ╗▒ j   '└░╠╚╠╠╠╬╠╬░▒¡░░╫╬▓╬╬╬▒╠╬▓▓▓╬╬╠╬╣███▓▓▓▓▓    //
//        '' ▐█'.  ╟█⌐   ╟⌐ ███      ╙▓b ╣╬> ⌐     !╫╠╠╬╬╣╬╬▒Γ▒Γ▒╫╬╬╬╬╬╬╠╠╠╬██▓▓███╣█▓╣▓▓▓    //
//        .: ▐▌┌¡~.╞█µ,,▄╫▒▄██Γ       "╢▄╠▄▄≥.   .¡░╬░╠╠╣╣╬╠░░░░░╬╬╬╬╬╬▒╠╠╠╠╣╬╬██████╬╣▓╣▓    //
//         ' ▐▌│░┐.╞█└└└└█▌└╠.          '└└   ┌¡;░░▒▓╠╬╬╬╣▒▒░░░░░╣╬╬╬╬╬╬╬╬╬╠╣╣╝╣╬█████▓███    //
//        .¡,╣▌µ░░'╫█   '█⌐ ╠▒╔  ó      ,▄▓█▌▐░▒░╟▓▓██╬╬╣╬╣╬▒░░░░╣╬╬╬╬╬╬╬╠╬╠▓╬╠╜╫▓╬███╣███    //
//        ▓▓▓▓▓▓▓~'╫█    █▌ ▐▓╬╬╬▓▒, ,.▓████]▒░░╣▓▓█████╬╬╣▓▓▓▒▄╗╬╬╬╬╬╬▒╬╬╠╠╩║▒╣╣╬╣╣██╬▓██    //
//        ▓████▓▓▓ ██⌐   █▒.j█╬╫▓╬╬▓▓╣▒╠╫█▀ ╟████████████▓▓▓▓▓▓╣╬╣╣╬╬╬╬╬╬╝╠▒╠╣╣╣╣╣╣╣╣╣█▓▓▓    //
//        ███▓██▓▓▓██.¡  █▀   7╠╬╬╢▓╬╬▓▓▓╬▓╣███████████████╬▓▓▓▓╣╣╬╣╬╬╠╬╠╠╬╬╠╠╬╣╣╣╣╣▓▒╣▓▓▓    //
//        ███████▓▓██⌐░' ^╓;=   ╚╬╢███████████▓██████████████▓╬╬╬╬╬╬╜╠╠╬╬╬╬╬╠╬╬╬╬╬╠╠╬╠╠╫▓╣    //
//        ███████████▌░; j▒⌐  '.░╠╬███████████████████████████╬╬╬╝╠╬╬╬╬╬╬╬╬╬╠╬╬╠╬╠╠╠╣▒╠╠▓▓    //
//        ████████████▒▐  ╠░░ ;∩░░╠╫███████████████████████████╬▄▓╬╬╬╬╬╬╬╬╬╬╠╬╬╬╠╠╠╠╣╬╠╬▓▓    //
//        ███████████▀░░░ ░╠░░,░░╠▒╢████████████████████████▀▄▓███╬╬╬╬╬╬╬╬╠╠╬╬╬╬╬╬╬╬▓╬╠╟╬▓    //
//        ██████████Ü]░⌠Ç"░╫▒▒▒▒▒╬▒╬╬█████████████████████▓▓███████╬╬╣╣╬╬╬╬╬╬╬╬╬╣╬╬╬▓▒╠╫▓▓    //
//        ██████████ ^▒   ░░╬╬╬╬╬╬▒╙╙╙▀██████▓▓▓▓▓█████▓▓████████▓▓▓█╬╬╣╬╬╬╬╬╠╠╬╬╬╬╬▓╬╢▓▓╬    //
//        █████████▒∩'╙░  "░▒╬╬╬╬█▒░░┌' ╙▀▀▓▓▓▓▓█▓▓█▀▄████████▓▓▓▓▓▓▓▓▓╬╣╬╬╬╬╬╬╬╬╬╣╣▓▓╬▓▓▓    //
//        █████████░▒  ^'  ⌡╚╠╬╬╬████▓▄▄µ░  `"<,,≡╓@▓▓▓▓▓▓██▓▓▓▓▓▓▓▓▓█▓▓▓╬╬╬╬╬╬╠╬╬╬╣▓▓▓███    //
//        ████████▒░└░    ;▒░╠╬╬╣█████▓▓▓▓▓▓▄░  ╠░▒╣▓██▓█████▓▓▓▓▓▓██▓▓▓▓█▓▒╬╬╬╬╬╬╣╣▓▓████    //
//        ████████▒░░░░,.;;╚╠╠╬╬╣████▓╬▓▓▓▓▓▓▓▒▒▓█▓▓▓▓▓▓▓▓▓▀╙╙▀╬█▓▓▓▓▓▓▓▓▓▓▓▓╬╬╬╬╬╬╬╬╣████    //
//        ██████████▓▓▓▄▒▒▒▒╠╠╬╬╫█████╣█▓▓██▓▓▓████▓█████Γ.╔╣▓▓▓╣╬▓▓▓╣▓▓▓▓▓█████╬▓╬╬╬█████    //
//        █████████▓███████▓▓▓╬╬███████╬╬╬╬▓██▓▓▓▓▓▓▓▓▓▓▓]╣╢▓▓▓▓▓╚` ╙╙╠╬╬▓████████▓╬██████    //
//        █████████▓███████████████████▓▓▓▓▓█▓▓▓▓▓▓▓▓▓▓▓▓▒▓▐███▌⌐      ╚╠╬▓╬██████████████    //
//        ██████████████████████████████▓▓▓▓▓██▓▓▓▓▓▓▓▓██▓█▌▓▓▓▌▐██▄   ;╠╢▓▓██████████████    //
//        ████████████████████████████████████████████▓▓▓▓▓████▓▒╙█▀▒░░▒╬╣╬▓██████████████    //
//        ████████████████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓Γ  ,▒╫▓╣╨╠╬▓██████████████    //
//        ███████████▓█████████████████████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓██▓▓▓╣▓▓▒▓╬▓▓▓█████████████    //
//        ████████████▓▓████████████████████▓▓████▓▓▓▓▓▓▓▓▓▓▓█████████▓╬╬╬▓███████████████    //
//        █████████████████████████████████▓▓▓▓▓▓████▓▓▓▓▓▓▓█████████▄╬╬╣▓█████▓██████████    //
//        ████████████████████████████████▓▓▓▓▓▓▓▓▓████████▀│░░╚▀████╬▓▓████████████▓█████    //
//        ████████████████████████████████▓▓▓▓▓▓█▓▓▓▓▓▓▓▀▀│░░▒╠▒▒╠▓▓╬╣▓███████████████████    //
//        ██████████████████████████████████████▓▓▓▓▓▓▓░░░, ╠╬╬╬╬╬╬▓▓▓████████████████████    //
//        ██████████████████████████████████████▓▓▓▓▓▓█░╚╚▒▒╫█████████████████████████████    //
//        ██████████████████████████████████▓▓▓███▓▓▓▌│░░▒╠▓██▌╬╬╬╫███████████████████████    //
//        ████████████▓▀█████████████████████▓▓▓▓▓▓▓▀░▒▒▓██████▒╬╬████████████████████████    //
//        ▓▓█████████▓▓▓▓▓▓▓µ ▓████████████████▓▓▓▓▒▒╣╫█████████╬╣████████████████████████    //
//        ▓▓▓███████▄▓▓,╫▓▓▓▓╬▓▓▓█▓▓▓████████████████████████████╬████████████████████████    //
//        ▓███████████▓▄▄▓▓▓▓▓▓▓▓▓▓▓▓█████████████████████████████████████████████████████    //
//        ▓▓▓▓▓███████████████████████████████████████████████████████████████████████████    //
//        ▓▓▓▓▓▓█████████████████████████▓▓▓▓█████████████████████████████████████████████    //
//        █████▓████████████████████████▓▓▓▓██████████████████████████████████████████████    //
//                                                                                            //
//                                                                                            //
//                               ▄Æ▓█▀¥▄                                                      //
//                             ▄██████▀▀▀          *███▓███▄                                  //
//                            ▐█████▀  ▄▓█▀▓¥▄    ╓▄▄,████▀█                                  //
//                            ▐█▀▀█¬ ▓██▓▓█▀▄██ ▓██████╩█▌▓▀                                  //
//                             ╙▀▀` █▀▀╓▓███▓µ▐██▀████▀█                                      //
//                                 ╞▌ ▓█████▀ ╟▌█▌╟████▓                                      //
//                                 ╘█ ,▓██▌ ,▄█  ▀▓▄██▀                                       //
//                                   ▀╪▄▓█Φ▀▀█████▓     ,                                     //
//                               ,           █▄▀▌██─    ╫█                                    //
//                               ▀▌           ,██─      ██─                                   //
//                                └▀╗▄     ,▄▓▀█▌▀▀▄▄,▄█╨╟Γ                                   //
//                                    .█└─└ µ,,█▌        ▐▌                                   //
//                                    ▐▌    ───╙█        ▐▌                                   //
//                                    ╟Γ        █        j▌                                   //
//                                    ╫⌐        ▐▌ ▄     ▐▌                                   //
//                                    ╫─         ^  ▀▄   █Γ                                   //
//                                    ╟               ╙▀▀╙                                    //
//                                                                                            //
//                                                                                            //
//                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////


contract AH is ERC721Creator {
    constructor() ERC721Creator("ANIMAL-HOOD", "AH") {}
}