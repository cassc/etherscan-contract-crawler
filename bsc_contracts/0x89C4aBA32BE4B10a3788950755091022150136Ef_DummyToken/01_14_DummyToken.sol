// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../helpers/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract DummyToken is ERC20BurnableUpgradeable, UUPSUpgradeable, OwnableUpgradeable {

    function initialize(string memory name, string memory symbol, uint256 initialSupply, address _owner) external {
        _mint(_owner, initialSupply);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}