// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../openzeppelin/ERC20Upgradeable.sol";
import "../openzeppelin/OwnableUpgradeable.sol";
import "../openzeppelin/Initializable.sol";
import "../openzeppelin/UUPSUpgradeable.sol";

contract DAMM is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("dAMM", "DAMM");
        __Ownable_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, 250000000 * 10 ** decimals());
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}