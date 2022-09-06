// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IVotiumRegistry {
    struct Registry {
        uint256 start;
        address to;
        uint256 expiration;
    }

    function registry(address _from)
        external
        view
        returns (Registry memory registry);

    function setRegistry(address _to) external;
}