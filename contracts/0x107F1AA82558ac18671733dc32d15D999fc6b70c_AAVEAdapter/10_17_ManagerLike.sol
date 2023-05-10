// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface ManagerLike {
    function cdpCan(
        address owner,
        uint256 cdpId,
        address allowedAddr
    ) external view returns (uint256);

    function vat() external view returns (address);

    function ilks(uint256) external view returns (bytes32);

    function owns(uint256) external view returns (address);

    function urns(uint256) external view returns (address);

    function open(bytes32 ilk, address usr) external returns (uint256);

    function cdpAllow(uint256 cdp, address usr, uint256 ok) external;

    function frob(uint256, int256, int256) external;

    function flux(uint256, address, uint256) external;

    function move(uint256, address, uint256) external;

    function exit(address, uint256, address, uint256) external;

    event NewCdp(address indexed usr, address indexed own, uint256 indexed cdp);
}