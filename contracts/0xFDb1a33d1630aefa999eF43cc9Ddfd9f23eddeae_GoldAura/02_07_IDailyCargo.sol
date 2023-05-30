// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "erc721a/contracts/IERC721A.sol";  


interface IDailyCargo is IERC721A {
    function getCargoStreak(uint256 _tokenId) external view returns (uint256);
    function getAddressStreak(address _address) external view returns (uint256);
}