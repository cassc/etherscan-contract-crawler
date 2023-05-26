// contracts/ITeaVaultV2.sol
// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;


interface ITeaVaultV2 {

    function deposit(address _token, uint256 _amount) external;
    function withdraw(address _recipient, address _token, uint256 _amount) external;
    function deposit721(address _token, uint256 _tokenId) external;
    function withdraw721(address _recipient, address _token, uint256 _tokenId) external;
    function deposit1155(address _token, uint256 _tokenId, uint256 _amount) external;
    function withdraw1155(address _recipient, address _token, uint256 _tokenId, uint256 _amount) external;
    function depositETH(uint256 _amount) external payable;
    function withdrawETH(address payable _recipient, uint256 _amount) external;
    
}