// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Booster.sol";
import "../piglet/IPigletz.sol";

contract SpecialBooster is Booster {
    constructor(IPigletz pigletz, uint256 boost) Booster(pigletz, boost, 1) {
        _pigletz = pigletz;
    }

    function getName() external view virtual override returns (string memory) {
        return "Special Piglet Booster";
    }

    function getRequirements()
        external
        view
        virtual
        override
        returns (string memory description, uint256[] memory values)
    {
        values = new uint256[](0);
        return ("Piglet is Special", values);
    }

    function isReady(uint256 tokenId) public view virtual override returns (bool) {
        return _pigletz.isSpecial(tokenId);
    }

    function isLocked(uint256 tokenId) public view virtual override returns (bool) {
        return !_pigletz.isSpecial(tokenId);
    }

    function isBoosted(uint256 tokenId) public view virtual override returns (bool) {
        return _pigletz.isSpecial(tokenId);
    }
}