// SPDX-License-Identifier: GNU-GPL v3.0 or later

pragma solidity >=0.8.0;

import "./IRevest.sol";

interface ITokenVault {

    function createFNFT(
        uint fnftId,
        IRevest.FNFTConfig memory fnftConfig,
        uint quantity,
        address from
    ) external;

    function withdrawToken(
        uint fnftId,
        uint quantity,
        address user
    ) external;

    function depositToken(
        uint fnftId,
        uint amount,
        uint quantity
    ) external;

    function cloneFNFTConfig(IRevest.FNFTConfig memory old) external returns (IRevest.FNFTConfig memory);

    function mapFNFTToToken(
        uint fnftId,
        IRevest.FNFTConfig memory fnftConfig
    ) external;

    function handleMultipleDeposits(
        uint fnftId,
        uint newFNFTId,
        uint amount
    ) external;

    function splitFNFT(
        uint fnftId,
        uint[] memory newFNFTIds,
        uint[] memory proportions,
        uint quantity
    ) external;

    function getFNFT(uint fnftId) external view returns (IRevest.FNFTConfig memory);
    function getFNFTCurrentValue(uint fnftId) external view returns (uint);
    function getNontransferable(uint fnftId) external view returns (bool);
    function getSplitsRemaining(uint fnftId) external view returns (uint);
}