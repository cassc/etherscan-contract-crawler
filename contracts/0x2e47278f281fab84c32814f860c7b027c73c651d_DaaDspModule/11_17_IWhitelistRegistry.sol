// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

interface IWhitelistRegistry {

    function isActionWhitelisted(bytes4 actionId) external view returns (bool);

    function isTargetWhitelisted(address target) external view returns (bool);

    function enableActionId(bytes4 actionId) external;

    function enableTargetDest(address target) external;

    function disableActionId(bytes4 actionId) external;

    function disableTargetDest(address target) external;
    
}