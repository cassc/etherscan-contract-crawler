//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IYardboisResources is IERC1155 {

    function mint(address _recipient, uint256 _tokenId, uint256 _amount) external;
    function burn(address _from, uint256 _tokenId, uint256 _amount) external;
    
}