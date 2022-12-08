// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRAX {
    function referrers(address referrer) external view returns (address);
    function setReferrer(address referrer) external;
    function setReferrer(address referee, address referrer) external;
}