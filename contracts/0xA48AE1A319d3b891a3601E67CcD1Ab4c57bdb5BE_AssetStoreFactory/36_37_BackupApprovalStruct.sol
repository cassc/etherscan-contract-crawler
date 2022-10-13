//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./MemberStruct.sol";
import "./TokenStruct.sol";
import "./BeneficiaryStruct.sol";

/**
 * @dev BackUpApprovals struct
 *
 * @param Member member struct of information for the user
 * @param approvedWallet address wallet approving the assets
 * @param backUpWallet address[] wallet approved to recieve assets
 * @param token Token struct with information about the asset backed up
 * @param dateApproved uint256 timestamp of when the approval came in
 * @param claimed bool status of the approval if it was claimed
 * @param approvalId uint256 id of the specific approval for this asset
 */
struct BackUpApprovals {
    member Member;
    address approvedWallet;
    address[] backUpWallet;
    Token token;
    uint256 dateApproved;
    bool claimed;
    uint256 approvalId;
}