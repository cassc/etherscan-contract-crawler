// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOpenSkyFlashClaimReceiver {
    function executeOperation(
        address[] calldata nftAddresses,
        uint256[] calldata tokenIds,
        address initiator,
        address operator,
        bytes calldata params
    ) external returns (bool);
}