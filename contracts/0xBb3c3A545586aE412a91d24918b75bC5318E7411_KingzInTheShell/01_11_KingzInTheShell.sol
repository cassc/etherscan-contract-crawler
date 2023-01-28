// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./interfaces/IKingzInTheShell.sol";

interface IKaijuKingz is IERC721 {
    function tokenURI(uint256) external view returns (string memory);
}

interface IScales {
    struct AccountInfo {
        uint16 shares;
        uint128 lastUpdate;
        uint256 stash;
    }

    function accountInfo(address) external view returns (AccountInfo memory);
    function ownerOf(uint256) external view returns (address);
}

/**                                     ..',,;;;;:::;;;,,'..
                                 .';:ccccc:::;;,,,,,;;;:::ccccc:;'.
                            .,:ccc:;'..                      ..';:ccc:,.
                        .':cc:,.                                    .,ccc:'.
                     .,clc,.                                            .,clc,.
                   'clc'                                                    'clc'
                .;ll,.                                                        .;ll;.
              .:ol.                                                              'co:.
             ;oc.                                                                  .co;
           'oo'                                                                      'lo'
         .cd;                                                                          ;dc.
        .ol.                                                                 .,.        .lo.
       ,dc.                                                               'cxKWK;         cd,
      ;d;                                                             .;oONWMMMMXc         ;d;
     ;d;                                                           'cxKWMMMMMMMMMXl.        ;x;
    ,x:            ;dxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx0NMMMMMMMMMMMMMMNd.        :x,
   .dc           .lXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.        cd.
   ld.          .oNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkl'         .dl
  ,x;          .xWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0d:.             ;x,
  oo.         .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKxc'.                .oo
 'x:          .kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNOo;.                     :x'
 :x.           .xWMMMMMMMMMMM0occcccccccccccccccccccccccccccccccccccc:'                         .x:
 lo.            .oNMMMMMMMMMX;                                                                  .ol
.ol              .lXMMMMMMMWd.  ,dddddddddddddddo;.   .:dddddddddddddo,                          lo.
.dl                cXMMMMMM0,  'OMMMMMMMMMMMMMMNd.   .xWMMMMMMMMMMMMXo.                          ld.
.dl                 ;KMMMMNl   oWMMMMMMMMMMMMMXc.   ,OWMMMMMMMMMMMMK:                            ld.
 oo                  ,OWMMO.  ,KMMMMMMMMMMMMW0;   .cKMMMMMMMMMMMMWO,                             oo
 cd.                  'kWX:  .xWMMMMMMMMMMMWx.  .dKNMMMMMMMMMMMMNd.                             .dc
 ,x,                   .dd.  ;KMMMMMMMMMMMXo.  'kWMMMMMMMMMMMMMXl.                              ,x;
 .dc                     .   .,:loxOKNWMMK:   ;0WMMMMMMMMMMMMW0;                                cd.
  :d.                      ...      ..,:c'  .lXMMMMMMMMMMMMMWk'                                .d:
  .dl                      :OKOxoc:,..     .xNMMMMMMMMMMMMMNo.                                 cd.
   ;x,                      ;0MMMMWWXKOxoclOWMMMMMMMMMMMMMKc                                  ,x;
    cd.                      ,OWMMMMMMMMMMMMMMMMMMMMMMMMWO,                                  .dc
    .oo.                      .kWMMMMMMMMMMMMMMMMMMMMMMNx.                                  .oo.
     .oo.                      .xWMMMMMMMMMMMMMMMMMMMMXl.                                  .oo.
      .lo.                      .oNMMMMMMMMMMMMMMMMMW0;                                   .ol.
       .cd,                      .lXMMMMMMMMMMMMMMMWk'                                   ,dc.
         ;dc.                      :KMMMMMMMMMMMMNKo.                                  .cd;
          .lo,                      ;0WWWWWWWWWWKc.                                   'ol.
            ,ol.                     .,,,,,,,,,,.                                   .lo,
             .;oc.                                                                .co:.
               .;ol'                                                            'lo;.
                  ,ll:.                                                      .:ll,
                    .:ll;.                                                .;ll:.
                       .:ll:,.                                        .,:ll:.
                          .,:ccc;'.                              .';ccc:,.
                              .';cccc::;'...            ...';:ccccc;'.
                                    .',;::cc::cc::::::::::::;,..
                                              ........
 * @title KingzInTheShell
 * @author Augminted Labs, LLC
 * @notice Mock ERC721 for preserving Collab.Land support in P2E ecosystem
 */
contract KingzInTheShell is ERC721, IKingzInTheShell {
    IKaijuKingz public immutable KAIJU;
    IScales public immutable SCALES;

    constructor(address kaiju, address scales) ERC721("KingzInTheShell", "KAIJU") {
        KAIJU = IKaijuKingz(kaiju);
        SCALES = IScales(scales);
    }

    /**
     * @notice Get the combined balance of an account's staked and unstaked KAIJU
     * @param account Address of account to return balance for
     * @return uint256 Combined KAIJU balance
     */
    function balanceOf(address account) public view override(ERC721, IERC721) returns (uint256) {
        return KAIJU.balanceOf(account) + SCALES.accountInfo(account).shares;
    }

    /**
     * @notice Return the actual owner of a KAIJU regardless of staking status
     * @param tokenId KAIJU to return the owner of
     * @return address Actual KAIJU owner
     */
    function ownerOf(uint256 tokenId) public view override(ERC721, IERC721) returns (address) {
        address owner = KAIJU.ownerOf(tokenId);

        return owner == address(SCALES) ? SCALES.ownerOf(tokenId) : owner;
    }

    /**
     * @notice Return whether or not an address holds a staked or unstaked KAIJU
     * @param account Address to return the holder status of
     */
    function isHolder(address account) public view override returns (bool) {
        return KAIJU.balanceOf(account) > 0 || SCALES.accountInfo(account).shares > 0;
    }

    /*
     * @inheritdoc ERC721
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        return KAIJU.tokenURI(tokenId);
    }
}