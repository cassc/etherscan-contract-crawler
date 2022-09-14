// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";
import "./LibRoyalties.sol";
import "./IRoyalties.sol";

abstract contract RoyaltiesUpgradeable is ERC165StorageUpgradeable, IRoyalties {
    function __RoyaltiesUpgradeable_init_unchained() internal onlyInitializing {
       _registerRoyaltiesInterfaces();
    }

    function _registerRoyaltiesInterfaces() internal {
        _registerInterface(LibRoyalties._INTERFACE_ID_ROYALTIES);
        _registerInterface(LibRoyalties._INTERFACE_ID_RARIBLEV2);
        _registerInterface(LibRoyalties._INTERFACE_ID_MANIFOLD); 
    }
}