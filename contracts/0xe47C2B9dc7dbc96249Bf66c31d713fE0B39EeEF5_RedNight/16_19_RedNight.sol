// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {ERC1155Base} from "./ERC1155Base.sol";
import {RED_NIGHT_ID} from "./Constants.sol";
import {IRedNight} from "./interfaces/IRedNight.sol";

/**
 * @author Fount Gallery
 * @title  Tormius 23: "Red Night"
 * @notice
 * Features:
 *   - Red Night Open Edition
 *   - Shared metadata contract with the 1/1 from the same collection
 *   - On-chain royalties standard (EIP-2981)
 *   - Support for OpenSea's Operator Filterer to allow royalties
 */
contract RedNight is IRedNight, ERC1155Base {
    /* ------------------------------------------------------------------------
       I N I T
    ------------------------------------------------------------------------ */

    /**
     * @param owner_ The owner of the contract
     * @param payments_ The address where payments should be sent
     * @param royaltiesAmount_ The royalty percentage with two decimals (10,000 = 100%)
     * @param metadata_ The initial metadata contract address
     */
    constructor(
        address owner_,
        address payments_,
        uint256 royaltiesAmount_,
        address metadata_
    ) ERC1155Base(owner_, payments_, royaltiesAmount_, metadata_) {}

    /* ------------------------------------------------------------------------
       M I N T
    ------------------------------------------------------------------------ */

    /**
     * @notice Mints an edition of "Red Night"
     * @dev Only approved addresses can mint, for example the sale contract
     * @param to The address to mint to
     */
    function mintRedNight(address to) external {
        require(approvedMinters[msg.sender], "Only approved addresses can mint");
        _mint(to, RED_NIGHT_ID, 1, "");
    }
}