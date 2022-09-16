// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISmartInvoice {
    function init(
        address _client,
        address _provider,
        uint8 _resolverType,
        address _resolver,
        address _token,
        uint256[] calldata _amounts,
        uint256 _terminationTime, // exact termination date in seconds since epoch
        uint256 _resolutionRate,
        bytes32 _details,
        address _wrappedNativeToken,
        bool _requireVerification
    ) external;

    function release() external;

    function release(uint256 _milestone) external;

    function releaseTokens(address _token) external;

    function withdraw() external;

    function withdrawTokens(address _token) external;

    function lock(bytes32 _details) external payable;

    function resolve(
        uint256 _clientAward,
        uint256 _providerAward,
        bytes32 _details
    ) external;
}