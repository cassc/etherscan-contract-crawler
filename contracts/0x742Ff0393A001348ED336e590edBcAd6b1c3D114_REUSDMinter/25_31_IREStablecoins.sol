// SPDX-License-Identifier: reup.cash
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Base/IUpgradeableBase.sol";

interface IREStablecoins is IUpgradeableBase
{
    struct StablecoinConfigWithName
    {
        IERC20 token;
        uint8 decimals;
        string name;
        string symbol;
    }

    error TokenNotSupported();
    error TokenMisconfigured();
    error StablecoinAlreadyExists();
    error StablecoinDoesNotExist();
    error StablecoinBakedIn();

    function isREStablecoins() external view returns (bool);
    function supported() external view returns (StablecoinConfigWithName[] memory);
    function getMultiplyFactor(IERC20 token) external view returns (uint256);

    function add(IERC20 stablecoin) external;
    function remove(IERC20 stablecoin) external;
}