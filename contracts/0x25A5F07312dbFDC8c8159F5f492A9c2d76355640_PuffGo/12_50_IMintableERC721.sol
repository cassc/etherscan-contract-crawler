// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

interface IMintableERC721 is IERC721Enumerable {

    function mint(address _to, uint _num) external;

}