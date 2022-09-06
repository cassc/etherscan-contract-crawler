// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { IMembershipsMetadataRegistry } from "./interfaces/IMembershipsMetadataRegistry.sol";

/// @title MembershipsMetadataRegistry
/// @author Coinvise
/// @notice Registry contract for changing `_baseTokenURI` in Memberships V1
/// @dev Owned by Coinvise to control changes to `_baseTokenURI` for Memberships V1 proxies.
///      Used by `Memberships.changeBaseTokenURI()` to fetch allowed baseURI
contract MembershipsMetadataRegistry is Ownable, IMembershipsMetadataRegistry {
    /// @notice Mapping to store baseTokenURI for each Memberships proxy: membershipsProxyAddress => baseTokenURI
    mapping(address => string) public baseTokenURI;

    /// @notice Set baseTokenURI for a Memberships Proxy
    /// @dev Callable only by `owner`.
    /// @param _membershipsProxy address of Memberships proxy to set `_baseTokenURI`
    /// @param _baseTokenURI baseTokenURI string to set for `_membershipsProxy`
    function setBaseTokenURI(address _membershipsProxy, string calldata _baseTokenURI) public onlyOwner {
        baseTokenURI[_membershipsProxy] = _baseTokenURI;
    }
}