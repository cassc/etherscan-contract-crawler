// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Contributor Virtual Lizcoin (cLIZ) ERC20 Token
 *
 * @notice cLIZ is a temporary token issued ahead of the offical (LIZ) token launch
 * On launch, each cLIZ will be redeemable 1:1 for LIZ.
 *
 */
contract ContributorVirtualLizCoin is ERC20, Ownable {
    // Don't change the 10 ** 18, to keep the token 18 decimal places
    uint256 constant _initial_supply = 17500000 * (10 ** 18);

    address constant lizardDaoTreasury = 0x5Ac6Ebe70a98b985eb53aEdC038c933d1315eAC6;

    constructor() ERC20("Contributor Virtual LizCoin", "cLIZ") {
        _mint(lizardDaoTreasury, _initial_supply);
    }

    /// @notice ensure input is in 18 decimal points as token is 18dp
    function mintAdditional(uint256 _amount) external onlyOwner {
        _mint(lizardDaoTreasury, _amount);
    }
}