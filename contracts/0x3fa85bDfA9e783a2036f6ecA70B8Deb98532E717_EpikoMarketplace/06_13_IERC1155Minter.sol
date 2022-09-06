//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IERC1155Minter is IERC1155,IERC2981{
    function getArtist(uint256 tokenId) external view returns(address);
    function burn(address from, uint256 id, uint256 amounts) external; 
    function mint(address to, uint256 amount, uint256 _royaltyFraction, string memory uri,bytes memory data)external returns(uint256);
    function _isExist(uint256 tokenId) external returns(bool);
}