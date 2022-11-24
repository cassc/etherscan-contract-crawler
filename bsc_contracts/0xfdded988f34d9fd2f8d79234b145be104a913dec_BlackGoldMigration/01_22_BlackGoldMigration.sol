// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./BlackGold.sol";
import "./BlackGoldV1.sol";

contract BlackGoldMigration is
    Initializable,
    PausableUpgradeable,
    OwnableUpgradeable,
    UUPSUpgradeable
{
    BlackGoldV1 public tokenV1;
    BlackGold public tokenV2;
    address public bonusFromAddress;
    mapping(address => bool) internal _isExcludedFromBonus;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address tokenV1_,
        address tokenV2_,
        address bonusFromAddress_,
        address[] memory excludedAddresses_
    ) public initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        tokenV1 = BlackGoldV1(tokenV1_);
        tokenV2 = BlackGold(tokenV2_);
        bonusFromAddress = bonusFromAddress_;
        _isExcludedFromBonus[bonusFromAddress] = true;
        for (uint256 i = 0; i < excludedAddresses_.length; i++) {
            _isExcludedFromBonus[excludedAddresses_[i]] = true;
        }
    }

    function migrate() external whenNotPaused {
        uint256 balance = tokenV1.balanceOf(_msgSender());
        require(balance > 0, "Migration: no tokens to migrate");
        uint256 maxTransferAmount = balance;
        // we need to take fees into account
        if (!tokenV1.isExcludedFromFee(_msgSender())) {
            // we usually divide by 1.1 to get the max transfer amount including fees
            // but solidity needs integer division, so we multiply by it's inverse 10 / 11 instead
            maxTransferAmount = (balance * 10) / 11;
        }
        tokenV1.transferFrom(_msgSender(), address(this), maxTransferAmount);
        // now we give the total initial balance they had of v1 in v2
        tokenV2.transfer(_msgSender(), balance);
        // extra 10% bonus, hooray!
        if (!_isExcludedFromBonus[_msgSender()]) {
            tokenV2.transferFrom(bonusFromAddress, _msgSender(), balance / 10);
        }
    }

    // to release v1, we will need to pause migrations, exclude this contract from fees on v1,
    // then releaseAll, then add back fees and unpause

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

    function excludeFromBonus(address account) external onlyOwner {
        _isExcludedFromBonus[account] = true;
    }

    function includeInBonus(address account) external onlyOwner {
        _isExcludedFromBonus[account] = false;
    }

    function isExcludedFromBonus(address account) external view returns (bool) {
        return _isExcludedFromBonus[account];
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}