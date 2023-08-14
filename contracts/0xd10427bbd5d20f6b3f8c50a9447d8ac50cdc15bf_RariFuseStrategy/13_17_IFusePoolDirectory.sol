// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;

interface IFusePoolDirectory {
    function pools(uint256)
        external
        view
        returns (
            string memory name,
            address creator,
            address comptroller,
            uint256 blockPosted,
            uint256 timestampPosted
        );
}