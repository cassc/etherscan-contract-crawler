// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./Booster.sol";
import "../piglet/IPigletz.sol";

contract StakingBooster is Booster {
    constructor(IPigletz pigletz, uint256 boost) Booster(pigletz, boost, 1) {
        _pigletz = pigletz;
    }

    function getName() external view virtual override returns (string memory) {
        return "Stake Piglet";
    }

    function getRequirements()
        external
        view
        virtual
        override
        returns (string memory description, uint256[] memory values)
    {
        values = new uint256[](1);
        values[0] = 1;
        return ("Stake ${0} Piglet", values);
    }

    function isReady(uint256 tokenId) public view virtual override returns (bool) {
        address staker = _pigletz.getStaker();
        return staker != address(0) && _pigletz.ownerOf(tokenId) == staker;
    }
}