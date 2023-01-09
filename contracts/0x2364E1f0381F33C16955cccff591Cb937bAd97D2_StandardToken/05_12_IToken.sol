// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IToken is IERC721 {

    function totalSupply() external view returns (uint256);

    function mint() external returns(uint256);

    function burn(uint256 tokenId) external returns(bool);

}