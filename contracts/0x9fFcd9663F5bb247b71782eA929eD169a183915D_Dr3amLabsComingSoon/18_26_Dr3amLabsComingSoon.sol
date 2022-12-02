// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import './Dr3amLabsComingSoonBase.sol';
import './Dr3amLabsComingSoonSplitsAndRoyalties.sol';

/**
 * @title Dr3amLabsComingSoon
 *             ____  ____
 *            / /\ \/ /\ \
 *           / /  \  /  \ \
 *          / /   /  \   \ \
 *         /_/   /_/\_\   \_\
 *         \ \   \ \/ /   / /
 *          \ \   \  /   / /
 *           \ \  /  \  / /
 *            \_\/_/\_\/_/
 *   ____  _ __  ____    _    __  __
 *  |  _ \|  _ \|___ /  / \  |  \/  |
 *  | | | | |_) | |_ \ / _ \ | |\/| |
 *  | |_| |  _ < ___) / ___ \| |  | |
 *  |____/|_| \_\____/_/___\_\_|  |_|
 *     | |      / \  | __ ) ___|
 *     | |     / _ \ |  _ \___ \
 *     | |___ / ___ \| |_) |__) |
 *     |_____/_/   \_\____/____/
 */
contract Dr3amLabsComingSoon is Dr3amLabsComingSoonSplitsAndRoyalties, Dr3amLabsComingSoonBase {
    constructor()
        Dr3amLabsComingSoonBase(
            'Dr3amLabsComingSoon',
            'DR3AM',
            'https://nftculture.mypinata.cloud/ipfs/QmRJ5xKPM87JZSrtUdmk1t5r7cNSCQgrbQXEzyzXXULYe7/', // Dr3amLabs-ComingSoon_METADATA_V1
            addresses,
            splits,
            0.069 ether
        )
    {
        // Implementation version: v1.0.0
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }
}