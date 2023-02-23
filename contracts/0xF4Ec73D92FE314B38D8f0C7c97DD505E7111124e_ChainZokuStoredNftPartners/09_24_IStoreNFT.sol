// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com

interface IStoreNFT {
    function TransferExternal(address _to, address _partnerAddress, uint256 _id, uint256 _count) external;
    function TransferBatchExternal(address _to, address _partnerAddress, uint256[] calldata _ids, uint256[] calldata _counts) external;
    function balanceOf(address _partnerAddress) external returns(uint256);
    function balanceOf(address _partnerAddress, uint256 _id) external returns(uint256);
}