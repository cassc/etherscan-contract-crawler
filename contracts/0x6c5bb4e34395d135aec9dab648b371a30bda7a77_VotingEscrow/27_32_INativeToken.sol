//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

interface INativeToken {
    function mintVestingTokens(address receiver, uint256 amount) external;

    function mintGenesisTokens(uint256 amount) external;

    function burnGenesisTokens(uint256 amount) external;

    function mintGaugeRewards(address receiver, uint256 amount) external;

    function mintRebates(address receiver, uint256 amount) external;
}