// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @title: Bottega Manifesto
/// @author: manifold.xyz

import "./ERC1155Creator.sol";

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                                                                                               //
//                                                                                                                                                                                               //
//                                                                                                                                                                                               //
//    #                                                                                                                                                                                          //
//    #  8 888888888o       ,o888888o.     8888888 8888888888 8888888 8888888888 8 8888888888        ,o888888o.             .8.                                                                  //
//    #  8 8888    `88.  . 8888     `88.         8 8888             8 8888       8 8888             8888     `88.          .888.                                                                 //
//    #  8 8888     `88 ,8 8888       `8b        8 8888             8 8888       8 8888          ,8 8888       `8.        :88888.                                                                //
//    #  8 8888     ,88 88 8888        `8b       8 8888             8 8888       8 8888          88 8888                 . `88888.                                                               //
//    #  8 8888.   ,88' 88 8888         88       8 8888             8 8888       8 888888888888  88 8888                .8. `88888.                                                              //
//    #  8 8888888888   88 8888         88       8 8888             8 8888       8 8888          88 8888               .8`8. `88888.                                                             //
//    #  8 8888    `88. 88 8888        ,8P       8 8888             8 8888       8 8888          88 8888   8888888    .8' `8. `88888.                                                            //
//    #  8 8888      88 `8 8888       ,8P        8 8888             8 8888       8 8888          `8 8888       .8'   .8'   `8. `88888.                                                           //
//    #  8 8888    ,88'  ` 8888     ,88'         8 8888             8 8888       8 8888             8888     ,88'   .888888888. `88888.                                                          //
//    #  8 888888888P       `8888888P'           8 8888             8 8888       8 888888888888      `8888888P'    .8'       `8. `88888.                                                         //
//    #            .         .                                                                                                                                                                   //
//    #           ,8.       ,8.                   .8.          b.             8  8 8888 8 8888888888   8 8888888888      d888888o.   8888888 8888888888     ,o888888o.                           //
//    #          ,888.     ,888.                 .888.         888o.          8  8 8888 8 8888         8 8888          .`8888:' `88.       8 8888        . 8888     `88.                         //
//    #         .`8888.   .`8888.               :88888.        Y88888o.       8  8 8888 8 8888         8 8888          8.`8888.   Y8       8 8888       ,8 8888       `8b                        //
//    #        ,8.`8888. ,8.`8888.             . `88888.       .`Y888888o.    8  8 8888 8 8888         8 8888          `8.`8888.           8 8888       88 8888        `8b                       //
//    #       ,8'8.`8888,8^8.`8888.           .8. `88888.      8o. `Y888888o. 8  8 8888 8 888888888888 8 888888888888   `8.`8888.          8 8888       88 8888         88                       //
//    #      ,8' `8.`8888' `8.`8888.         .8`8. `88888.     8`Y8o. `Y88888o8  8 8888 8 8888         8 8888            `8.`8888.         8 8888       88 8888         88                       //
//    #     ,8'   `8.`88'   `8.`8888.       .8' `8. `88888.    8   `Y8o. `Y8888  8 8888 8 8888         8 8888             `8.`8888.        8 8888       88 8888        ,8P                       //
//    #    ,8'     `8.`'     `8.`8888.     .8'   `8. `88888.   8      `Y8o. `Y8  8 8888 8 8888         8 8888         8b   `8.`8888.       8 8888       `8 8888       ,8P                        //
//    #   ,8'       `8        `8.`8888.   .888888888. `88888.  8         `Y8o.`  8 8888 8 8888         8 8888         `8b.  ;8.`8888       8 8888        ` 8888     ,88'                         //
//    #  ,8'         `         `8.`8888. .8'       `8. `88888. 8            `Yo  8 8888 8 8888         8 888888888888  `Y8888P ,88P'       8 8888           `8888888P'                           //
//                                                                                                                                                                                               //
//                                                                                                                                                                                               //
//                                                                                                                                                                                               //
//    # Vision                                                                                                                                                                                   //
//    Bottega è un collettivo decentralizzato di artisti, collezionisti, curatori, critici, scrittori, sviluppatori, appassionati di arte, blockchain e nuove tecnologie.                        //
//    La nostra azione è focalizzata ed ispirata al movimento della “Crypto Arte” ed esploriamo ogni tipo di espressione artistica contemporanea.                                                //
//    Il coraggio, l'audacia, l’indipendenza sono elementi essenziali della nostra poesia.                                                                                                       //
//    Esaltiamo il valore dell’espressione individuale, tramite la creatività.                                                                                                                   //
//    Abbracciamo il concetto di decentralizzazione sia artistica che finanziaria che dell’intelletto.                                                                                           //
//    Riaffermiamo il valore della proprietà intellettuale, del pensiero critico individuale, e                                                                                                  //
//    promuoviamo il raggiungimento dell’ indipendenza economica per ogni Artista.                                                                                                               //
//    Vogliamo che l’Arte sia fruibile e alla portata di tutti, non destinata ad un circuito elitario, svincolata dalle convenzioni speculative del mercato contemporaneo e main stream,         //
//    riportando l’artista e il suo lavoro al centro dell’attenzione, senza intermediazioni, favorendo uno scambio reale e diretto con appassionati e collezionisti.                             //
//    Bottega è un centro di scambio ideale e culturale, con il fine di promuovere e divulgare l’arte attraverso canali di informazione e comunicazione non esclusivamente canonici,             //
//    utilizzando nuove tecnologie quali NFT, blockchain, AR,VR, AI.                                                                                                                             //
//    Bottega si promuove come parte attiva dello sviluppo e dell’innovazione del web3, dando sempre risalto alla concettualità, alla ricerca, all’ avanguardia artistica e tecnologica.         //
//    # Mission.                                                                                                                                                                                 //
//    L’ azione di Bottega si focalizza nel favorire lo sviluppo e divulgare la Crypto Arte, nonché di forgiare gli impavidi esploratori del web 3.0 presenti nel panorama italiano.             //
//    Bottega darà vita ad una delle più vaste collezioni di Cripto Artisti Italiani della storia.                                                                                               //
//    Bottega si colloca in maniera fluida, tra il concetto di movimento artistico e quello di fondazione d’arte, un hub culturale che favorisce le sinergie e lo sviluppo di progetti,          //
//    sia collettivi che individuali, che ne supporta il percorso artistico dalla sua genesi fino all’ obiettivo finale.                                                                         //
//    L’impegno organico da parte dei membri e dei collaboratori sarà la linfa vitale per costituire un luogo di importanza e di rilevanza nel panorama artistico italiano ed internazionale.    //
//    Bottega è un movimento in movimento, l'eterogeneità è la nostra omogeneità.                                                                                                                //
//                                                                                                                                                                                               //
//    //ENG                                                                                                                                                                                      //
//                                                                                                                                                                                               //
//    # Vision                                                                                                                                                                                   //
//    Bottega is a decentralized collective of artists, collectors, curators, critics, writers, and developers, who are passionate about art, blockchain, and new technologies.                  //
//    Our action is focused and inspired by the 'Crypto Art' movement and we explore all kinds of contemporary artistic expression.                                                              //
//    Courage, boldness, and independence are essential elements of our poetry.                                                                                                                  //
//    We exalt the value of individual expression through creativity.                                                                                                                            //
//    We embrace the concept of Decentralisation, both artistic and financial, and of the intellect.                                                                                             //
//    We reaffirm the value of intellectual property, and individual critical thinking, and promote the achievement of economic independence for every artist.                                   //
//    We want Art to be usable and within everyone's reach, not destined for an elitist circuit, freed from the speculative conventions of the contemporary and mainstream market,               //
//    bringing the artist and his work back to the center of attention, without intermediaries, fostering a real and direct exchange with enthusiasts and collectors.                            //
//    Bottega is a center for ideas and cultural exchange, with the aim of promoting and disseminating art through not exclusively canonical information and communication channels,             //
//    using new technologies such as NFTs, Blockchain, AR,VR, AI.                                                                                                                                //
//    Bottega promotes itself as an active part of Web 3 development and innovation, always emphasizing conceptuality, research, and the artistic and technological avant-garde.                 //
//    # Mission                                                                                                                                                                                  //
//    Bottega's action focuses on facilitating the development and divulgation of Crypto Art, as well as forging fearless explorers of Web 3.0 on the Italian scene.                             //
//    Bottega will create one of the largest collections of Italian Crypto Artists in history.                                                                                                   //
//    Bottega sits fluidly between the concept of an art movement and that of an art foundation, a cultural hub that fosters synergies and the development of projects,                          //
//    both collective and individual, supporting the artistic journey from its genesis to its final goal.                                                                                        //
//    The workforce of the members and collaborators will be the lifeblood of a place of importance and relevance in the Italian and international art scene.                                    //
//    Bottega is a movement in motion; heterogeneity is our homogeneity.                                                                                                                         //
//                                                                                                                                                                                               //
//                                                                                                                                                                                               //
//                                                                                                                                                                                               //
//                                                                                                                                                                                               //
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


contract BTG is ERC1155Creator {
    constructor() ERC1155Creator() {}
}