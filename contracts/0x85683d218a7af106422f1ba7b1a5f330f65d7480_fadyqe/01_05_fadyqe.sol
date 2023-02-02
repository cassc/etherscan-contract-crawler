// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Matilda Fadyqé
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

////////////////////////////////////////////////////
//                                                //
//                                                //
//    ╔╦╗┌─┐┌┬┐┬┬  ┌┬┐┌─┐  ╔═╗┌─┐┌┬┐┬ ┬┌─┐ ┌─┐    //
//    ║║║├─┤ │ ││   ││├─┤  ╠╣ ├─┤ ││└┬┘│─┼┐├┤     //
//    ╩ ╩┴ ┴ ┴ ┴┴─┘─┴┘┴ ┴  ╚  ┴ ┴─┴┘ ┴ └─┘└└─┘    //
//                                                //
//                                                //
////////////////////////////////////////////////////


contract fadyqe is ERC1155Creator {
    constructor() ERC1155Creator(unicode"Matilda Fadyqé", "fadyqe") {}
}