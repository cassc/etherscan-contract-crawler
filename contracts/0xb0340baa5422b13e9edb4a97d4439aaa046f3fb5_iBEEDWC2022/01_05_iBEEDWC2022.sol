// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: iBEED | World Cup Catar 2022
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
//    Acreditamos que NFTs contam histórias e durante a Copa do Mundo no Catar 2022 fizemos POAPs para registrar presença em cada jogo do Brasil junto a iBEED.                                                                                              //
//                                                                                                                                                                                                                                                           //
//    Visto isso, o fundador da iBEED, viniciusbedum.eth decidiu criar um NFT único e exclusivo registrado na Blockchain da Ethereum para presentear todas as pessoas estiveram juntos com a iBEED torcendo pelo Brasil e que coletaram todos os 4 POAPs.    //
//                                                                                                                                                                                                                                                           //
//    Esse NFT totalmente exclusivo vai desbloquear experiências, benefícios e acesso a canais exclusivos dentro do ecossistema da iBEED. Se você é holder de algum, guarde com muito carinho pois valorizamos muito que acredita em nós.                    //
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
//    ___                                                                                                                                                                                                                                                    //
//                                                                                                                                                                                                                                                           //
//    We believe that NFTs tell stories and during the World Cup in Qatar 2022 we made POAPs to register presence in each game in Brazil with iBEED.                                                                                                         //
//                                                                                                                                                                                                                                                           //
//    Given this, the founder of iBEED, viniciusbedum.eth decided to create a unique and exclusive NFT registered on the Ethereum Blockchain to present all the people who were together with iBEED cheering for Brazil and who collected all 4 POAPs.       //
//                                                                                                                                                                                                                                                           //
//    This totally exclusive NFT will unlock experiences, benefits and access to exclusive channels within the iBEED ecosystem. If you are a holder of one, keep it with great affection because we greatly appreciate that you believe in us.               //
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
//    1 POAP: Jogo do Brasil x Suíça: https://poap.gallery/event/87871                                                                                                                                                                                       //
//    2 POAP: Jogo do Brasil x Camarões: https://poap.gallery/event/87977                                                                                                                                                                                    //
//    3 POAP: Jogo do Brasil x Coréia do Sul: https://poap.gallery/event/88925                                                                                                                                                                               //
//    4 POAP: Jogo do Brasil x Croácia: https://poap.gallery/event/90546                                                                                                                                                                                     //
//                                                                                                                                                                                                                                                           //
//                                                                                                                                                                                                                                                           //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract iBEEDWC2022 is ERC721Creator {
    constructor() ERC721Creator("iBEED | World Cup Catar 2022", "iBEEDWC2022") {}
}