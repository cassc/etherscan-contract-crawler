// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ILSSVMPairERC721 {
    function swapNFTsForToken(
        uint256[] calldata nftIds,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller,
        bytes calldata propertyCheckerParams
    ) external returns (uint256 outputAmount);
}