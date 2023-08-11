// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <=0.9.0;

interface IHarvestController {
    function greyList(address _addr) external view returns (bool);

    // Only smart contracts will be affected by the whitelist.
    function addToWhitelist(address _target) external;

    function addMultipleToWhitelist(address[] memory _targets) external;

    function removeFromWhitelist(address _target) external;

    function removeMultipleFromWhitelist(address[] memory _targets) external;

    function addCodeToWhitelist(address _target) external;

    function removeCodeFromWhitelist(address _target) external;
}