// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../access/GenArtAccess.sol";
import "../legacy/IGenArtMembership.sol";
import {GenArtLoyaltyVault} from "../loyalty/GenArtLoyaltyVault.sol";
import "../interface/IGenArtERC721.sol";
import "../interface/IGenArtInterfaceV4.sol";

/**
 * Interface to the GEN.ART Membership and Vault
 */

contract GenArtInterfaceV4 is GenArtAccess, IGenArtInterfaceV4 {
    IGenArtMembership public genArtMembership;
    GenArtLoyaltyVault public genartVault;

    constructor(address genArtMembershipAddress_) {
        genArtMembership = IGenArtMembership(genArtMembershipAddress_);
    }

    function isGoldToken(uint256 _membershipId)
        external
        view
        override
        returns (bool)
    {
        return genArtMembership.isGoldToken(_membershipId);
    }

    function getMembershipsOf(address account)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory vaultedMemberships = genartVault.getMembershipsOf(
            account
        );
        uint256[] memory memberships = genArtMembership.getTokensByOwner(
            account
        );
        uint256 vaultedMembershipsLength = vaultedMemberships.length;
        uint256 membershipsLength = memberships.length;
        uint256[] memory returnArr = new uint256[](
            vaultedMembershipsLength + membershipsLength
        );
        for (uint256 i = 0; i < vaultedMembershipsLength; i++) {
            returnArr[i] = vaultedMemberships[i];
        }
        for (uint256 i = 0; i < membershipsLength; i++) {
            returnArr[vaultedMembershipsLength + i] = memberships[i];
        }

        return returnArr;
    }

    function ownerOfMembership(uint256 _membershipId)
        external
        view
        override
        returns (address, bool)
    {
        address account = genArtMembership.ownerOf(_membershipId);

        if (account == address(genartVault)) {
            return (genartVault.membershipOwners(_membershipId), true);
        }

        return (account, false);
    }

    function isVaulted(uint256 _membershipId)
        external
        view
        override
        returns (bool)
    {
        return genArtMembership.ownerOf(_membershipId) == address(genartVault);
    }

    function setLoyaltyVault(address genartVault_) external onlyAdmin {
        genartVault = GenArtLoyaltyVault(payable(genartVault_));
    }
}