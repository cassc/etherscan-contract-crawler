// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

interface IHoneyJars is IERC721, IERC721Enumerable {

    function tokensInWallet(address _owner) external view returns(uint256[] memory);

}