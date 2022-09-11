// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IMRC721 is IERC721{

    function mint(address to, uint256 id) external;

    function burn(uint256 tokenId) external;

    function tokensOfOwner(address _owner) external view returns(uint256[] memory);

    function totalSupply() external view returns (uint256);
}