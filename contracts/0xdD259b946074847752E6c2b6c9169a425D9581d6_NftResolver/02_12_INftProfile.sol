// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface INftProfile {
    event ExtendExpiry(string _profileURI, uint256 _extendedExpiry);

    function createProfile(
        address receiver,
        string memory _profileURI,
        uint256 _expiry
    ) external;

    function extendLicense(
        string memory _profileURI,
        uint256 _duration,
        address _licensee
    ) external;

    function purchaseExpiredProfile(
        string memory _profileURI,
        uint256 _duration,
        address _receiver
    ) external;

    function getTokenId(string memory _string) external view returns (uint256);

    function tokenUsed(string memory _string) external view returns (bool);

    function profileOwner(string memory _string) external view returns (address);
}