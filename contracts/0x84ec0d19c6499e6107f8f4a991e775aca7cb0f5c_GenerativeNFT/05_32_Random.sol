// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

library Random {
    using SafeMathUpgradeable for uint256;

    function randomSeed(address msgSender, uint256 projectId, uint256 index) internal view returns (bytes32){
        return keccak256(abi.encodePacked(blockhash(block.number - 1), msgSender, projectId, index));
    }

    function randomValueIndexArray(uint256 seed, uint256 n) internal view returns (uint256) {
        return seed % n;
    }

    function randomValueRange(uint256 seed, uint256 min, uint256 max) internal view returns (uint256) {
        return (min + seed % (max - min + 1));
    }
}