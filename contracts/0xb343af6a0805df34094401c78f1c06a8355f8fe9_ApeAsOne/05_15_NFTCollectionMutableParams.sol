// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../NFTCollection.sol";

abstract contract NFTCollectionMutableParams is NFTCollection {
    function setCost(uint256 _cost) external onlyOwner {
        cost = _cost;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }
}