// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./IUniqRedeem.sol";

interface IUniqRedeemV2 is IUniqRedeem {
    function redeemTokensAsAdmin(
        address[] memory _tokenContracts,
        uint256[] memory _tokenIds,
        uint256[] memory _purposes,
        string[] memory _redeemerName
    ) external;

    function redeemTokenForPurposesAsAdmin(
        address _tokenContract,
        uint256 _tokenId,
        uint256[] memory _purposes,
        string memory _redeemerName
    ) external;
}