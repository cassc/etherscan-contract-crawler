// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './CosmicBloomBase.sol';
import './CosmicBloomSplitsAndRoyalties.sol';

/**
 * @title CosmicBloom
 *     _______      ,-----.       .-'''-. ,---.    ,---..-./`)     _______
 *    /   __  \   .'  .-,  '.    / _     \|    \  /    |\ .-.')   /   __  \
 *   | ,_/  \__) / ,-.|  \ _ \  (`' )/`--'|  ,  \/  ,  |/ `-' \  | ,_/  \__)
 * ,-./  )      ;  \  '_ /  | :(_ o _).   |  |\_   /|  | `-'`"`,-./  )
 * \  '_ '`)    |  _`,/ \ _/  | (_,_). '. |  _( )_/ |  | .---. \  '_ '`)
 *  > (_)  )  __: (  '\_/ \   ;.---.  \  :| (_ o _) |  | |   |  > (_)  )  __
 * (  .  .-'_/  )\ `"/  \  ) / \    `-'  ||  (_,_)  |  | |   | (  .  .-'_/  )
 *  `-'`-'     /  '. \_/``".'   \       / |  |      |  | |   |  `-'`-'     /
 *    `._____.'     '-----'      `-...-'  '--'      '--' '---'    `._____.'
 *       _______     .---.       ,-----.        ,-----.    ,---.    ,---.
 *      \  ____  \   | ,_|     .'  .-,  '.    .'  .-,  '.  |    \  /    |
 *      | |    \ | ,-./  )    / ,-.|  \ _ \  / ,-.|  \ _ \ |  ,  \/  ,  |
 *      | |____/ / \  '_ '`) ;  \  '_ /  | :;  \  '_ /  | :|  |\_   /|  |
 *      |   _ _ '.  > (_)  ) |  _`,/ \ _/  ||  _`,/ \ _/  ||  _( )_/ |  |
 *      |  ( ' )  \(  .  .-' : (  '\_/ \   ;: (  '\_/ \   ;| (_ o _) |  |
 *      | (_{;}_) | `-'`-'|___\ `"/  \  ) /  \ `"/  \  ) / |  (_,_)  |  |
 *      |  (_,_)  /  |        \'. \_/``".'    '. \_/``".'  |  |      |  |
 *      /_______.'   `--------`  '-----'        '-----'    '--'      '--'
 */
contract CosmicBloom is CosmicBloomSplitsAndRoyalties, CosmicBloomBase {
    constructor()
        CosmicBloomBase(
            'CosmicBloom',
            'CSBL',
            'https://api.dr3amlabs.xyz/api/v1/cosmic-bloom/metadata/', // Instant Reveal Service
            addresses,
            splits,
            0.8 ether,
            0.8 ether,
            0.8 ether
        )
    {
        // Implementation version: v1.0.0
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}