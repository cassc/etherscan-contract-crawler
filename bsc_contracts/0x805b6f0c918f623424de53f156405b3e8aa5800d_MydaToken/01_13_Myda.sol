// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

// MydaToken.
contract MydaToken is Initializable, ContextUpgradeable, ERC20Upgradeable, UUPSUpgradeable, OwnableUpgradeable {

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @dev default constructor
     */
    function initialize() public initializer {
        
        __ERC20_init("Myda Coin", "MYDA");
        __Ownable_init();
        __UUPSUpgradeable_init();
        _mint(owner(), 100000000 * 1e18);
    }

}