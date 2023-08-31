//SPDX-License-Identifier: Unlicense

pragma solidity 0.8.9;

import {
    ERC20Votes,
    ERC20Permit,
    ERC20
} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @dev An ERC20 contract having 18 decimals and total fixed supply of
 * 1 Billion tokens.
 */
contract MetaMonopoly is ERC20Votes {

    // CAP of total supply.
    uint256 public immutable CAP;

    // Private pre-sale address
    address public immutable privatePreSale;

    // Public pre-sale address
    address public immutable publicPreSale;

    // Marketing funds address.
    address public immutable marketing;

    // Development funds address.
    address public immutable development;

    // Locked funds address.
    address public immutable lockedLiquidity;

    address public immutable lockedCommunityTreasury;

    /// Initialises contract's state and mints 1 Billion tokens.
    constructor()
        ERC20Permit("Meta Monopoly")
        ERC20("Meta Monopoly", "MONOPOLY")
    {
        CAP = 1_000_000_000 * (10 ** decimals());

        privatePreSale = 0x6c3fe383df36bA16650e176eA226F1ee691be3Fc;
        publicPreSale = 0xC95b5a278f198605596EB22AEDfF06cdB9E1203c;
        marketing = 0xC32428b76d0b37bb6d3f92cfa99452ea8B36F476;
        development = 0x8beAC6dA1D9C04cDf175Cf36905B2E1225F1fC54;
        lockedLiquidity = 0xAd9Cd7579ef5c529277C6d1E16Af3bff4138ADcb;
        lockedCommunityTreasury = 0x5D3F254321C8bE0E3e3C3Bb41860190B28f394B2;

        _mint(privatePreSale, CAP * 15 / 100);
        _mint(publicPreSale, CAP * 5 / 100);
        _mint(marketing, CAP * 20 / 100);
        _mint(development, CAP * 10 / 100);
        _mint(lockedLiquidity, CAP * 15 / 100);
        _mint(lockedCommunityTreasury, CAP * 35 / 100);

        assert(totalSupply() == CAP);
    }
}