// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: MitamaUnited-supporters
/// @author: manifold.xyz

import "./manifold/ERC1155Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//         `  `        `  `       `  `          `  `                                                                                                                                                            //
//                           `            `           `   `    `                                                                                                                                                //
//                `                   `       `                    `  `  `  `  `  `  `  `  `  `  `  `  `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `   `        //
//        `          `   `     `  `               `         `                                                                                                                                             `     //
//           `                           `           `  `      `                                                                                                                                                //
//              `       `   `       `  `    `  `                                                `....J++J-...   `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `  `           //
//        `        `                              `         `      `   `   `   `  `  `  `  ` .-g###N######N###MNa,.                                                                                             //
//                             `                                                  .JgHHmgJ-gM##MBY1;;;;;;;;?7TWM#N#MHJ,                                                                                `  `     //
//         `  `       `  `        `  `         `   `  `  `     `     `..(JJ..    (##MMMMM##MH5<;;;;;;;;;;;;;;;;;;?TWMM#Mm..                                                                                     //
//               `          `            `  `                     ` .d#NNMM#NN,  .M#NagJ;;;;;;;;;;;;;;<<<:;;;;;;;;;;;;?THM#N,     `    `    `    `    `    `    `    `    `    `    `    `    `    `            //
//                             `    `            `          `     .d###3;;;?MNM&    -7M#Ne;;;;;;:;;;<~~~~~~~~~<;;;;;;;;;;<TMNN,                                                                       `    `    //
//       `   `      `   `                                       `.M#M6+++&++?H##p.     ?##R;;;;;;;;;;__~:~~:~~(;;;;;;;;;;;;?H#Mo                                                                 `              //
//               `         `           `      `     `  `        .M#MOrtttttrz;d##Ma....d##D;;:;;:;;:;;;;;;;;;;;;;:;;:;;;;;;;<M#N.   `   `  `  `   `  `  `   `  `  `   `  `  `   `  `  `   `  `          `       //
//         `                    `  `      `      `        `  ` .##MZtrtrrttrt+<(TMNN###M#3;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;;;;;d#N}                                                                               //
//                    `                                      .d##BtrttrtttttrO+<~~~~<<~<;;;;;;:;;:;;:;;;;;;;;;;;:;;:;;;;:;;;+d#M:                                                                               //
//          `   `       `  `        `  `       `   `       .(##M8tttrAgHMN#NMNsz<:~~:__(;;;;;;;;;;;;;:;;;;;;;;;;;;;;;;;;;;+xdN#F                                                                `  `  `   `     //
//       `          `         `             `  (Hg+(.....JH##MBttrAgM##M#"""H#NRtz<;;;;;;;;;:;;:;;:;;;;:;;:;;:;;:;;;;;;++Owd##@     `  `      `  `      `  `      `  `      `  `      `  `   `                  //
//                               `              (M####NN#MMM9ttOQH##MY!     (#N8ttrO&+<;;;;;;;;;;;;;;;;;;;;;;;;;;;+++OtwQk##M=            `         `         `         `         `                             //
//          `    `      `          `  `  `        ?M##MmgAAwAgg####=       (##@ttrtttrttttwQa&ggNNMMMMMMMMMMMMMMMNNNggMN###=                                                                            `  `    //
//                          `                       -THM#######M"!         d########MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNg.,     `        `         `         `         `         `    `   `  `  `           //
//       `          `    `     `            `  `         `!!!`              ?"[email protected]"7MMMHM,    -#YTM~ d#HMMMMMMMMMMMMMNJ,.   `       `  `      `  `      `  `      `  `                              //
//           `                     `   `                                   .+MMMMMMMM#"!.#1>[email protected] [email protected]>j>dN.   (#>jM  M$;dMC>?N,J#THMMMMMMNg,.                                                                       //
//                     `                          `                   `..MMMMMMMH#C>dN,.MC+>J#.#<jMp>dN   [email protected]>J# .Mz>MM>+&?NdD>gM3>M#MMMMMNg,                                                                    //
//             `   `        `                                      `.JMMMMMH9dN,,N>++?MMD+R>JNM$>?YY>>Hb..Jb>JN..M>+M#>jNe?MC>M#>jMNg&+THMMMMa,                                                                 //
//        `                    `  `  `      `  `                 .(MMMM#WM#>u>dN,Mc+Nx?B>dN<[email protected]>jMMMN<+MMMMMg++7Y<[email protected];j#Ms?>[email protected]>dF dD>qg&#TMMMMa,                                                              //
//           `           `                         `           .MMMMB3juHHD+MN<?MMP>MMs;jMM&&MggMMMMMMMMMMMMMMMMNMMMMNgdMMMe>jM$>M\.#>j# JE;&?TMMMN,                                                            //
//                    `                   `           `     ..MMMM$jg>[email protected] dI?Y1&<?M#+dMMMMMMMBYC?????>???????????????OTTMMMMMMMN&[email protected]>d] M<jMMmjMMMMMa.                                                         //
//                 `        `         `                   .(MMMN>JM^M2<M,M>jMHMNgMMMMMB6???????????>???>?>?>?>????????????+7TMMMMMMMm+M`[email protected]>g+TMMD>dMMMMm.                                                       //
//        `   `                   `            `  `     ..MMM5?Mp+N.(N>db#jdMMMMMM91?????>?>?>?>??>??>??>???>?>?>?>?????>??????zTMMMMMMNMzjNMNd#>dm?MMMMMa.                                                     //
//                       `                             .MMMMM>>dN>db McjMMMMMMB3??????>???>???>??>??>?????>????>???>>?>??>??>??????vTMMMMMm&?HMCjF,Pd/TMMMMp                                                    //
//                           `       `      `        .MMMMM_d>R?Mp<N.JMMMMMBC?????>??>??>???>???>????>?>???>?????>?????>??>??>????>[email protected]+M .Dj} .TMMMN,                                                  //
//         `  `      `           `                 .JMMM#>?MMzN+dNjMMMMMM5??????>??>???>??>??>???>??>???>???>?>???>??>?????>??>?>??>?????7MMMMNx?M8+H    ,MMMMh.                                                //
//                      `              `       `  .MMMMDW+u<dIMbjMMMMM#C?????>???>??>????>????>???>??>??>?>????>???>??>?>???>??>????>???????HMMMNJ&d\      7MMMN,                                               //
//                 `       `        `       `    .MMMH' ,b?Ne>WMMMMM#1???>?>??>??????>??>??>??>?>?????>????>??>?>???>????>??????>?>??>?>?????zHMMMMe        ,MMMMp                                              //
//        `                    `               .gMMMF    ?pdMNMMMM#C??>???>???>?>?>???>???>??>???>?>???>??>??>???>???>??>??>?>???>????>?>?>?>???MMMMN,        UMMMN.                                            //
//           `          `                     .MMMM$      W&NMMMM5??>??>???>???>??>?>??>????>?????>?>???>??????>??>???>???>??>?>???>?????>???????dMMMMx        ?MMMN.                                           //
//                          `      `   `     .MMMM^       .MMMM#???>????>??>?>?????>????>?>???>?>????>???>?>?>??>??>???>????>???>??>?>?>???>?>????1HMMMh.       ,MMMN,                                          //
//             `     `                      .MMMM^       .MMMM5??>???>??>???>??>?>???>???>??>??>??>??>?>????>????>??>???>??>?????>????>??>??>?>?>???dMMMN,       ,MMMN,                                         //
//        `             `        `         .MMMM^       .MMMM3????>??>???>????>???>??>?>???>?????>??>???>????>?>????>?>??>??>?>???>?????>??????>??>???MMMN,       ,MMMN.                                        //
//           `              `        `     dMMM\       .MMMMNgggggggggggx?>?>??>???>?????uggggggggggggggga??ugggggggggggggx????>???>?>??ugggggggggggg&zMMMM,       ,MMMN                                        //
//                 `                      -MMMF       .MMMMMMMMMMMMMMMMMMNc??>??>???>?>?uMMMMMMMMMMMMMMMMMNdMMMMMMMMMMMMMMMNx??>?>?????dMMMMMMMMMMMMMMMmMMMN,       ?MMMb                                       //
//                     `       `         .MMMF       .MMMMdMMMMMMMMMMMR?MMMmc????>?????1MM#gMMMMMMMMMMMb>dMMM#dNNNNNNNNNK+TMMNx???>?>??MM#dNNNNNNNNN2?MMMMMMN.       WMMM,                                      //
//        `   `           `        `  `  MMMM`       dMMMNJMMYTTTTTTWMMx>?MMMp>??>?>?>[email protected]>;>MM#dMMMMMMMMM#>>+TMMNz????>?MM#dMMMMMMMMMP;>?MMMMMb       .MMMN                                      //
//                                      .MMM$       .MMMMNJMMz???????MMN<;>dMNc>????>?uMM8MM#???????zMMb>>>MM#dMN????>MM#;;>;jMMb?>????MM#dMN????dMMP;>>;dMMMM]       -MMM]                                     //
//                 `  `     `          .MMM#       .MMMMMNJMMz??>?>???MMb;>+MMN???>??1MM#dMM3?>??>??zMMb>;;MM#dMN?????MM#;>;>jMMb??>?>?MM#dMN?>??dMMP;;;>dMMMMN.       MMMN.                                    //
//         `  `          `       `     .MMM%       JMMMMMNJMMz???>????dMMp;>?MMK???>?dMMGMM8??>??>??zMMb>>;MM#dMN?>?>?MM#>;>>jMMb>?????MM#dMN?>?>dMMP>;>>dMMMMMb       -MMM]                                    //
//                                  `  MMM#       .MMM#dMNJMMz???????>?HMN+;>dMMs???dMM8MM#???????>?zMMb>;>MM#dMN??>??MM#>;;>jMMb?>?>??MM#dMN??>?dMMP;;;>dMMHMMM.       MMMN                                    //
//                             `      .MMMF       -MMM3dMNJMMz?1MMMMMm?zMMN>>;MMNz?1MM#dMMC1dMMMMN??zMMb>;>MM#dMN????>MM#;>;>jMMb????>?MM#dMN?>??dMMP;>;>dMMdMMM]       JMMM-                                   //
//        `          `  `   `         (MMM\       dMM#?dM#JMMz?dMM$dMMR?dMMR>>?MMb?dMMqMM8?dMMCdMMC?zMMb>>;MM#dMN?>???MM#>;>;jMMb?>????MM#dMN?>??dMMP;;>;dMM?MMM#       .MMM]                                   //
//           `                        dMMM     ` [email protected]?MM#JMMz?zMMP>dMNc?dMMc;>dMMgMM8MM#?dMMD>dMN??zMMb>;>MM#dMN?>?>?MM#>;;>jMMb?>?>??MM#dMN??>?dMMP;>;>dMM?dMMM.       [email protected]                                   //
//                 `              `   MMM#       .MMMD?MM#JMMz??MM#;?MM#??MMN<;>dMMM#dMM11MM#>;MM#??zMMb>;;MM#dMN????>MM#;>;>jMMb??>???MM#dMN?>??dMMP;;>>dMM?dMMM;       MMMN                                   //
//             `         `            MMM#       .MMM$?MM#JMMz??dMN>>JMMp??MMK;>+MMMqMMD?dMM1>jMME?>zMMb>>;MM#dMN?>???MM#>;>>jMMb>???>?MM#dMN?>??dMMP>;;>dMM?dMMM]       dMMM                                   //
//        `                 `         MMMF       -MMMI?MM#JMMz??dMMz;>HMNz?dMMc;>JM8MM#?dMM5;;jMM$??zMMb>>;MM#dMN??>??MM#>;;>jMMb?>????MM#dMN??>?dMMP;>;>dMM?dMMM]       dMMM                                   //
//           `        `        `   `  MMMF       -MMMI?MM#JMMz??dMMZ>;?MMN?1MM#>;>djMM31MM#>;>jMM1??zMMb>;>MM#dMN???>?MM#;>;>jMMb??>?>?MM#dMN?>??dMMP;;>;dMM?dMMM]       dMMM                                   //
//                                    MMMb       ,MMM$?MM#JMMz??zMMb>>>dMMp?dMMs>;[email protected]?dMM>;>>dM#???zMMb>;>MM#dMN?>??>MM#>;>;jMMb?>????MM#dMN?>??dMM$;>;>dMM?dMMM\       dMMM                                   //
//                 `     `            MMM#    `  .MMMb?MM#[email protected]>;;;dMNc?MMN>>dMM1dMM5;;;>MM#?>?zMMb>>;MM#dMN??>??MM#;;>>jMMb??>???MM#dMN??>?dMM$>;>>dMM?dMMM:       dMMN                                   //
//        `   `             `     `   MMMN        MMMN?MM#JMMz?>?MM#;;>>+MMN?JMMm&[email protected]>;>;>MM#???zMMb>;>MMNJMMz??>?MMN;;>;jMMb>??>[email protected]#?>??dMMI;;;>dMM?dMMM        MMM#                                   //
//                     `              JMMM-       dMMN?MM#JMMz???MM#>;;>JJMMK?dMMMMB?dM#<;;>;>[email protected]??>zMMb>>>dMMdMMf????dMM+;>>jMMb?>??>[email protected]???>dMM>;>;>dMM1MMMF       .MMMF                                   //
//                                    ,MMM]       -MMMyMM#JMMz???MM#>;;>jNdMMy??????dMM3;;>;>>[email protected]?>?zMMb>;;JMMPMMN?>??JMMR>;>+MMb?????dM#dMM3??>1MM#;>;>;dMNdMMM%       -MMM\                                   //
//         `  `    `           `   `   MMMN        MMMNMM#JMMz?>?MM#;>;>jMKMMNz????uMME;;>;>>[email protected]???zMMb>;;>MMNdMMc?>??dMMx;;>MM#[email protected]?>??dMM$>;;>>MM#dMMM        dMMM                                    //
//                     `  `            dMMM,       JMMMMM#JMMz???MM#;;>;+MMsMMb??>1MM#>>;>>;[email protected]??>zMMb>>;>dMMpMMN??>??HMMe1>dMMMMMMM#qMM#????jMM#>;>;>jMMNMMMF       .MMMF                                    //
//                           `         .MMMb        MMMMM#JMMz???MM#>;>>+MMNJMMp??dMM>;;>;>[email protected]?>?zMMb>;>>JMMNJMMR?????dMMMNxWHHHHagMMM8??>?1MMM<;>;;>jMMMMM#        gMMM!                                    //
//        `                       `     dMMM,   `   ,MMMM#JMMz???MM#>;;>+MMMNdMMMMMM5>;;>;[email protected]???zMMb>;;;JMMMNJMMNc?>????HMMMMMMMMMB6?????uMMM>;;>;>+MMMMMM\       .MMMF                                     //
//           `     `   `                .MMMN        qMMM#JMMz???MM#;;>>+MMMMKYYYYY5;>;>>>[email protected]??>zMMb;>;>JMMMMMeHMMNx?>???????????>[email protected]>;;>;>>gMMMMMF        MMMM!                                     //
//                        `          `   JMMMp        WMMMdMMNNNNMM#>;;>+MMMMMN&>>;;>;;;>jMMMPMMNNNNNMMb>;>>JMMzdMMNeWMMMNggxz?>?>???1uggNMMMB1;;>;>>;[email protected]        .MMMF                                      //
//             `             `   `        WMMM,  ......MMMMMMMMMMMME>;>>+MMbzHMMN&>>;>>;+MMMMPMMMMMMMMM5>;;>JMMz??TMMNx?TMMMMMMMMMMMMMMMMM8C>;>;>;>;+dMMMMM#        [email protected]                                       //
//        `           `                 ..(MMMMMMMMMMMMMMMMMMMMNg&J>;>>;+MMb??zHMMMMMMMMMMMMMMe<;;;;;;;;;>;;JMMz???+TMMNJ>>>>?7TTYTTC1;>>;;>;;>>>>>jMMMMMM#`       .MMMM`                                       //
//           `           `         .(NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNaJ++MMb????zTYYYYYYY91?7MMNe>>;>;>;>;>>JMMz??>??1TMMNg+>;;;;;>;;;>;;>;;>[email protected]        .MMMM^                                        //
//                          `  .-MMMMMMMMMMBYC??????????uMMMMM#TMMMMMMMMMMMb?>??????>>?>??????dMMNNNNNNNNNNNMMM1???>????TMMMMNg&++>>;>;>>+jgMMMMMMMMMMMMF        .dMMM\                                         //
//                 `        .(MMMMMMMB6=???????????????uMMMMMN?????ZTMMMMMMMMNgxz??????>?>?>??>?TMMMMMMMMMMMMBC??>???>?????7TMMMMMMMMMMMMMMMMMMMHMMMMMM$        .MMMM%                                          //
//        `    `      `   .MMMMMM#[email protected]??????vTMMMMMMMMMNgg&z???>??>??????????????????>??>??>?>??????1ugMMMMMMMMMMB6??zMMMM#'        .MMMM3                                           //
//                     .+MMMMM#[email protected]?????????zTHMMMMMMMMMMMMNNgggggg&&&zzz111?????11zz&&gggggNMMMMMMMMMMMM9C???????MMMM;        .MMMM^                                            //
//           `      .gMMMMMMB1?????????????????????=??dMMM#[email protected]?????????????7THMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMH9C??????????udMMMMb       (MMM#`                                             //
//               [email protected]@HMmz?????????[email protected]@HMMMMm    .MMMMF                                               //
//        `      [email protected]@Hx????[email protected][email protected]?MMMMb  .MMMM^                                                //
//                ?"[email protected][email protected][email protected]#6???JMMMN.MMMMF                                                  //
//           `          ([email protected]@[email protected]@MB1??????MMMMMMM#'                                                   //
//                          7WMMMMMMMMMMNNggggggggNMMMMMMMR?WxdHQd#[email protected]@[email protected]@@M5????????1MMMMMM=                                                     //
//        `                     [email protected]@[email protected][email protected]@#6?????????uMMMMM3                                                       //
//            `                        ?"""""""""""7`  ?WMMMNe??dm?5j8u#[email protected]@[email protected][email protected]@MBI?????????uMMMMMY                                                         //
//                                                       ?MMMMNx??vT1d5j8d#[email protected]@[email protected][email protected]`                                                          //
//                 `                                       TMMMMNx??z9W1gwWNEjb&[email protected]@[email protected][email protected]!                                                            //
//        `  `         `  `                                 .WMMMMNx???7mJW#WB1&[email protected]@[email protected]@[email protected]!                                                              //
//                           `                                ([email protected][email protected]@[email protected]??????????????????????????????????gMMMM#!                                                                //
//                                `  `          `               ,[email protected]@HNmx=???????????????????????????=udMMMM3                                                                  //
//           `     `   `                           `              [email protected]=????????????????????????aMMMMB`                                                                   //
//        `               `    `            `         `              7MMMMMNmx??vSJNVYYT1d????????????????1vT9??????????????????????udMMMM"                                                                     //
//                                     `        `         `            .TMMMMMNax?zTa?MK6?????????????????????????????????????????1gMMMM#`                                                                      //
//            `    `   `    `      `                                      ?WMMMMMMNgx7W5???????????????????????????????????????==gMMMMM=                                                                        //
//                                                 `           `             ?TMMMMMMMNgaz?=???????????????????????????????????aMMMMM"                                                                          //
//        `                                 `   `                                ?"MMMMMMMMNgax=????????????????????????????=uMMMMMD                                                                            //
//           `          `  `   `  `  `                  `   `                        [email protected]`                                                                             //
//                 `                      `                                               ?THMMMMMMMMMNagxz??????????????1gMMMM#'                                                                  `            //
//             `      `                         `  `               `                           -7"MMMMMMMMMMNNgga&zz=?=?dMMMMM^                                                                  `              //
//        `                           `               `                                              ?"WMMMMMMMMMMMMMMMNMMMMD                                                                                   //
//           `           `  `    `            `           `    `       `                                    ?""HMMMMMMMMMM#'                                                                                    //
//                 `                `                                                                                                                                                                           //
//                                                                                                                                                                                                              //
//                                                                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract MUS is ERC1155Creator {
    constructor() ERC1155Creator("MitamaUnited-supporters", "MUS") {}
}