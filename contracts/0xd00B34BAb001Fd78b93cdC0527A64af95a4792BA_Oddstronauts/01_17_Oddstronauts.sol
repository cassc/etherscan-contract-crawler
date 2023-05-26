//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "../Augminted/ERC721ABase.sol";

/**
 *                                         ..',;;::::;;,'..
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
 */
contract Oddstronauts is ERC721ABase {
    uint256 public constant MAX_RESERVED = 100;
    uint256 public reserved;

    constructor(
        address signer,
        address vrfCoordinator,
        bytes32 keyHash,
        uint64 subId
    )
        ERC721ABase(
            "Oddstronauts",
            "ODD",
            10000,
            vrfCoordinator
        )
    {
        setMintPrice(0.05 ether);
        setMaxPerAddress(2);
        setSigner(signer);

        setVrfRequestConfig(VrfRequestConfig({
            keyHash: keyHash,
            subId: subId,
            callbackGasLimit: 200000,
            requestConfirmations: 20
        }));
    }

    /**
     * @notice Mint a specified amount of tokens to a specified receiver
     * @param amount Of tokens to reserve
     * @param receiver Of reserved tokens
     */
    function reserve(uint256 amount, address receiver) external onlyOwner {
        require(_totalMinted() + amount <= MAX_SUPPLY, "Insufficient total supply");
        require(reserved + amount <= MAX_RESERVED, "Insufficient reserved supply");

        _safeMint(receiver, amount);
        reserved += amount;
    }
}