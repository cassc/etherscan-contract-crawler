//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

interface IERC721Minter is IERC721,IERC2981{
    function mint(address to, uint256 royaltyFraction, string memory _uri)external returns(uint256);
    function burn(uint256 tokenId) external;
    function _isExist(uint256 tokenId)external view returns(bool);
    function isApprovedOrOwner(address spender, uint256 tokenId)external view returns(bool);
    function getArtist(uint256 tokenId)external view returns(address);
}