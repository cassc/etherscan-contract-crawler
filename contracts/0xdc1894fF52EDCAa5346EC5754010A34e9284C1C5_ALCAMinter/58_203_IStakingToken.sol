// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IStakingToken {
    function migrate(uint256 amount) external returns (uint256);

    function migrateTo(address to, uint256 amount) external returns (uint256);

    function finishEarlyStage() external;

    function externalMint(address to, uint256 amount) external;

    function externalBurn(address from, uint256 amount) external;

    function getLegacyTokenAddress() external view returns (address);

    function convert(uint256 amount) external view returns (uint256);
}

interface IStakingTokenMinter {
    function mint(address to, uint256 amount) external;
}

interface IStakingTokenBurner {
    function burn(address to, uint256 amount) external;
}