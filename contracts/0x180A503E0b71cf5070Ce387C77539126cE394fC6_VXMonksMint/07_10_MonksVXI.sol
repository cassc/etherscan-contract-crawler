//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

abstract contract MonksVXI is Ownable, IERC721 {
    function mint(address _owner, uint256 _tokenId) external virtual;

    function mintBatch(address _owner, uint16[] calldata _tokenIds) external virtual;

    function exists(uint256 _tokenId) external view virtual returns (bool);

    function tokensOfOwner(address _owner) external view virtual returns (uint256[] memory);

    function MAX_SUPPLY() external view virtual returns (uint256);
}