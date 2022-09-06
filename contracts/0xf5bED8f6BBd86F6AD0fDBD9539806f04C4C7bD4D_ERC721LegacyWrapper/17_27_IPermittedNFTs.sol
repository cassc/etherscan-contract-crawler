// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IPermittedNFTs {
    function setNFTPermit(address _nftContract, string memory _nftType) external;

    function getNFTPermit(address _nftContract) external view returns (bytes32);

    function getNFTWrapper(address _nftContract) external view returns (address);
}