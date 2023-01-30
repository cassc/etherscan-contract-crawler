// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Devil in Heaven
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                                                           //
//    Once upon a time, in a land far, far away, there lived a horned woman named Adin. She was feared and respected by all who knew her, as she was a wild and powerful creature. Her father, of unknown mixed heritage, had always warned her to hide her horns, out of fear of rejection from society.    //
//                                                                                                                                                                                                                                                                                                           //
//    But Adin was not one to be controlled by fear. Despite the disdain and judgement of those around her, she proudly wore her horns and displayed her unique appearance.                                                                                                                                  //
//                                                                                                                                                                                                                                                                                                           //
//    One day, while out hunting, Adin encountered a strange creature. It was a small baby with two eyes on either side of its head. Adin felt an immediate connection with the creature and knew it was her destiny to protect and raise it as her own.                                                     //
//                                                                                                                                                                                                                                                                                                           //
//    She named the baby Eyra, and together they roamed the land, striking fear into the hearts of anyone brave enough to cross their path. Despite her fearsome reputation, Adin loved Eyra with all her heart and would do anything to keep her safe.                                                      //
//                                                                                                                                                                                                                                                                                                           //
//    As Eyra grew, her horns began to emerge, just like her mother's. Adin was proud to see her daughter embrace her true nature, and together they became an unstoppable force of power.                                                                                                                   //
//                                                                                                                                                                                                                                                                                                           //
//    However, their bond was tested when a group of hunters, determined to rid the land of the horned woman and her demon child, set out to hunt them. Adin and Eyra bravely fought, but were outnumbered and outmatched.                                                                                   //
//                                                                                                                                                                                                                                                                                                           //
//    In a final selfless act, Adin used her powers to create a magical barrier around Eyra, protecting her from harm. Then, determined to give her daughter a chance at freedom and a chance to live her own life, she turned to face the hunters alone.                                                    //
//                                                                                                                                                                                                                                                                                                           //
//    The hunters were never seen or heard from again, but the legend of the horned woman and her two-eyed demon baby lives on to this day. Some say Adin and Eyra still roam the land, protecting the oppressed and striking fear into the hearts of the wicked.                                            //
//                                                                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract DH is ERC1155Creator {
    constructor() ERC1155Creator("Devil in Heaven", "DH") {}
}