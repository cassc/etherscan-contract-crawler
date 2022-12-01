// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "erc721a/contracts/IERC721A.sol";

interface IBridge is IERC721A {
    function getNumberOfNFTsForUser(address _user) external view returns (uint256);

    function getNumberOfNFTHolders() external view returns (uint256);

    function getNFTHoldersArray() external view returns (address[] memory);
}