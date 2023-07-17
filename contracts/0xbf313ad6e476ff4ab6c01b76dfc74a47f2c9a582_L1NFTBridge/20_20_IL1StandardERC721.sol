// SPDX-License-Identifier: MIT
pragma solidity >0.7.5;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IL1StandardERC721 is IERC165, IERC721 {
    function l2Contract() external returns (address);

    function mint(address _to, uint256 _tokenId, bytes memory _data) external;

    function burn(uint256 _tokenId) external;

    event Mint(address indexed _account, uint256 _tokenId);
    event Burn(uint256 _tokenId);
}