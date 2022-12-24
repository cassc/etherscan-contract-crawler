// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './IERC721CoreV2.sol';

interface IBurnableERC721V2 is IERC721CoreV2 {

    function burn(address _to, uint _id) external;

}