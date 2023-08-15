// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import { ERC721CoreOpenSea } from "../core/ERC721CoreOpenSea.sol";

/*

                 . 1ttffttt .        . 1ttfftt1 .        . 1ttffttt .        . 1ttfftt1 .        . 1ttfftt1 .
              .tfft1i;;;;;i1tL.   .tff11i;;;;;i1tL.   .tfft1i;;;:;i1tL.   .tff11i;;;;;i1tL.   .tff11i;;;;;ittL.
            .Lt1;:,.      .,i:f..Lti;:,.      .,i:L..Lf1;:,.      .,i:f..Lti;:,.      .,i:f. Lti;:,.      .,i:L ,
          .Ct;;:.   .,.    :1,L01;;:.   .,.    :1.C8t;;:.   .,.    ,1,L01;;:.   .,.    :1.C01;;:.   .,.    :i.L@0
         .L:;:   .;;:::;,.i;:0f,;:   .;;:::;,.i;;8L,;:   .;;:::;,.i;:0f,;:   .;;:::;,.i;;0f:;:   .;;:::;,.i:;8 @L
         i:i.   :1;:,,,:1fi,;::i.   :i;:,,,:1fi,;;:i.   :1;:,,,:1fi,;::i.   :i;:,,,:1fi,;::;.   :i;:,,,:1t;,;L@L
      t@;:i    :1 1,,,.....;;:;    :i 1,,,.....i:,i    ,1 1,,,.....;;:i    :1 1,,,.....i;:;    :i 1,,,.....i:;@G
     ;@t.1     1 .t        iii     t .t        i;i     1..t        iii     1 .t        iii     t ,1        1.G@0
      @.1.     i: i:;:     11.     1, i:i,    .11.     i: i:;:     1t.     1, i:i:    .11      1,.i:i,    .1.@ f
    ;@@.t      .i;,,t:    :i1      .i:,,t,    ;;1.     .i;,,1:    :i1      .i:,,t,    :i1      .i:,,t,    ;:i @:
    i@ i,i.      .,::     1,:i       .,:,     1.,i.      .,::     1,,i       .,:,     1.:;       ,,:,     1.C@0
    .8@@1:;,..           .t.i:;,..           .1.1:;:..           .t.i:;,..           .1.i:;,..           .1.@@f
     ;8@@0ti;::,,,::,,,,::,; Gti;::,,,::,,,,::,i Gti;::,,,::,,,,::,; Gti;::,,,::,,,,::,i Gti;::,,,::,,,,:;.1 @:
      ,L8@@@8GCLffffffffLLC@@@@@8GCLffffffffLLC@@@@@8GCLffffffffLLC@@@@@8GCLffffffffLLC@@@@@8GCLffffffffLLC@@0
        ,1C  @@@@@@@@@@@@@@@0tC  @@@@@@@@@@@@@@@GtC  @@@@@@@@@@@@@@@0tC  @@@@@@@@@@@@@@@0tC  @@@@@@@@@@@@@@@G:
            ,:i1tffffftt11;:   .,:i1tffffftt11;:    ,:i1tffffftt11;:   .,:i1tffffftt11;:   .,:i1tffffftt11;:
*/
contract SamsungCollabSkinNFT is ERC721CoreOpenSea {
    /* solhint-disable no-empty-blocks */
    constructor()
        ERC721CoreOpenSea(
            "GGGGG Samsung special collection",
            "GGGGGSAMSUNG",
            address(0),
            0,
            30,
            "",
            ""
        )
    {}
    /* solhint-enable no-empty-blocks */
}