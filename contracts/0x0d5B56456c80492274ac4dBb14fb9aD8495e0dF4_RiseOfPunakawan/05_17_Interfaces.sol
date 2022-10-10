// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

interface IPrajna is IERC20 {
    function updateReward(address _address) external;
    function burn(address _from, uint256 amount) external;
}

interface IRiseOfPunakawan is IERC721 {

}

interface ISemar is IERC721 {

}