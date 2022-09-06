// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {$8liensMeta} from "./8liensMeta.sol";

/// @title 8liensMinter
/// @author 8liens (https://twitter.com/8liensNFT)
/// @author Developer: dievardump (https://twitter.com/dievardump, [email protected])
contract $8liensMinter is $8liensMeta {
    error OnlyMinter();
    error TooManyRequested();

    uint256 private constant MINT_BUNDLE = 5;

    /// @notice the address of the minter module
    address public minter;

    constructor(
        address minter_,
        string memory contractURI_,
        address metadataManager_,
        address vrfHandler_
    ) $8liensMeta(contractURI_, metadataManager_, vrfHandler_) {
        minter = minter_;
    }

    /////////////////////////////////////////////////////////
    // Setters                                             //
    /////////////////////////////////////////////////////////

    /// @notice Allows the `minter` contract to mint new tokens to `to`
    /// @dev using the minter pattern adds a bit of gas overhead but nothing compared to the flexibility
    /// @param to to whom we need to mint
    /// @param amount how many to mint
    function mintTo(address to, uint256 amount) external {
        if (msg.sender != minter) {
            revert OnlyMinter();
        }

        // check that there is enough supply
        if (_totalMinted() + amount > MAX_SUPPLY) {
            revert TooManyRequested();
        }

        // here we make bundles of MINT_BUNDLE in order to have a mint not too expensive, but also
        // not transfer too much the cost of minting to future Transfers, which is what ERC721A does.
        if (amount > MINT_BUNDLE) {
            uint256 times = amount / MINT_BUNDLE;
            for (uint256 i; i < times; i++) {
                _mint(to, MINT_BUNDLE);
            }

            if (amount % MINT_BUNDLE != 0) {
                _mint(to, amount % MINT_BUNDLE);
            }
        } else {
            _mint(to, amount);
        }
    }

    /////////////////////////////////////////////////////////
    // Gated Owner                                         //
    /////////////////////////////////////////////////////////

    //// @notice Allows to set the minter contract
    /// @param newMinter the new minter contract
    function setMinter(address newMinter) external onlyOwner {
        minter = newMinter;
    }
}