// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "IERC721Metadata.sol";

interface IERC721Mintable is  IERC721Metadata {
     function mint(address _to, uint256 _tokenId) external;
     function burn(uint256 _tokenId) external;
     function exists(uint256 _tokenId) external view returns(bool);
}