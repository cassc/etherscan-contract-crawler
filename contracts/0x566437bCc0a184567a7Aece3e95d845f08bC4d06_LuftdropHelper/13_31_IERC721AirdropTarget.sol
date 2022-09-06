// SPDX-License-Identifier: MIT
// ERC721AirdropTarget Contracts v4.0.0
// Creator: Chance Santana-Wees

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

interface IERC721AirdropTarget is IERC1155Receiver, IERC721Receiver {
    event ERC20AirdropHarvested(address token, address claimant, uint256[] claimIDs, uint256 totalClaimed);
    event ERC721AirdropHarvested(address collection, address claimant, uint256 nftID);
    event ERC1155AirdropHarvested(address collection, address claimant, uint256 nftID, uint256 quantity);

    function harvestERC721Airdrop(address collection, uint256 tokenID) external;

    function harvestERC1155Airdrop(address collection, uint256 tokenID, uint quantity) external;

    function noticeAirdrop(address tokenAddress) external;
    
    function pullAirdrop(address tokenAddress, uint256 quantity) external;

    function claimableAirdrops(address airdropToken, uint256 tokenID) external view returns (uint256);

    function harvestAirdrops(address[] memory airdropTokens, uint256[] memory tokenIDs) external;
}