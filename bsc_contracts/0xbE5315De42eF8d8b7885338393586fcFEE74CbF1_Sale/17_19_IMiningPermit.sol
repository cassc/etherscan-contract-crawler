// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMiningPermit {
    function checkPermitOfWallet(address wallet) external view returns (bool);
    function issuePermit(address to) external;
    function issuePermits(address[] memory tos) external ;
    function setTokenURIForAll(string memory _newTokenURI) external;
    function revokePermit(address to) external ;
    function forceRevokePermit(address to) external;
    function getPermitHoldersTxIssued() external  view returns (address[] memory);
    function getPermitHoldersTxRevoked() external  view returns (address[] memory);
    function grantModIssue(address mod) external;
    function grantModRevoke(address mod) external;
    function revokeModIssue(address mod) external;
    function revokeModRevoke(address mod) external;
    function transferOwner(address newOwner) external;
}