// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    ERC721PartnerSeaDropBurnable
} from "../extensions/ERC721PartnerSeaDropBurnable.sol";


/**
 * @notice This contract uses ERC721PartnerSeaDropBurnable,
 *         an ERC721A token contract that is compatible with SeaDrop,
 *         along with a burn function only callable by the token owner.
 */
contract DayAwayFoundersKey is ERC721PartnerSeaDropBurnable {
    /**
     * @notice Deploy the token contract with its name, symbol,
     *         administrator, and allowed SeaDrop addresses.
     */
    constructor(
        string memory name,
        string memory symbol,
        address administrator,
        address[] memory allowedSeaDrop
    )
        ERC721PartnerSeaDropBurnable(
            name,
            symbol,
            administrator,
            allowedSeaDrop
        )
    {}
}