pragma solidity ^0.8.1;
interface IERC721Gateway {
    function token() external view returns (address);
    function Swapout_no_fallback(uint256 tokenId, address receiver, uint256 toChainID) external payable returns (uint256 swapoutSeq);
}