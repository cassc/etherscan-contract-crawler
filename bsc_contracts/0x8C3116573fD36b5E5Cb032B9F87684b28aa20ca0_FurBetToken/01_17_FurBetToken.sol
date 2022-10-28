// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./abstracts/BaseContract.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * @title FurBet Token
 * @notice This is the ERC20 contract for $FURBET.
 */

/// @custom:security-contact [email protected]
contract FurBetToken is BaseContract, ERC20Upgradeable
{
    /**
     * Contract initializer.
     * @dev This intializes all the parent contracts.
     */
    function initialize() initializer public
    {
        __BaseContract_init();
        __ERC20_init("FurBet", "$FURB");
    }

    /**
     * Mint.
     * @param to_ The address to mint to.
     * @param quantity_ The token quantity to mint.
     */
    function mint(address to_, uint256 quantity_) external {
        require(_canMint(msg.sender), "FurBetToken: Unauthorized");
        super._mint(to_, quantity_);
    }

    /**
     * Can mint?
     * @param address_ Address of sender.
     * @return bool True if trusted.
     */
    function _canMint(address address_) internal view returns (bool)
    {
        if(address_ == owner()) {
            return true;
        }
        if(address_ == addressBook.get("furbetpresale")) {
            return true;
        }
        if(address_ == addressBook.get("furbetstake")) {
            return true;
        }
        if(address_ == addressBook.get("furmax")) {
            return true;
        }
        return false;
    }
}