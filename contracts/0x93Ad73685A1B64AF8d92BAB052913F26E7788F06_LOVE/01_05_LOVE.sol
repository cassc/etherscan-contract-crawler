// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: LOVE ON CHAIN
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                          //
//                                                                                          //
//               [email protected]@[email protected]@@[email protected]@[email protected]@[email protected]@@[email protected]@[email protected]                        //
//               :[email protected]@[email protected]@MBOO0qSk5F2uL7;;;[email protected]@@qNOLBBMX                         //
//                [email protected]@[email protected]@[email protected]                         //
//                [email protected]@[email protected]@[email protected]@@.       LOVE ON CHAIN       //
//               [email protected]@[email protected]@[email protected];[email protected]:          ArtByGage         //
//            ,[email protected]@[email protected]@BMMMO8qNSSUFqJ:r77:rvv7;;vSG,              . . . .        //
//    :[email protected]@[email protected]@@[email protected]@MBMMGPjLLu1Xr:ii:::777rri::i::,,...,:::,::::::::i.       //
//    [email protected]:,:,:,,,,.. .   ..,....,::.........,,.       //
//    @[email protected]@[email protected]::,.,,,,,.. . .     ......,,:...........,       //
//    [email protected]@[email protected]:,,...,...,.,.,.:.,,:....,,.,,,:.:,,.,...,,.       //
//    [email protected]@ui:,,:,,,,.,.,.,,:,:,,.,.....,,.,,:::::,,.,,:.       //
//    [email protected]@OGYi::,:::,:::,:,:.,,,........ ....,,..:r:,,,,::.       //
//    [email protected]@@@@Xvi,:,:,:,:,:,:,,,,.,,,...... ... ........ir,:,,.:.       //
//    [email protected]@[email protected]@Bv ..,.,,:,,.,.,...,,,.,,,..........   ...,.,ri,,....       //
//    [email protected]@BN7. .,,,:,,,,.........,.,.,...,.,....     ..,.:,iLi...,       //
//    [email protected],   ,.,,,,,,:,:......,,.,,,.,.,.,.,.....   .,::iiU:.....       //
//    [email protected]@BMui.    . ..:,,,,,,,:,:,,.....,,:,,.,,......,..     ..::iiLJ:....       //
//    0qE8MMZX8BOMX;         ....,,:,:::,:::,....,,,,,...,..........     ..:r7uY.....       //
//    [email protected]              ....,.,,:,:::,,.,,:,,.,.,......            .:j07:,...       //
//    kMBMFPOM0u                   ......::::i,,,:,,..,,.. .                 rOv::,..       //
//    8BM5FOMSu.    .               . ....,,:i:::::....                       iJr::,,       //
//    MMkSXMk2,  ,:i::,.             . .....:;iii:....   .              .,,.   :7i::.       //
//    BZF5ZX5r.,iirri:::.           . ......:;7r7::.... .              .::iii,. :ri,,       //
//    OZJSGkv:.iLEk27rii..           ....,.,,rrrY;::....               ::::rLY:..ii::       //
//    MPukEur,:75qPu7iii,..     . ....,.,,::i7;:17i:,,,.. . . .       .:rrrJZ0Y:,,ri:       //
//    M0LEEJi::rvLrrir::...........,.,,:,::irji.u2rii:,:,........,...,:irvY11jr::ii:.       //
//    BOuNZJ7:i:i;r;r::.,.,.,.:,:,:,:,::i:iivu: rkuv7ii::,:,:,:,:::::::::i7vJLLri:ri:       //
//    OM5q0u7r:::i:::::::::::::::::i:::iirrvuu:..1kjvv;;iiii:i:i:i:i:i:iirr7r7r;i;rr:.      //
//    SPMFGuLr;iiii:::i:::i:iiiii:iiiirr77vL5r, .iXFJ7777rri;iiii:iiiiri;irr7rr;7rJ7i.      //
//    SNMqkkjLrrrrir;r;ri;iiiiiririrr77vvLvFui...:7NFjvLvv7vv7r7r7r7rrr7;rr77v7v7v27:.      //
//    ME0E2k2YL7vrrr7r77777r7r7r7rvvvvYLLLS57,....:L0PuLYLLLYvL7vvv7vvv7v7Lvv7L7vFF;:.      //
//    J5OMNUF2JYvvvLvv7vvLvLvvvLvLvLLJLYjqkL:,...,,iJNN5LYLJLYLJLLLLLLvYLJLLLYvv5Zvi:.      //
//    ;[email protected]:,....,:ivqZPujYjLuJuuuuuYuJjYuLYLv1O27::.      //
//    ::7u0BXjjuYYLJYjYjYujUJjJUuuJJY5E85Yi::,...,.::i7FEGS1uuJuJujuuujujuJJvL1MSLii:.      //
//    i,vL1EMOSYJYuYjYujuJujuuuJuYj5GOE2Yri:,,,.:,:,::irjP80NS5uujUjuuUujYJvYXBPj;i:i.      //
//    :,rLv1EMBB1JLJLJLuJuuujuJu1N8BZSjLii:,,:,:,:,:,::[email protected]:::,      //
//    [email protected]@Oq12uuJ2u1FXq8MMMGFu7r::,,,:::,:,,,:::,:[email protected]:::i,      //
//    :.:i;[email protected]@MMOMOMMBMM8GX1Yvr:::,,,:::::,:,:,:,,,:::[email protected]:::::.      //
//    i.i:i;[email protected]::::::::::::::,,,:,:,:,:,,:;vu1SFXXqkNkZBF7i::::::.      //
//    :.:::i:[email protected]:::::::i:i::::,:,:,:,:::::::,::rvuU525UuPBL;:::::::.      //
//    :.::i:i:[email protected]:::i:iiiii::::::,:,:,:,::::::::::::;rv7v70G7ii::::::.      //
//    i,:::::::iiYBMkF22jJvv77i;iiiiiii;ii:i::::::,:,:,:::::::::ii::::ii;rPkir:::::::,      //
//    i.i:::::::[email protected];rir;;iiiriiii:i::,:::::::::::::,::::iii;rirrZurii:i:::i,      //
//    i,:::::::::ivBkj7v7vr7r;iririri;irii:::i:::::i:::::::::::::i:iirirrvEjr;ii:i:i:,      //
//    i,:::,::::i:rqkvv7v77rrrrirrr;i:i:i:::::::::::i:::::::::::::::iirr7vZLriiii:::i,      //
//    i.::,:,::::ii1kY7vr7rrrrrri;ii:i:i:i:::i:::i:::::::i:::::i:iiiirr7rL0Lrri;ii:i:.      //
//    :.::::::iiiiiv0Yv77;r;riiiiiii::::::::::::::::::i:i:i:i:iiiirirrrr770v7rrii::::.      //
//    i.::::::::iri7NUvvrririiiiii:i:i:i:i:::::::::::i:iii:iiiiiiirrr7777L0Jr7iiii::i:      //
//    i.::::i:::ii7r01L77rr;iii:iii:i:i:::i:::::i:::::i:i:ii;ir;r;rr77777LOu7rri;iiii,      //
//    :.:::::i:iiii7PPLvr7iri;i;iiii:i:iii:i:i:i:i:::i:iiii;i;rrr77v7v7v7jM277rr;iiii,      //
//    :.::::::::iirrNkJ77rri;;r;ri;iiiii;iiiiii:i:i:iiiiiiii;i7r77v7v7L7vYM1v77riirii,      //
//    :.:::i::iiirr7kPYL7v77rrrrr7rr;rr;i;iiiiiiiiii:iiii;ir;rr7r7777vvL7JOE777vrri;i:      //
//    i.::::i:iii;77XXJLLvvvL77r777rririiiiiri;iiii:iii:irr;rr7r7r77v7LvLj8Mj7v77i;;7:      //
//    :.:::i:iiii77vS0JuJYvL7v77r7rririii;iriri;ii:iiii;[email protected]:      //
//    :.::::iirirr7vNqUJYLLvL7vv7r7rrir;r;ririii;iiiri;rrirr7r7vv7vvLLLLj1NOBuJvvv7rr:      //
//    :.:i:iirrr;rr7NZUuJJLLvv7v77rrrrr;rr;rir;r;rrr;rrrrr77777L7vvvvLLuukPGMZJJvL77r:      //
//    :.i:::iir;;r77Z01uuYJYLvv7v7vrr77r7r7rrrrrrir;7r777r7rL7v7v7YLjJuu5k0E8GXJJvv77:      //
//    :,:i:iirrrirrLZZ1UJuuuYYLv7v7777r7r777r7rrrr;rr7r7rr7v7vvLvLLjJUu1SqNZEGZFJYvv7i      //
//    :.i:ii;irrrr7JOqFu2juYYLYvLvLvv7v77r777rrr777r7r7r77vvL7LLYYjJuu15XXEN0assciivLi      //
//    i.iii;;7irr772GP1UuuLYvLvL7LvL7v7vr7r7r7r77777r77vvvLLvLvJYuJuu21kkPq0qE0Zk1JjLr      //
//    i.i:iirirr7r75ZPSuuYuLLvLvL7LvLvv7Lvv7L777v7v7LvYLLvLLjJjJUu2U1UkkPXqq0N00XYSuur      //
//    i ,,,::::i:;r5NSujLLvLvv7vrrrr;7r7r7rrrrr7r7r7r7r77vvvvJLJJujUuU2S5SkXkPXqqvv5Yr      //
//    u/clothesareoverrated                                                                 //
//                                                                                          //
//                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////


contract LOVE is ERC1155Creator {
    constructor() ERC1155Creator("LOVE ON CHAIN", "LOVE") {}
}