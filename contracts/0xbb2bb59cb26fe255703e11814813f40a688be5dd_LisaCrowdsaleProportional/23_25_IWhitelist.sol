// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IWhitelist {
    function isWhitelister(address addr) external view returns (bool);

    function isWhitelisted(address addr) external view returns (bool);

    function addToWhitelist(address participant) external;

    function removeFromWhitelist(address participant) external;

    function addWhitelister(address whitelister) external;

    function removeWhitelister(address whitelister) external;
}