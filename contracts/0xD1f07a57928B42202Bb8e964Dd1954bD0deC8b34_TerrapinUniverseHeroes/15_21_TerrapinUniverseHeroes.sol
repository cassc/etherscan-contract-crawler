//SPDX-License-Identifier: MIT

/*
 ***************************************************************************************************************************
 *                                                                                                                         *
 * ___________                                     .__           ____ ___        .__                                       *
 * \__    ___/____ _______ _______ _____   ______  |__|  ____   |    |   \ ____  |__|___  __  ____ _______  ______  ____   *
 *   |    | _/ __ \\_  __ \\_  __ \\__  \  \____ \ |  | /    \  |    |   //    \ |  |\  \/ /_/ __ \\_  __ \/  ___/_/ __ \  *
 *   |    | \  ___/ |  | \/ |  | \/ / __ \_|  |_> >|  ||   |  \ |    |  /|   |  \|  | \   / \  ___/ |  | \/\___ \ \  ___/  *
 *   |____|  \___  >|__|    |__|   (____  /|   __/ |__||___|  / |______/ |___|  /|__|  \_/   \___  >|__|  /____  > \___  > *
 *               \/                     \/ |__|             \/                \/                 \/            \/      \/  *
 *                                                                                                                         *
 ***************************************************************************************************************************
 */

pragma solidity ^0.8.9;

import "./interfaces/TerrapinUniverse.sol";

/**
 * @title Terrapin Universe Heroes
 *
 * @notice ERC-721 NFT Token Contract
 *
 * @author 0x1687572416fdd591bcc710fa07cee94a76eea201681884b1d5cc528cba584815
 */
contract TerrapinUniverseHeroes is TerrapinUniverse {
    constructor(
        TerrapinGenesis terrapinGenesis_,
        TerrapinUniverseCardPack terrapinUniverseHeroesCardPack_,
        string memory baseURI_,
        address[] memory operators
    )
        TerrapinUniverse(
            "TerrapinUniverseHeroes",
            "TUH",
            terrapinGenesis_,
            terrapinUniverseHeroesCardPack_,
            baseURI_,
            operators
        )
    {}
}