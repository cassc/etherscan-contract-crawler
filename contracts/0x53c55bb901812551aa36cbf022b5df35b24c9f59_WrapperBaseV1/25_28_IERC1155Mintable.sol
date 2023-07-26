// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "IERC1155MetadataURI.sol";

interface IERC1155Mintable is  IERC1155MetadataURI {
     function mint(address _to, uint256 _tokenId, uint256 _amount) external;
     function burn(address _to, uint256 _tokenId, uint256 _amount) external;
     function totalSupply(uint256 _id) external view returns (uint256); 
     function exists(uint256 _tokenId) external view returns(bool);
}