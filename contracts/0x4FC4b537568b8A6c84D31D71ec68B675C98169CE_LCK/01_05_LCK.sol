// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Live on Crypto KEY
/// @author: manifold.xyz

import "./manifold/ERC721Creator.sol";

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                              //
//                                                                                                                                                              //
//     ///////////////////////////////////////////////////////////////////////////////////////////                                                              //
//     //|$|   (_)_   _____    ___  _ __    /$$$$|_ __ _   _ _ __ | |_ ___   |$|/$/  ___\ \ / / //                                                              //
//     //|$|   | \ \ / / _ \  / _ \| '_ \  |$|   | '__| | | | '_ \| __/ _ \  |$'$/|  _|  \ V /  //                                                              //
//     //|$|___| |\ V /  __/ | (_) | | | | |$|___| |  | |_| | |_) | || (_) | |$.$\| |___  | |   //                                                              //
//     //|$ $ $|_| \_/ \___|  \___/|_| |_|  \$$$$|_|   \__, | .__/ \__\___/  |$|\$\_____| |_|   //                                                              //
//     ///////////////////////////////////////////////////|_|/////////////////////////////////////                                                              //
//                                                                                                                                                              //
//     Essa  é a  chave  que dá acesso ao seu caminho pela busca da liberdade financeira na WEB3 e                                                              //
//     em DeFi. LCK é seu token de acesso a Comunidade Viver de Cripto, uma  comunidade  focada no                                                              //
//     estudo e no desenvolvimento dentro deste ambiente digital. Existirão apenas 777 tokens LCK,                                                              //
//     sendo divididos em 3 tiers: Ouro, Prata e Bronze, sendo 7  Ouro, 70  Prata  e  700  Bronze.                                                              //
//                                                                       Iniciada por Taylor Costa                                                              //
//                                  VENHA ESTUDAR COM A GENTE!                                                                                                  //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//                                                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract LCK is ERC721Creator {
    constructor() ERC721Creator("Live on Crypto KEY", "LCK") {}
}