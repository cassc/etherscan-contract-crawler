// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Booster.sol";
import "../piglet/IPigletz.sol";

contract CollectNumberBooster is Booster {
    uint256 private _numberToCollect;

    constructor(
        IPigletz pigletz,
        uint256 boost,
        uint256 numberToCollect,
        uint8 level
    ) Booster(pigletz, boost, level) {
        _pigletz = pigletz;
        _numberToCollect = numberToCollect;
    }

    function getName() external view virtual override returns (string memory) {
        return "Collect Number";
    }

    function getRequirements()
        external
        view
        virtual
        override
        returns (string memory description, uint256[] memory values)
    {
        values = new uint256[](1);
        values[0] = _numberToCollect;
        return ("Collect ${0} Piglets", values);
    }

    function isReady(uint256 tokenId) public view virtual override returns (bool) {
        address owner = _pigletz.ownerOf(tokenId);
        return _pigletz.balanceOf(owner) >= _numberToCollect && !this.isLocked(tokenId);
    }
}