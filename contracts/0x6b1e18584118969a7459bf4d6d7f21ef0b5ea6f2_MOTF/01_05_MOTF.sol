// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Memories Of The Future
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                            //
//                                                                                                                            //
//    ....................................................................................................................    //
//    .------------------------------------------------------------------------------------------------------------------.    //
//    .--.                                                                                                            `--.    //
//    .--.                                                                                                            `--.    //
//    .--.                                                                                                            `--.    //
//    .--.                                                                                                            `--.    //
//    .--.                                                                                                            `--.    //
//    .--.                                                                                                            `--.    //
//    .--.                                                                                                            `--.    //
//    .--.                    .`                                                                                      `--.    //
//    .--.                    `--`                                                                                    `--.    //
//    .--.                      .//.`.`                                                                               `--.    //
//    .--.                        -shmmy+-`                                                                           `--.    //
//    .--.                       .yNNNmmmmds/.                                                                        `--.    //
//    .--.                     `sNMMMNmmmmmmmmh.                                                                      `--.    //
//    .--.                    +NMMNmhhmmmmmmmmm:                                                                      `--.    //
//    .--.                    .oo:.` +mmmmmmmmm:                                                                      `--.    //
//    .--.                           +mmmmmmmmm:                                                                      `--.    //
//    .--.                           +mmmmmmmmm:                                                                      `--.    //
//    .--.                           +mmmmmmmmm:                                                                      `--.    //
//    .--.                           +mmmmmmmmm:                                                                      `--.    //
//    .--.                           +mmmmmmmmm:                                                                      `--.    //
//    .--.                           +mmmmmmmmm/                              `.`                                     `--.    //
//    .--.                           +mmmmmmmmm/                              /dhyso/:-.``                            `--.    //
//    .--.                           /dddddddddso+`                           +mdNNNNNNmdhys+/-..``                   `--.    //
//    .--.                           /dddddmddddddh.                      `.:odmNNNNNNNNNNmmmdhs+:.                   `--.    //
//    .--.                           :ddddmmmddddddh-   ```  //:-.``````:ohmNNNNNNNNNNms/:-.`                         `--.    //
//    .--.                           :ddmmmdmmmmmmmmd+shmNy +NNNNNNmmddmNNNNNNNNNNNNNmdy-                             `--.    //
//    .--.                           `sNNNNNNNNNNNNNmNmMMMMsNNNNNNNNNNNNNNNNNNNNmdhhyssys`                            `--.    //
//    .--.                            .hNNNNNNNNNNNNNMNmMMMMNNNNNNNNNNNNNNNmdhyssssssssyso                            `--.    //
//    .--.                             -dNNNNNNNNNNmMMMNNMMMNNNNNNNNNmddhysssssssssssssyss/                           `--.    //
//    .--.                              /mNNNNNNNNmMMMMMmNMMMNNNhs+:``:osssssssssssssssysss-                          `--.    //
//    .--.                              `oNNNNNNNmNMMMMMMmmhs/-`       `:osssssssssssssyssso`                         `--.    //
//    .--.                               `yNNNNNNNMMMMNy:.`              ./osssssssssssyssss+                         `--.    //
//    .--.                                -hNNNNmMMMdo.                    ./osssssssssysssss:                        `--.    //
//    .--.                                `+mNNmMNy:`                       `-/osssssssyssssss`                       `--.    //
//    .--.                               .+hhNmNmo`                           `-/osssssysssssso                       `--.    //
//    .--.                              -ohdhyhddmo`                            `:/ossyysssssss/                      `--.    //
//    .--.                             -ohdhhddddddh-                             .:/ossssssyyys.                     `--.    //
//    .--.                           `:ohdhddddddddho`                              `:/oyhhhhhhs`                     `--.    //
//    .--.                          `:odhhdddddddy/.                                  .//shhhhhh:                     `--.    //
//    .--.                         ./sdhhdddddho-                                      `:/+shhhhy`                    `--.    //
//    .--.                        -/shhddddds:`                                          -//+yhhho                    `--.    //
//    .--.                       :/yhhdddy/`                                              `:/:/yhh:                   `--.    //
//    .--.                     `:/yhddh+.                                                   -/ .+hh`                  `--.    //
//    .--.                    .:/yhdo-                                                       `   .so                  `--.    //
//    .--.                    ..ys/`                                                               :`                 `--.    //
//    .--.                     :.                                                                                     `--.    //
//    .--.                                                                                                            `--.    //
//    .--.                                                                                                            `--.    //
//    .--.                                                                                                            `--.    //
//    .--.                                                                                                            `--.    //
//    .--.                                                                                                            `--.    //
//    .--.                                                                                                            `--.    //
//    .--.                                                                                                            `--.    //
//    .--.                                                                                                            `--.    //
//    .--.                                                                                                            `--.    //
//    .--.                                                                                                            `--.    //
//    .---............................................................................................................---.    //
//    ....................................................................................................................    //
//                                                                                                                            //
//                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MOTF is ERC721Creator {
    constructor() ERC721Creator("Memories Of The Future", "MOTF") {}
}