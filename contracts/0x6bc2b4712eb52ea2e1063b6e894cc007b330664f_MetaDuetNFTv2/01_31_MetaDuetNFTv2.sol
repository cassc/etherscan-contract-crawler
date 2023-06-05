// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {
    ERC721SeaDropUpgradeable
} from "./ERC721SeaDropUpgradeable.sol";

/*
 * @notice This contract uses ERC721SeaDrop,
 *         an ERC721A token contract that is compatible with SeaDrop.
 */
contract MetaDuetNFTv2 is ERC721SeaDropUpgradeable {
    /**
     * @notice Initialize the token contract with its name, symbol,
     *         administrator, and allowed SeaDrop addresses.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    ) external initializer initializerERC721A {
        ERC721SeaDropUpgradeable.__ERC721SeaDrop_init(
            name,
            symbol,
            allowedSeaDrop
        );
    }
    function emergencyPause() public onlyOwner {
        _pause();
    }
    function emergencyUnpause() public onlyOwner {
        _unpause();
    }
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override whenNotPaused {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
    }
}