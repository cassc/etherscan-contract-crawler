// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ISwapRewards {

    function setSWINGBYPrice(uint256 _pricePerBTC) external;

    function pullRewards(address _dest, address _receiver, uint256 _swapped) external returns (bool);

    function pullRewardsMulti(address _dest, address[] memory _receiver, uint256[] memory _swapped) external returns (bool);
}