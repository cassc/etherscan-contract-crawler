// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IInterceptorManager {
    function addCollectionInterceptor(address Interceptor) external;

    function removeCollectionInterceptor(address Interceptor) external;

    function isInterceptorWhitelisted(address Interceptor) external view returns (bool);

    function viewWhitelistedInterceptors(uint256 cursor, uint256 size)
        external
        view
        returns (address[] memory, uint256);

    function viewCountWhitelistedInterceptors() external view returns (uint256);
}