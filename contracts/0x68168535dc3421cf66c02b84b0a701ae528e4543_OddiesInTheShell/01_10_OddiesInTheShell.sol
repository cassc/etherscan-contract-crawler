// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IBoba {
    function getAllOwned(address) external view returns (uint256[] memory);
    function ownerOf(uint256) external view returns (address);
}

/**                                        ..',;;::::;;,'..
 *                                   .':oxkOOOOOkkkkkkOOOOOkxl:'.
 *                               .,lxO0kxdddddxxxxxxxxxxdddddxk0Oxl,.
 *                             ,oO0kdoodkOOOkxollcccclloxkO0Okdoodk0Oo,.
 *                          .ckKkolokKKxl;..              ..,cdO0kolokKOc.
 *                        .l0KdclkXMMWKkxol:,..                .'lOKklcdK0l.
 *                       :OKd:l0WMMMMMMMMMMMWNKko:'..              ,dK0l:dK0:
 *                     .dXk::OWMMMMMMMMMMMMMMMMMMMNX0d:.             .dKOc:kXx.
 *                    ,OXo,oNMMMMMMMMMMMMMMMMMMMMMMMMMWKx;.            ,kXd,lKO,
 *                   ;0Kc,kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0l.           .oXk,cK0;
 *                  ,0K:'kWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo.           lXO,:K0,
 *                 .kNl.dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKl.         .oNx.lNk.
 *                 lNk.:XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWO,         .kNc.xNl
 *                .OX:.kMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXl.        :XO.:XO.
 *                :XO.,KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNd.       .OX;.OX:
 *                lNx.:NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.      .xNc.dNl
 *                oWo.cNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd.     .xNl.oWo
 *                oWd.:XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNl     .kNc.dWo
 *                cNk.'0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK;    '0K,.kNc
 *                ,KK,.dWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx.   lNx.,KK,
 *                .dNo.,0MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:  ,0K;.oNd.
 *                 ,KK; cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWd..kXl.,KK,
 *                  cXO..lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM0lkXo..kXl
 *                  .oXk..cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXl..xXo.
 *                   .oXO' ;OWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0; 'kXo.
 *                     cK0:..lKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo..:0Kc
 *                      'kXx' .oKWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWKo' .dXO,
 *                       .:OKd' .:kXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXkc.   .kNk.
 *                         .cOKx:...cx0NWMMMMMMMMMMMMMMMMMMMMWN0xc'       .oX0:
 *                           .;d00d:...':oxOKXNWWWWMWWWNXKOkdol::clodxxkkkkOXMNd.
 *                              .:dO0ko:'.....',;;;;;;:loddxOOOOkxdolc:;;;;;:l0Wd.
 *                                 .'cdkO0Oo.    .;clxO0Oxoc;'..            .l0K:
 *                                      .lXK:.:dO0Okdl;..               .,lk0Ol.
 *                                       :XN00Od:.                 .':ok00kl,.
 *                                       lWNx,.             ..,:ldkOOkdc,.
 *                                       cXKo:;,,,;;;:clodkOOOOkdl:'.
 *                                        ,lxkkOOOkkkxxdoc:;'.. 
 * @author Augminted Labs, LLC
 * @notice Mock ERC721 for preserving Collab.Land support
 */
contract OddiesInTheShell is ERC721 {
    IERC721 public immutable ODD;
    IBoba public immutable BOBA;

    constructor(address odd, address boba) ERC721("OddiesInTheShell", "ODD") {
        ODD = IERC721(odd);
        BOBA = IBoba(boba);
    }

    /**
     * @notice Get the combined balance of an account's staked and unstaked ODD
     * @param account Address of account to return balance for
     * @return uint256 Combined ODD balance
     */
    function balanceOf(address account) public view override(ERC721) returns (uint256) {
        return ODD.balanceOf(account) + BOBA.getAllOwned(account).length;
    }

    /**
     * @notice Return the actual owner of an ODD regardless of staking status
     * @param tokenId ODD to return the owner of
     * @return address Actual ODD owner
     */
    function ownerOf(uint256 tokenId) public view override(ERC721) returns (address) {
        address owner = ODD.ownerOf(tokenId);

        return owner == address(BOBA) ? BOBA.ownerOf(tokenId) : owner;
    }
}