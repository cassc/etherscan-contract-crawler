// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IHomageProtocolConfigView.sol";

interface IL2TokenClaimBridge is IHomageProtocolConfigView {
    function initialize(address homageProtocolConfig_) external;

    function claimEtherForMultipleNfts(
        address[] calldata canonicalNfts_,
        uint256[] calldata tokenIds_,
        address payable beneficiary_,
        uint256[] calldata claimAmounts_,
        address payable[][] calldata royaltyRecipientsArray_,
        uint256[][] calldata royaltyAmountsArray_
    ) external returns (uint256);

    function markReplicasAsAuthentic(address canonicalNft_, uint256 tokenId_)
        external;
}