// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// @author: miinded.com
import "./ICryptoFoxesOrigins.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICryptoFoxesOriginsV2 is ICryptoFoxesOrigins, IERC721  {
    function walletOfOwner(address _owner) external view returns(uint256[] memory);
}