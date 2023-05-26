pragma solidity >=0.7.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";

interface IMintedBeforeReveal is IERC721Enumerable {
    function isMintedBeforeReveal(uint256 index) external view returns (bool);
}