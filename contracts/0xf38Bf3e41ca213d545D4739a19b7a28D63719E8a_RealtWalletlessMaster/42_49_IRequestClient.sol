// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRequestClient {
    event TokenWhitelistSet(
        address[] indexed oldWhitelist,
        address[] indexed newWhitelist
    );

    event DestinationWhitelistSet(
        address[] indexed oldWhitelist,
        address[] indexed newWhitelist
    );

    event FeeAddressWhitelistSet(
        address[] indexed oldWhitelist,
        address[] indexed newWhitelist
    );

    event SetFeeProxy(address indexed oldFeeProxy, address indexed newFeeProxy);

    function setDestinationWhitelist(address[] memory destinationWhitelist_)
        external;

    function destinationWhitelist() external view returns (address[] memory);

    function setTokenWhitelist(address[] memory tokenWhitelist_) external;

    function tokenWhitelist() external view returns (address[] memory);

    function setFeeProxy(address feeProxy_) external;

    function feeProxy() external view returns (address);

    function setFeeAddressWhitelist(address[] memory feeAddressWhitelist_)
        external;

    function feeAddressWhitelist() external view returns (address[] memory);
}