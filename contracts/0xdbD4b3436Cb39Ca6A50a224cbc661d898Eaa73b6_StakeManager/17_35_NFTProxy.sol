// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

library NFTProxy {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    struct Proxies {
        mapping(address => mapping(uint256 => EnumerableSetUpgradeable.AddressSet)) _values;
    }

    function add(
        Proxies storage proxies,
        address nftAsset,
        uint256 tokenId,
        address proxy
    ) internal {
        proxies._values[nftAsset][tokenId].add(proxy);
    }

    function remove(
        Proxies storage proxies,
        address nftAsset,
        uint256 tokenId,
        address proxy
    ) internal {
        proxies._values[nftAsset][tokenId].remove(proxy);
    }

    function isEmpty(
        Proxies storage proxies,
        address nftAsset,
        uint256 tokenId
    ) internal view returns (bool) {
        return size(proxies, nftAsset, tokenId) == 0;
    }

    function size(
        Proxies storage proxies,
        address nftAsset,
        uint256 tokenId
    ) internal view returns (uint256) {
        return proxies._values[nftAsset][tokenId].length();
    }

    function values(
        Proxies storage proxies,
        address nftAsset,
        uint256 tokenId
    ) internal view returns (address[] memory) {
        return proxies._values[nftAsset][tokenId].values();
    }
}