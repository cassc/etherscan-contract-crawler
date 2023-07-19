// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';

interface IPaw is IERC20 {
    function updateReward(address _address) external;
}

interface IKumaVerse is IERC721 {

}

interface IKumaTracker is IERC1155 {}