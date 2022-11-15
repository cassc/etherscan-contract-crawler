// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;
import "erc721a/contracts/IERC721A.sol";

interface INft is IERC721A {
    function mint(address to, uint256 amount) external;

    function burn(uint256 tokenId) external;

    function currentIndex() external returns (uint256);
}