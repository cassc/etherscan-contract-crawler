// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "IERC721Metadata.sol";

interface IERC721Mintable is  IERC721Metadata {
     function mint(address _to, uint256 _tokenId) external;
     function transferOwnership(address _contract) external;
}