// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IMultiWalletCallerOperator {
    function checkHolder (address _from) external view;
    function checkId (uint256 _startId, uint256 _endId, address _from) external view;
    function createWallets (uint256 _quantity, address _from) external;
    function sendERC20 (uint256 _startId, uint256 _endId, address _token, uint256 _amount, address _from) external;
    function sendETH (uint256 _startId, uint256 _endId, address _from) external payable;
    function setNFTId (uint256 _nftId, address _from) external;
    function withdrawERC1155 (uint256 _startId, uint256 _endId, address _contract, uint256 _tokenId, address _from) external;
    function withdrawERC20 (uint256 _startId, uint256 _endId, address _contract, address _from) external;
    function withdrawERC721 (uint256 _startId, uint256 _endId, address _contract, uint256[] calldata _tokenIds, address _from) external;
    function withdrawETH (uint256 _startId, uint256 _endId, address _from) external;
}