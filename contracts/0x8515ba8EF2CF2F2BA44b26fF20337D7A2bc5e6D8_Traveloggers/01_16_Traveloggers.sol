// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./Lottery.sol";
import "./Logbook.sol";
import "./PreOrder.sol";

contract Traveloggers is Lottery, Logbook, PreOrder {
    constructor(
        string memory name_,
        string memory symbol_,
        uint16 supply_,
        string memory sharedBaseURI_
    ) BatchNFT(name_, symbol_, supply_, sharedBaseURI_) {}

    /**
     * @dev Unlock logbook on token transfer
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, Logbook) {
        super._beforeTokenTransfer(from, to, tokenId); // Call parent hook
    }
}