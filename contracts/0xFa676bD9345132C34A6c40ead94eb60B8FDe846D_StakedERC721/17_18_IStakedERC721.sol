// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
interface IStakedERC721 is IERC721 {
    function disableTransfer() external;
    function enableTransfer() external;
    function safeMint(address to, uint256 tokenId, StakedInfo memory stakedInfo) external;
    function burn(uint256 tokenId) external;
    function stakedInfoOf(uint256 _tokenId) external view returns (StakedInfo memory);

    struct StakedInfo {
        uint64 start;
        uint256 duration;
        uint64 end;
    }
}