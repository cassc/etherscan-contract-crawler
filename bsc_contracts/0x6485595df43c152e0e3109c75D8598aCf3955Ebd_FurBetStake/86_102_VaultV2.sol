// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

/**
 * @title Furio Vault
 * @author Steve Harmeyer
 * @notice This is the Furio vault contract.
 */

/// @custom:security-contact [email protected]
contract VaultV2 is BaseContract, ERC721Upgradeable
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __ERC721_init("Furio Vault NFT", "$FURV");
        __BaseContract_init();
        _period = 1 days;
    }

    /**
     * Properties.
     */
    uint256 _period;
    uint256 _tokenId; // Token ID tracker.
}