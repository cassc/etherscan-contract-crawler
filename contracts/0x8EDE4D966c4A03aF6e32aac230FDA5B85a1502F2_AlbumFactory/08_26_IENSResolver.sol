// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

// Pared down from https://github.com/ensdomains/ens-contracts/blob/master/contracts/resolvers/PublicResolver.sol

interface IENSResolver {
    function multicall(bytes[] calldata data)
        external
        returns (bytes[] memory results);
}