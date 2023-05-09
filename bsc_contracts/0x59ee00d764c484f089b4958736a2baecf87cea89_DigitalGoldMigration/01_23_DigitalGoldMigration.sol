// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./DigitalGold.sol";
import "./legacy/DigitalLinkedGoldV1.sol";

contract DigitalGoldMigration is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    DigitalLinkedGoldV1 public tokenV1;
    DigitalGold public tokenV2;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address tokenV1_, address tokenV2_) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        tokenV1 = DigitalLinkedGoldV1(tokenV1_);
        tokenV2 = DigitalGold(tokenV2_);
    }

    function migrate() external whenNotPaused {
        uint256 balance = tokenV1.balanceOf(_msgSender());
        require(balance > 0, "Migration: no tokens to migrate");
        tokenV1.transferFrom(_msgSender(), address(this), balance);
        // shift the decimals so that we get to atomic units of the v2 token
        uint8 decimalShift = tokenV1.decimals() - tokenV2.decimals();
        // 1000x the total initial balance they had of v1 in v2 tokens, shifted by the decimal shift
        uint256 tokenV2Amount = (balance / (10 ** decimalShift)) * 1000;
        tokenV2.transfer(_msgSender(), tokenV2Amount);
    }

    function releaseTokenV1To(address to, uint256 amount) public onlyOwner {
        uint256 balance = tokenV1.balanceOf(address(this));
        require(balance >= amount, "Migration: amount exceeds balance");
        tokenV1.transfer(to, amount);
    }

    function releaseAllTokenV1To(address to) public onlyOwner {
        uint256 balance = tokenV1.balanceOf(address(this));
        require(balance > 0, "Migration: no tokens to release");
        tokenV1.transfer(to, balance);
    }

    function releaseTokenV2To(address to, uint256 amount) public onlyOwner {
        uint256 balance = tokenV2.balanceOf(address(this));
        require(balance >= amount, "Migration: amount exceeds balance");
        tokenV2.transfer(to, amount);
    }

    function releaseAllTokenV2To(address to) public onlyOwner {
        uint256 balance = tokenV2.balanceOf(address(this));
        require(balance > 0, "Migration: no tokens to release");
        tokenV2.transfer(to, balance);
    }

    function burnTokenV2(uint256 amount) public onlyOwner {
        uint256 balance = tokenV2.balanceOf(address(this));
        require(balance >= amount, "Migration: burn amount exceeds balance");
        tokenV2.burn(amount);
    }

    function burnAllTokenV2() public onlyOwner {
        uint256 balance = tokenV2.balanceOf(address(this));
        require(balance > 0, "Migration: no tokens to burn");
        tokenV2.burn(balance);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}