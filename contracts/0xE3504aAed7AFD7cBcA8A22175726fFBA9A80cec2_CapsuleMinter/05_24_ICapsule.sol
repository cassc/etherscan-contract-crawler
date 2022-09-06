// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../openzeppelin/contracts/interfaces/IERC2981.sol";

interface ICapsule is IERC721, IERC2981 {
    function mint(address account, string memory _uri) external;

    function burn(address owner, uint256 tokenId) external;

    // Read functions
    function baseURI() external view returns (string memory);

    function counter() external view returns (uint256);

    function exists(uint256 tokenId) external view returns (bool);

    function isCollectionMinter(address _account) external view returns (bool);

    function maxId() external view returns (uint256);

    function royaltyRate() external view returns (uint256);

    function royaltyReceiver() external view returns (address);

    function tokenURIOwner() external view returns (address);
}