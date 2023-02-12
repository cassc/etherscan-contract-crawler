// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IImTravelToken {
    function initialize(
        address[2] memory addrs, // [0] = owner, [1] = router
        string memory name_,
        string memory symbol_,
        uint256 totalSupply_,
        uint256 tax_
    ) external;
}