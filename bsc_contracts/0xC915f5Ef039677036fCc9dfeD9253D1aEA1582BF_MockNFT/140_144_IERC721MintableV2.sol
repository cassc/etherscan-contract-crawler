// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721MintableV2 is IERC721 {

    function mint(address to) external;

    function batchMint(address _recipient, uint256 _number) external;

    function totalSupply() external returns (uint);

}