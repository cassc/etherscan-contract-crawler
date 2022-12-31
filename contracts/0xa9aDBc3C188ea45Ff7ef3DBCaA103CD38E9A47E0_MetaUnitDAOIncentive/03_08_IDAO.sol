// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDAO {
    function getDaosByOwner(address owner_of)
        external
        returns (address[] memory);

    function getDaoOwner(address dao_address)
        external
        returns (address);
}