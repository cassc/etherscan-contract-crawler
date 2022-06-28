// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: NiftyRiffs Metaverse Guitars
/// @author: manifold.xyz

import "./ERC721Creator.sol";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                            //
//                                                                                                            //
//                                                           ,;;;;;                                           //
//                                                      ,   ,;::,:;;                                          //
//                                                    ,;;r;rr;;;;;;;r;                                        //
//                                                     ,,,rrr;;;rSr;;r                                        //
//                                                    :,  ;;2;;:;;;;r;                                        //
//                                                   ;;r;;;;;;;;:;;rr,                                        //
//                                                   ,;,;r;;;;;;;;r;,                                         //
//                                                   ,  ;;r2;;;;;,                                            //
//                                                 ,;;r,;:;;;:;;;                                             //
//                                                  ,::r;;;;;;;;;                                             //
//                                                ,:  ,;r5;;;:;;;,                                            //
//                                                ::;:;::;;;:;,;;;                                            //
//                                                 ,,rrr;;;::,;r;;,                                           //
//                                               :,  ;;3;;::,::rr::                                           //
//                                              ::r;::;:;:;rrr;;r:;                                           //
//                                               ,,;rr;;;;:;:;,,5;;,                                          //
//                                             ,:  ::rr;;:;::,;;3;;:                                          //
//                                            ,;;r:;,;:::;:;::;r;;r;                                          //
//                                             ,,,rrr;;::::::::;r;,                                           //
//                                               :;r5;:, ,,:,;;;                                              //
//                                              ,;;:;,:,35 ,;;:                                               //
//                                               ;;;;;:;BM;;;;                                                //
//                                                 :5rrrMBrr5;                                                //
//                                                  ;;:,,,,:;:                                                //
//                                                  ;,,,, ,,:,                                                //
//                                                  ;;:;::,:;:                                                //
//                                                  ;;:,:,::;,                                                //
//                                                  ;;::,,::::                                                //
//                                                  rrr;r;r;r;                                                //
//                                                  ;;,::,,:;:                                                //
//                                                  ;::,:,,,:,                                                //
//                                                  :;,,,,,,,,                                                //
//                                                 ,r;;;;;;;;;                                                //
//                                                 ,;;;;,,;;;;                                                //
//                                                  ;:,,X;, ,,                                                //
//                                                  ;:,,r;,,,,                                                //
//                                                 ,r;;;::;;;:                                                //
//                                                 ,;;;;:;;;;;                                                //
//                                                  ;,,,,,: ,,                                                //
//                                                  ;,,,,,:,,,                                                //
//                                                 :r;;;;;r;r;                                                //
//                                                 ,;;,,,,::;;                                                //
//                                                 ,;,,,B:,,,,                                                //
//                                                 :;;:,;,::::                                                //
//                                                 ;r;;;;;r;r;                                                //
//                                                 ,:,,,, ,,,,                                                //
//                                                 ,;,,,, : ,,                                                //
//                                                 ;r;;;;;;;r;                                                //
//                                                 :;,;,r,:,;:                                                //
//                                                 ::,,;h:  ,:                                                //
//                                                 ;r;;;:;;;r;                                                //
//                                                 ;;:;::,::;;                                                //
//                                                 :: , ,   ,,                                                //
//                                                 rr;;;:;;;;;                                                //
//                                                 ;;,;:r,::;,                                                //
//                                                 ::,,;h,   ,                                                //
//                                                 ;r;r;;;;;r;                                                //
//                                                 ;;,,,,,,,;:                                                //
//                                                 ;;::,:,:,;;                                                //
//                                                ,r;;;;;;;;rr                                                //
//                                                 ,, , , , ,:                                                //
//                                                ,r;:;;;;:;;;                                                //
//                                                ,;:3r,;,Sr::                                                //
//                               :                ,;:5r::,3r:;                                                //
//                              ;rr,              :r;,;;;;:,;;                                                //
//                          ;@[email protected]               ,;,:,,,,,,,,                                                //
//                         @BhMB93M               :rr;r;r;;;r;                                                //
//                        Bh5MMM9;B               ,;,:,,,,,,,:                                                //
//                       3M;MMMMB:M,              ;rr;;;r;;;r;                                                //
//                       [email protected],Mr              ,;,, rh,,,,;                                                //
//                      :M;BMBMBM;AB              ;r;;;;;;r;rr,                                               //
//                      rM;MBMBMMB;Mh             ,;::,,,,:;;:                                                //
//                      [email protected];           ;;;;;r3:;;r;                  :rr:                          //
//                      ;M;[email protected],      ;M;;:;,r9,::;;                 @MMMMB;                        //
//                       M;BMBBBMBMBMBBBMMMMBBBMMM,:;;;,,:;:;;                rM5MrBhB;                       //
//                       [email protected]@@MMMBMMM,;;;;;;;;;;;                BrB5 ,MrM                       //
//                       ;BrMMMBMBMBMBMBMMMMMBMMMB,;;;,[email protected],;:;;               ;MrM,, 33Ar                      //
//                        [email protected]    rG:;;;;;;;;;;;               M5M9   :9rS                      //
//                        [email protected]@      ;;;;;;;:;:;:r            rMS9B    :9r3                      //
//                         [email protected];    ,;r;;:[email protected]:;;;,@MXr:, ,,;[email protected]     rXSr                      //
//                         ;[email protected]   ,:;r;;;;;;r;;:rBMMMBMBMMMBMBh;  ,   [email protected]                       //
//                          929MBMBBBMBBBBBMM  ,,:;rrrrrrrrrrr ,;:[email protected];    ,   :@rS                       //
//                           BrMMBMBBBBBBBBBM:  ,   ,,,,,,, ,  ,              , ,  @39,                       //
//                           33SMMBMBBBBBBBMM; ; ,, , ,, , , ,  ,        , , ,, ;,[email protected]                        //
//                            B;MMMBMBBBMBBMM; r,;;,r,r:;;,r,r;,3:,,,,,,,,,,,,,  ;M5X                         //
//                            S2AMBMBBBBBMBMM;  , ,, , ,  ,,,  , , ,,,,,,,,,,,  ,M3h                          //
//                            r9rBMBBBBBBBMMM   , , , , , , , , , ,,,,,,,,,,,   BSh,                          //
//                            :B;MMMBMBBBBMMS  ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,, 2B3r                           //
//                            ;@rBMBBBBBBBMB  ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,  B29                            //
//                            SSrMMMBBBBBMMr , , , ,,, ,,,,,,,,, ,,,,,,, ,,,, ,Mr9                            //
//                            M;@[email protected] ;, ,, , ,,    , , ,,  ,,,,,,,,,,, ;[email protected]                            //
//                           3X;MMBMBBBMMM    ;5,r;;r:5;rr:3,2;:5, ,,,,: ,,,,  [email protected],                           //
//                          ,M:BMBMBBBBMM:  ,,,,,,,,:,,,:,::::::;,,,, ,:,,,,,  [email protected]                           //
//                          M;SMBMBBBBBMr  ,,, , ,,,,,,,,,,,,,,,,,,,,,,r , , ,  Mr93                          //
//                         @3rMBMBBBBBMB  ,,,,,,,,,,,,,,,,,,,,,,,,,,, :r,,; , ;;;M;Br                         //
//                        S9;MMMBBBBBMB; , , , ,,,,,,,,,,,,,,,,,,,,,,,,; ,;;, ,, AM;M;                        //
//                       rM:MMMBBBBBMBM ;; ,,,,,, ,   ,,, ,,,,,,,,,,, ;;,,,:r,    BB;M:                       //
//                      :M:@MBBBBBBBBMB   ,,,,;5,r:;;,,,       , , , ,;,,,:;:,;;,  [email protected];B                       //
//                      M;[email protected]   ,,,,,;,;;;;;2:3;;;,;,:;,,,,;:,,,:,,,,;r:  M3rM                      //
//                     M5rMMBBBBBBBBBMB  ,,,,,,,,,,,,:,:;,;;:r,5h; ,:; ;::,,,,,,;:  :Mr59                     //
//                    SB;BMBMBBBBBBBBMM3   ,,,,     , , ,,, , ,:;;;:;::;;,:,,,,,,,,;,rM:h;                    //
//                   ,M;@MMMBBBMBBBBBMMMr      ;;;;;;;:;:;;;;;;;  ,;::,;;;;:,, ,,,,;, @M,B                    //
//                   BArMMMBBBBBBBMBMBBMM9, ;  ;r3,,;:;::,;,,rA,,;      ;r;,;;,,;::,, ,B3r3                   //
//                   M;[email protected]; ;;;;r;r;;;;;r; 3r;2;;:,,,,:,::;::,,,, rB;@,                  //
//                  3ArBMBMBBBBBMBBBMBMBMMMMMMM; r;:r,r,;;:r ;, r [email protected]:  ,,,,:,,   M3r3                  //
//                  X3BMBBBBBMBBBBBMBMBMBBBMMMB, ;;;;;;r;;;r;; ;; [email protected]  :; ,:,  3M;9                  //
//                  BMMBBBBBBBBBBBMBBBBBBBMBBMMr::rr;;,r;;;:3:;rr,9BMBMBMBMMMMMr:,:,;,, ;MrS:                 //
//                  BMMMBBBBBBBBBMBMBBBBBMBMBMMMMMMMMMBMMMMBMBMMMMBMM;    ;XMMMMM3:  ,r ,M53;                 //
//                  [email protected]     ,,:rMBMBM3;,:;BMA5;                 //
//                  BMMBBMBMBMBBBBBMBMBBBBBBBMBMBMBBBMBMBMBMBMBMBBBMMr  ,;3r;; 2BMBMBMBMBMS3;                 //
//                  rMMBMBMBBBMBBBMBMBMBMBMBMBMBMBBBMBBBMBBBBBMBBBBBMMh, ;rr::,  9MBMBMMMM3A,                 //
//                   MMMBBBMBMBMBMBBBBBMBBBMBMBBBMBBBMBMBMBBBBBBBBBMBMMMS,,   ,;  rMMMBMMMGh                  //
//                    MMMMMBBBMBMBMBBBBBBBMBBBMBMBMBMBBBMBMBMBMBBBMBMBMMMBh;   :,  rMBBBMBM,                  //
//                     [email protected];  ;MMBMMMr                   //
//                      3BMMMMMBMBMBMBMBBBBBBBBBBBBBMBMBMBMBBBMBBBBBBBBBBBMMMBMMMMMMMBMMMr                    //
//                        SMBMMMBMBMBMBMBMBBBBBBBBBMBMBMBMBBBBBMBMBMBMBMBMBBBMMMMMMMMMBM;                     //
//                          rMMMMMMMMMMBBBMBMBBBBBBBBBMBMBMBMBMBMBBBMBBBBBBBMBMBMBMMMM3                       //
//                             2BMMMMMBMMMMMBMMMMMMMBBBMBMBMBMBMBMBMBMBMBMBMMMBMMMBMr                         //
//                                ;r9BMBMMMMMBMMMMMBMBMMMMMMMMMMMMMMMMMMMMMBMMMBBr,                           //
//                                      ,;[email protected]@Ar;                                //
//                                                    ,;,                                                     //
//                                                                                                            //
//                                                                                                            //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract RIFF is ERC721Creator {
    constructor() ERC721Creator("NiftyRiffs Metaverse Guitars", "RIFF") {}
}