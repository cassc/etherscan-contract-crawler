// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IWildlandCards is IERC721 {

    function mint(address _to, uint256 _cardId) external;

    function isCardAvailable(uint256 cardId) external view returns (bool);

    function exists(uint256 _tokenId) external view returns (bool);

    function existsCode(bytes4 _code) external view returns (bool) ;

    function getTokenIdByCode(bytes4 _code) external view returns (uint256);

    function getCodeByAddress(address _address) external view returns (bytes4);

    function cardIndex(uint256 cardId) external view returns (uint256);
}