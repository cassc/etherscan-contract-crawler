// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "../interfaces/IWrap.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IHedgepieTradeNFT is IERC721 {
    struct UserAdapterInfo {
        uint256 ybnftId; // YBNFT token id
        uint256[] amount; // Current staking token amount
        uint256[] invested; // Current staked ether amount
        uint256[] userShares; // First reward token share
        uint256[] userShares1; // Second reward token share
    }

    function mint(
        address,
        uint256,
        uint256[] memory,
        uint256[] memory,
        uint256[] memory,
        uint256[] memory
    ) external;

    function updateShares(
        address,
        uint256,
        uint256[] memory,
        uint256[] memory
    ) external;

    function burn(uint256) external;

    function getNFTInfo(uint256 _tokenId)
        external
        view
        returns (UserAdapterInfo memory);

    function getCurrentTokenId() external view returns (uint256);
}