// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract EqbToken is ERC20Upgradeable, OwnableUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _incentivesAddr,
        address _othersAddr
    ) public initializer {
        __Ownable_init();

        __ERC20_init_unchained("Equilibria Token", "EQB");

        _mint(_incentivesAddr, 735e23);
        _mint(_othersAddr, 265e23);
    }
}