// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

interface IPermittedNFTs {
    function getNFTPermit(address _nftContract) external view returns (bytes32);
}