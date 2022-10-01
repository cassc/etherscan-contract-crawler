// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

pragma experimental ABIEncoderV2;

import "./IPosiNFT.sol";

interface IPosiNFTFactory {
    function getGego(uint256 tokenId)
        external
        view
        returns (
            uint256 grade,
            uint256 quality,
            uint256 amount,
            uint256 resBaseId,
            uint256 tLevel,
            uint256 ruleId,
            uint256 nftType,
            address author,
            address erc20,
            uint256 createdTime,
            uint256 blockNum,
            uint256 lockedDays
        );

    function getGegoStruct(uint256 tokenId)
        external
        view
        returns (IPosiNFT.Gego memory gego);

    function burn(uint256 tokenId) external returns (bool);

    function isRulerProxyContract(address proxy) external view returns (bool);
}