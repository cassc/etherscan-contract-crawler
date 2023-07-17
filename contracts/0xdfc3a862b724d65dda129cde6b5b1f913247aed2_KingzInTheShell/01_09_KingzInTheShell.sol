// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";

import "./interfaces/IKingzInTheShell.sol";

interface IKaijuKingz is IERC721Enumerable, IERC721Metadata {}

interface IScales {
    struct AccountInfo {
        uint16 shares;
        uint128 lastUpdate;
        uint256 stash;
    }

    function accountInfo(address) external view returns (AccountInfo memory);
    function ownerOf(uint256) external view returns (address);
    function getAllOwned(address) external view returns (uint256[] memory);
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
contract KingzInTheShell is IERC165, IERC721Enumerable, IERC721Metadata, IKingzInTheShell {
    IKaijuKingz public immutable KAIJU;
    IScales public immutable SCALES;

    constructor(address kaiju, address scales) {
        KAIJU = IKaijuKingz(kaiju);
        SCALES = IScales(scales);
    }

    /**
     * @inheritdoc IERC721Metadata
     */
    function name() public override pure returns (string memory) { return "KingzInTheShell"; }

    /**
     * @inheritdoc IERC721Metadata
     */
    function symbol() public override pure returns (string memory) { return "KAIJU"; }

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @notice Get the combined balance of an account's staked and unstaked KAIJU
     * @param account Address of account to return balance for
     * @return uint256 Combined KAIJU balance
     */
    function balanceOf(address account) public view override returns (uint256) {
        return KAIJU.balanceOf(account) + SCALES.accountInfo(account).shares;
    }

    /**
     * @notice Return the actual owner of a KAIJU regardless of staking status
     * @param tokenId KAIJU to return the owner of
     * @return address Actual KAIJU owner
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
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
     * @inheritdoc IERC721
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return KAIJU.tokenURI(tokenId);
    }

    /*
     * @inheritdoc IERC721Enumerable
     */
    function totalSupply() public override view returns (uint256) {
        return KAIJU.totalSupply();
    }

    /*
     * @inheritdoc IERC721Enumerable
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        uint256 unstakedBalance = KAIJU.balanceOf(owner);

        if (index < unstakedBalance) {
            return KAIJU.tokenOfOwnerByIndex(owner, index);
        } else {
            uint256 stakedIndex = index - unstakedBalance;

            if (stakedIndex >= SCALES.accountInfo(owner).shares) revert();

            return SCALES.getAllOwned(owner)[stakedIndex];
        }
    }

    /*
     * @inheritdoc IERC721Enumerable
     */
    function tokenByIndex(uint256 index) public override view returns (uint256) {
        if (index >= KAIJU.totalSupply()) revert();
        return index;
    }

    /*
     * @inheritdoc IERC721
     */
    function getApproved(uint256 tokenId) public override view returns (address) {
        return KAIJU.getApproved(tokenId);
    }

    /*
     * @inheritdoc IERC721
     */
    function isApprovedForAll(address owner, address operator) public override view returns (bool) {
        return KAIJU.isApprovedForAll(owner, operator);
    }

    /*
     * @notice Override ERC721 transfer and approve functions to be noops
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public override {}
    function safeTransferFrom(address from, address to, uint256 tokenId) public override {}
    function transferFrom(address from, address to, uint256 tokenId) public override {}
    function approve(address to, uint256 tokenId) public override {}
    function setApprovalForAll(address operator, bool _approved) public override {}
}