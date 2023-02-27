// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

interface IInkPassAdmin {
    function setMinter(address account, bool canMint) external;

    function isMinter(address account) external returns (bool);
}

contract InkPassAdmin is
    Initializable,
    OwnableUpgradeable,
    UUPSUpgradeable,
    IInkPassAdmin
{
    mapping(address => bool) public isMinter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    function setMinter(address account, bool canMint) public onlyOwner {
        isMinter[account] = canMint;
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}