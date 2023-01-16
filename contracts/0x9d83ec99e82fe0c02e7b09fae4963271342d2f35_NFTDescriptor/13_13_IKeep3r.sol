// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

// import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';

interface IPairManager {
    function mint(uint256, uint256, uint256, uint256, address) external returns (uint128);
}

interface IKeep3rHelper {
    function quote(uint256) external view returns (uint256);
}

interface IKeep3r {
    function keep3rV1() external view returns (address);

    function keep3rHelper() external view returns (address);

    function addJob(address) external;

    function isKeeper(address) external returns (bool);

    function worked(address) external;

    function bond(address, uint256) external;

    function activate(address) external;

    function liquidityAmount(address, address) external view returns (uint256);

    function jobPeriodCredits(address) external view returns (uint256);

    function addLiquidityToJob(address, address, uint256) external;

    function unbondLiquidityFromJob(address, address, uint256) external;

    function withdrawLiquidityFromJob(address, address, address) external;

    function canWithdrawAfter(address, address) external view returns (uint256);
}