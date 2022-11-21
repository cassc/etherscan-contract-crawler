// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './IERC721Core.sol';

interface IBurnableERC721 is IERC721Core {

    function burn(address _to, uint _id) external;

}