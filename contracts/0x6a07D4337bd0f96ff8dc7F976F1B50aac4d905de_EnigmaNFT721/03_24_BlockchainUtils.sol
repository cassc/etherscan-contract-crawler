// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;

import "./Types.sol";

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

    function getSigner(bytes32 hash, Signature memory signature) internal pure returns (address) {
        return
            ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
                signature.v,
                signature.r,
                signature.s
            );
    }
}