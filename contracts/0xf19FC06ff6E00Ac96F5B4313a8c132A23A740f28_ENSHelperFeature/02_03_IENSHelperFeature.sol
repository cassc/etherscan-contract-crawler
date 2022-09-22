// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IENSHelperFeature {

    struct ENSQueryResult {
        address resolver;
        address domainAddr;
        address owner;
        bool available;
    }

    struct ENSReverseResult {
        address resolver;
        bytes domain;
        address verifyResolver;
        address verifyAddr;
    }

    function queryENSInfosByNode(address ens, bytes32[] calldata nodes) external view returns (ENSQueryResult[] memory);

    function queryENSInfosByToken(address token, address ens, uint256[] calldata tokenIds) external view returns (ENSQueryResult[] memory);

    function queryENSReverseInfos(address ens, address[] calldata addresses) external view returns (ENSReverseResult[] memory);
}