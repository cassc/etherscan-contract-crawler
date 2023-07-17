//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "../interfaces/IYardboisResources.sol";

contract OreConverter is Ownable, Pausable {

    uint256 public constant ORE_INDEX = uint256(keccak256("ORE"));
    uint256 public constant GEM_INDEX = uint256(keccak256("GEM"));

    IYardboisResources public immutable RESOURCES;

    uint256 public immutable GEM_PRICE;

    constructor(IYardboisResources _resources, uint256 _price) {
        RESOURCES = _resources;
        
        GEM_PRICE = _price;

        _pause();
    }

    function disableExchange() external onlyOwner {
        _pause();
    }

    function enableExchange() external onlyOwner {
        _unpause();
    }

    function exchange(uint256 _wantedGems) external whenNotPaused {
        RESOURCES.burn(msg.sender, ORE_INDEX, _wantedGems * GEM_PRICE);
        RESOURCES.mint(msg.sender, GEM_INDEX, _wantedGems);
    }
}