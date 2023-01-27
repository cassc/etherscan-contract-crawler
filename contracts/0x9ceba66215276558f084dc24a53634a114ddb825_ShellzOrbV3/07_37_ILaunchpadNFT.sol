//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

interface ILaunchpadNFT {
    // return max supply config for launchpad, if no reserved will be collection's max supply
    function getMaxLaunchpadSupply() external view returns (uint256);

    // return current launchpad supply
    function getLaunchpadSupply() external view returns (uint256);

    // this function need to restrict mint permission to launchpad contract
    function mintTo(address to, uint256 size) external;
}