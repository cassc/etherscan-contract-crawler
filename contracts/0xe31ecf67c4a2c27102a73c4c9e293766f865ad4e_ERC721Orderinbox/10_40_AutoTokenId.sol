// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

abstract contract AutoTokenId {
    
    using CountersUpgradeable for CountersUpgradeable.Counter;
    
    // We cannot just use balanceOf to create the new tokenId because tokens
    // can be burned (destroyed), so we need a separate counter.
    CountersUpgradeable.Counter private _tokenIdTracker;

    function getNextTokenId() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    function _increment() internal {
        return _tokenIdTracker.increment();
    }

    uint256[256] private __gap;
}