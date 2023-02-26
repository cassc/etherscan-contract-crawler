// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC721PartnerSeaDrop } from "../ERC721PartnerSeaDrop.sol";

/**
 *      _____                     ______ __  __ _____   ______          ________ _____  ______ _____
 *     |_   _|                   |  ____|  \/  |  __ \ / __ \ \        / /  ____|  __ \|  ____|  __ \
 *       | |     __ _ _ __ ___   | |__  | \  / | |__) | |  | \ \  /\  / /| |__  | |__) | |__  | |  | |
 *       | |    / _` | '_ ` _ \  |  __| | |\/| |  ___/| |  | |\ \/  \/ / |  __| |  _  /|  __| | |  | |
 *      _| |_  | (_| | | | | | | | |____| |  | | |    | |__| | \  /\  /  | |____| | \ \| |____| |__| |
 *     |_____|  \__,_|_| |_| |_| |______|_|  |_|_|     \____/   \/  \/   |______|_|  \_\______|_____/
 *      _____   ______          __         __  __          _   _    _____ _____ _________     __
 *     |  __ \ / __ \ \        / /        |  \/  |   /\   | \ | |  / ____|_   _|__   __\ \   / /
 *     | |__) | |  | \ \  /\  / /  __  __ | \  / |  /  \  |  \| | | |      | |    | |   \ \_/ /
 *     |  ___/| |  | |\ \/  \/ /   \ \/ / | |\/| | / /\ \ | . ` | | |      | |    | |    \   /
 *     | |    | |__| | \  /\  /     >  <  | |  | |/ ____ \| |\  | | |____ _| |_   | |     | |
 *     |_|     \____/   \/  \/     /_/\_\ |_|  |_/_/    \_\_| \_|  \_____|_____|  |_|     |_|
 *
 *
 * @title  ERC721PartnerSeaDropBurnable
 * @author James Wenzel (emo.eth)
 * @author Ryan Ghods (ralxz.eth)
 * @author Stephan Min (stephanm.eth)
 * @notice ERC721PartnerSeaDropBurnable is a token contract that extends
 *         ERC721PartnerSeaDrop to additionally provide a burn function.
 */
contract ERC721PartnerSeaDropBurnable is ERC721PartnerSeaDrop {
    /**
     * @notice Deploy the token contract with its name, symbol,
     *         administrator, and allowed SeaDrop addresses.
     */
    constructor(
        string memory name,
        string memory symbol,
        address administrator,
        address[] memory allowedSeaDrop
    ) ERC721PartnerSeaDrop(name, symbol, administrator, allowedSeaDrop) {}

    /**
     * @notice Burns `tokenId`. The caller must own `tokenId` or be an
     *         approved operator.
     *
     * @param tokenId The token id to burn.
     */
    // solhint-disable-next-line comprehensive-interface
    function burn(uint256 tokenId) external {
        _burn(tokenId, true);
    }
}