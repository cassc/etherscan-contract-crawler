// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Urban Motion
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                            //
//    '  UUUUUU___UUUUUUUUUUU___UUUUUUUUUUU___UUUUUUUUUUU___UUUUUUUUUUU___UUUUUUUUUUUUUUUUUUUU___UUUUUUUUUUU___UUUUUUUUUUU___UUUUUUUUUUUUUUUUUUUUUUU___UUUUUUUUUUU___UUUUUUUUUUUUUUUUUUUU___UUUUUUUUUUU___UUUUUUUUUUUUUUUUUUUU___UUUUUUUUUUU___UUUUUUUUUUU___UUUUUUUUUUU___UUUUUUUUUUU___UUUUUUUUUUU___UUUUUUUUUUU___UUUUU    //
//    '  UUUUU/\__\UUUUUUUUU/\UU\UUUUUUUUU/\UU\UUUUUUUUU/\UU\UUUUUUUUU/\__\UUUUUUUUUUUUUUUUUU/\__\UUUUUUUUU/\UU\UUUUUUUUU/\UU\UUUUUUUUUU___UUUUUUUU/\UU\UUUUUUUUU/\__\UUUUUUUUUUUUUUUUUU/\UU\UUUUUUUUU|\__\UUUUUUUUUUUUUUUUUU|\__\UUUUUUUUU/\__\UUUUUUUUU/\UU\UUUUUUUUU/\UU\UUUUUUUUU/\UU\UUUUUUUUU/\UU\UUUUUUUUU/\UU\UUUU    //
//    '  UUUU/:/UU/UUUUUUUU/::\UU\UUUUUUU/::\UU\UUUUUUU/::\UU\UUUUUUU/::|UU|UUUUUUUUUUUUUUUU/::|UU|UUUUUUU/::\UU\UUUUUUUU\:\UU\UUUUUUUU/\UU\UUUUUU/::\UU\UUUUUUU/::|UU|UUUUUUUUUUUUUUUU/::\UU\UUUUUUUU|:|UU|UUUUUUUUUUUUUUUUU|:|UU|UUUUUUU/:/UU/UUUUUUUU/::\UU\UUUUUUU/::\UU\UUUUUUU/::\UU\UUUUUUUU\:\UU\UUUUUUU/::\UU\UUU    //
//    '  UUU/:/UU/UUUUUUUU/:/\:\UU\UUUUU/:/\:\UU\UUUUU/:/\:\UU\UUUUU/:|:|UU|UUUUUUUUUUUUUUU/:|:|UU|UUUUUU/:/\:\UU\UUUUUUUU\:\UU\UUUUUUU\:\UU\UUUU/:/\:\UU\UUUUU/:|:|UU|UUUUUUUUUUUUUUU/:/\:\UU\UUUUUUU|:|UU|UUUUUUUUUUUUUUUUU|:|UU|UUUUUU/:/__/UUUUUUUU/:/\:\UU\UUUUU/:/\:\UU\UUUUU/:/\:\UU\UUUUUUUU\:\UU\UUUUU/:/\:\UU\UU    //
//    '  UU/:/UU/UU___UUU/::\~\:\UU\UUU/::\~\:\__\UUU/::\~\:\UU\UUU/:/|:|UU|__UUUUUUUUUUUU/:/|:|__|__UUU/:/UU\:\UU\UUUUUUU/::\UU\UUUUUU/::\__\UU/:/UU\:\UU\UUU/:/|:|UU|__UUUUUUUUUUUU/::\~\:\__\UUUUUU|:|__|__UUUUUUUUUUUUUUU|:|__|__UUU/::\__\____UUU/::\~\:\UU\UUU/::\~\:\UU\UUU/::\~\:\UU\UUUUUUU/::\UU\UUU/::\~\:\UU\U    //
//    '  U/:/__/UU/\__\U/:/\:\U\:\__\U/:/\:\U\:|__|U/:/\:\U\:\__\U/:/U|:|U/\__\UUUUUUUUUU/:/U|::::\__\U/:/__/U\:\__\UUUUU/:/\:\__\UU__/:/\/__/U/:/__/U\:\__\U/:/U|:|U/\__\UUUUUUUUUU/:/\:\U\:|__|UUUUU/::::\__\UUUUUUUUUU____/::::\__\U/:/\:::::\__\U/:/\:\U\:\__\U/:/\:\U\:\__\U/:/\:\U\:\__\UUUUU/:/\:\__\U/:/\:\U\:\__\    //
//    '  U\:\UU\U/:/UU/U\/_|::\/:/UU/U\:\~\:\/:/UU/U\/__\:\/:/UU/U\/__|:|/:/UU/UUUUUUUUUU\/__/~~/:/UU/U\:\UU\U/:/UU/UUUU/:/UU\/__/U/\/:/UU/UUUU\:\UU\U/:/UU/U\/__|:|/:/UU/UUUUUUUUUU\:\~\:\/:/UU/UUUU/:/~~/~UUUUUUUUUUUUU\::::/~~/~UUUU\/_|:|~~|~UUUU\/__\:\/:/UU/U\/_|::\/:/UU/U\/__\:\/:/UU/UUUU/:/UU\/__/U\:\~\:\U\/__/    //
//    '  UU\:\UU/:/UU/UUUUU|:|::/UU/UUU\:\U\::/UU/UUUUUUU\::/UU/UUUUUU|:/:/UU/UUUUUUUUUUUUUUUUU/:/UU/UUU\:\UU/:/UU/UUUU/:/UU/UUUUUU\::/__/UUUUUU\:\UU/:/UU/UUUUUU|:/:/UU/UUUUUUUUUUUU\:\U\::/UU/UUUU/:/UU/UUUUUUUUUUUUUUUU~~|:|~~|UUUUUUUU|:|UU|UUUUUUUUUU\::/UU/UUUUU|:|::/UU/UUUUUUU\::/UU/UUUU/:/UU/UUUUUUU\:\U\:\__\UU    //
//    '  UUU\:\/:/UU/UUUUUU|:|\/__/UUUUU\:\/:/UU/UUUUUUUU/:/UU/UUUUUUU|::/UU/UUUUUUUUUUUUUUUUU/:/UU/UUUUU\:\/:/UU/UUUUU\/__/UUUUUUUU\:\__\UUUUUUU\:\/:/UU/UUUUUUU|::/UU/UUUUUUUUUUUUUU\:\/:/UU/UUUUU\/__/UUUUUUUUUUUUUUUUUUU|:|UU|UUUUUUUU|:|UU|UUUUUUUUUU/:/UU/UUUUUU|:|\/__/UUUUUUUU/:/UU/UUUUU\/__/UUUUUUUUU\:\U\/__/UU    //
//    '  UUUU\::/UU/UUUUUUU|:|UU|UUUUUUUU\::/__/UUUUUUUU/:/UU/UUUUUUUU/:/UU/UUUUUUUUUUUUUUUUU/:/UU/UUUUUUU\::/UU/UUUUUUUUUUUUUUUUUUUU\/__/UUUUUUUU\::/UU/UUUUUUUU/:/UU/UUUUUUUUUUUUUUUU\::/__/UUUUUUUUUUUUUUUUUUUUUUUUUUUUUU|:|UU|UUUUUUUU|:|UU|UUUUUUUUU/:/UU/UUUUUUU|:|UU|UUUUUUUUU/:/UU/UUUUUUUUUUUUUUUUUUUUU\:\__\UUUU    //
//    '  UUUUU\/__/UUUUUUUUU\|__|UUUUUUUUU~~UUUUUUUUUUUU\/__/UUUUUUUUU\/__/UUUUUUUUUUUUUUUUUU\/__/UUUUUUUUU\/__/UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU\/__/UUUUUUUUU\/__/UUUUUUUUUUUUUUUUUU~~UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU\|__|UUUUUUUUU\|__|UUUUUUUUU\/__/UUUUUUUUU\|__|UUUUUUUUU\/__/UUUUUUUUUUUUUUUUUUUUUUU\/__/UUUU    //
//                                                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                            //
//                                                                                                                                                                                                                                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract UM is ERC1155Creator {
    constructor() ERC1155Creator("Urban Motion", "UM") {}
}