// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IDefinitelyMemberships {
    function issueMembership(address to) external;

    function revokeMembership(uint256 id, bool addToDenyList) external;

    function addAddressToDenyList(address account) external;

    function removeAddressFromDenyList(address account) external;

    function transferMembership(uint256 id, address to) external;

    function overrideMetadataForToken(uint256 id, address metadata) external;

    function resetMetadataForToken(uint256 id) external;

    function isDefMember(address account) external view returns (bool);

    function isOnDenyList(address account) external view returns (bool);

    function memberSinceBlock(uint256 id) external view returns (uint256);

    function defaultMetadataAddress() external view returns (address);

    function metadataAddressForToken(uint256 id) external view returns (address);

    function allowedMembershipIssuingContract(address addr) external view returns (bool);

    function allowedMembershipRevokingContract(address addr) external view returns (bool);

    function allowedMembershipTransferContract(address addr) external view returns (bool);
}