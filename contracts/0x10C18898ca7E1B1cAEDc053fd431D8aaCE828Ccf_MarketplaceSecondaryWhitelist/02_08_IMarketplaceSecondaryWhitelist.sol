// SPDX-License-Identifier: ISC
pragma solidity ^0.8.10;

interface IMarketplaceSecondaryWhitelist {
    function is721Whitelisted(address _token) external view returns (bool);
    function is1155Whitelisted(address _token) external view returns (bool);
    function getWhitelistedCollections721() external view returns (address[] memory);
    function getWhitelistedCollections1155() external view returns (address[] memory);
    function addPaymentTokenToWhitelist(address _token) external;
    function removePaymentTokenToWhitelist(uint _index) external;
    function isPaymentTokenWhitelisted(address _token) external view returns (bool);
    function getWhitelistedPaymentTokens() external view returns (address[] memory);
}