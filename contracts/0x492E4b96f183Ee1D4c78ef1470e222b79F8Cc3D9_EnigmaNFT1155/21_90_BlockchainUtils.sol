// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

library BlockchainUtils {
    // @dev When migrating to 0.8.0 ideally we should replace this by block.chainId
    function getChainID() internal pure returns (uint256) {
        uint256 id;
        //solhint-disable-next-line
        assembly {
            id := chainid()
        }
        return id;
    }
}