// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// From 0xc9fe4ffc4be41d93a1a7189975cd360504ee361a
interface IGetRoyalties {
    function getRoyalties(uint256 tokenId)
        external
        view
        returns (
            address payable[] memory recipients,
            uint256[] memory feesInBasisPoints
        );
}