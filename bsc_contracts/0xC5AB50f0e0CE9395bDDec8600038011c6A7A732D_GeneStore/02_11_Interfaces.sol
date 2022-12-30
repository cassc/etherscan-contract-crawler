// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

interface IGPCToken is IERC20 {
    function dispense(address recipient, uint256 amount) external;
}

interface ICard is IERC721Metadata {
    function awardItem(address player, string memory tokenURI) external returns (uint256);
}

interface ICardFragment is IERC1155 {
    function dispense(address recipient, uint amount) external;
}

interface IGeneCards is IERC1155 {
  function dispenseSpecific(address recipient, uint256 _type, uint256 amount) external;
  function dispenseCardFrag(address recipient, uint256 amount) external;
}