// SPDX-License-Identifier: AGPL-3.0

pragma solidity >=0.8.0 <0.9.0;

interface IDssCdpManager {
    function open(bytes32, address) external returns (uint256);

    function urns(uint256) external view returns (address);

    function owns(uint256) external returns (address);

    function frob(
        uint256,
        int256,
        int256
    ) external;

    function move(
        uint256 cdp,
        address dst,
        uint256 rad
    ) external;

    function flux(
        uint256,
        address,
        uint256
    ) external;

    function quit(uint256 cdp, address dst) external;

    function urnAllow(address usr, uint256 ok) external;

    function give(uint256 cdp, address dst) external;

    function shift(uint256 cdpSrc, uint256 cdpDst) external;
}