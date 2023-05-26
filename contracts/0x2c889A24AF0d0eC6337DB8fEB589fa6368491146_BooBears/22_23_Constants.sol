// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Constants {
    /* Constants */
    uint256 private constant _WEI_PER_ETH = 10**18;
    uint16 private constant _IPFS_URI_LENGTH = 54; // len("ipfs://") == 7, len(hash) == 46, len("/") == 1, sum => 54

    function getWeiPerEth() internal pure returns (uint256) {
        return _WEI_PER_ETH;
    }

    function getIpfsUriLength() internal pure returns (uint16) {
        return _IPFS_URI_LENGTH;
    }
}