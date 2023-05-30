pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IProofOfAuditor is IERC721 {
    function mint(address auditor_) external returns (uint256 id_);
    function idHeld(address auditor_) external view returns (uint256 id_);
    function level(uint256 tokenId_) external view returns (uint256 level_);
}