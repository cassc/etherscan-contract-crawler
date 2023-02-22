// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

import {TokenType} from "../constant/TokenEnums.sol";
import {NFT} from "../constant/BaseStructs.sol";

interface IBank721 {
    struct Duration {
        uint64 start;
        address owner;
    }

    event StakeNFT721(address oNFT, uint256 oNFTId);
    event RedeemNFT721(address oNFT, uint256 oNFTId);

    function tryStakeNFT721(
        TokenType tokenType,
        address oNFT,
        uint256 oNFTId,
        address from
    ) external;

    function redeemNFT721(
        TokenType tokenType,
        address oNFT,
        uint256 oNFTId
    ) external;

    function userInfoOf(
        TokenType tokenType,
        address oNFT,
        uint256 oNFTId
    ) external view returns (address user, uint256 userExpires);

    function setUser(
        NFT calldata nft,
        address owner,
        address user,
        uint64 expiry,
        uint64 durationId
    ) external;

    function claimUser(NFT calldata nft, uint64 durationId) external;
}