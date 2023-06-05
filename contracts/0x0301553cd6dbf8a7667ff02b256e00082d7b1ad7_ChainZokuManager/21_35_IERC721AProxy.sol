// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "erc721a/contracts/extensions/IERC721AQueryable.sol";

// @author: miinded.com

interface IERC721AProxy is IERC721AQueryable{
    function mint(address _wallet, uint256 _count) external;
    function burn(uint256 _tokenId) external;
    function totalMinted() external view returns(uint256);
    function totalBurned() external view returns(uint256);
}