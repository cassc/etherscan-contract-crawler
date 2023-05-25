// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: First Day Out
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//          ____    ______   ____    ____    ______      ____    ______   __    __      _____   __  __  ______            //
//         /\  _`\ /\__  _\ /\  _`\ /\  _`\ /\__  _\    /\  _`\ /\  _  \ /\ \  /\ \    /\  __`\/\ \/\ \/\__  _\           //
//         \ \ \L\_\/_/\ \/ \ \ \L\ \ \,\L\_\/_/\ \/    \ \ \/\ \ \ \L\ \\ `\`\\/'/    \ \ \/\ \ \ \ \ \/_/\ \/           //
//          \ \  _\/  \ \ \  \ \ ,  /\/_\__ \  \ \ \     \ \ \ \ \ \  __ \`\ `\ /'      \ \ \ \ \ \ \ \ \ \ \ \           //
//           \ \ \/    \_\ \__\ \ \\ \ /\ \L\ \ \ \ \     \ \ \_\ \ \ \/\ \ `\ \ \       \ \ \_\ \ \ \_\ \ \ \ \          //
//            \ \_\    /\_____\\ \_\ \_\ `\____\ \ \_\     \ \____/\ \_\ \_\  \ \_\       \ \_____\ \_____\ \ \_\         //
//             \/_/    \/_____/ \/_/\/ /\/_____/  \/_/      \/___/  \/_/\/_/   \/_/        \/_____/\/_____/  \/_/         //
//                                                                                                                        //
//                                                                                                                        //
//        "Never let them steal your aura. To be a criminal in the eyes of the law and a disappointment in the eyes       //
//        of society is often to look at the present state of the world and find “That's just the way things are”         //
//        is a dissatisfactory answer. It's the persistence to press on and challenge like a child, understanding         //
//        that waxing older does not mean ceasing to ask “why” and most certainly does not mean you must accept the       //
//        world just as it is. The belief in the individual's power to change the world must carry on at any expense.     //
//                                                                                                                        //
//        Never let a cold cell turn your heart cold. Twenty-three hours in a cell is hard but you were still given       //
//        the twenty-fourth, make the most of it and be thankful. Never let the walls around you build up walls           //
//        within. Be brave enough to love and be vulnerable in the face of adversity. Never let your cell mate go         //
//        hungry. If the CO won't give you paper — write on the walls, carrying on the spirit of the poets and the        //
//        artists before you.                                                                                             //
//                                                                                                                        //
//        Where there is a voice, there is hope and hope must continue at all costs so always express and express         //
//        honestly. When you forget what the sun looks like, remember a greater light lives within; exist in              //
//        incandescence and rain or shine, reign with shine. If you acted in pure intention, then you need never          //
//        fear a jail cell for the universe is on your side. There comes a time where what is done in spirit              //
//        supersedes legality so ride the river, war with the wind, dance with the devil and go beyond. Everything        //
//        you need is on the other side.”                                                                                 //
//                                                                                                                        //
//                                                                                                                        //
//        Isaac Wright                                                                                                    //
//        Written on his cell wall at Coconino County Detention Facility                                                  //
//        Christmas Day, 2020                                                                                             //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
//                                                                                                                        //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract FDO is ERC721Creator {
    constructor() ERC721Creator("First Day Out", "FDO") {}
}