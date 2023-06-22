// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./TreasuryStorage.sol";
import "./proxy/VaultProxy.sol";

contract TreasuryProxy is
    TreasuryStorage,
    VaultProxy
{

    function initialize(
        address _tos,
        address _calculator,
        address _wethAddress,
        address _uniswapV3Factory,
        address _stakingV2,
        address _poolAddressTOSETH
    )
        nonZeroAddress(_tos)
        nonZeroAddress(_calculator)
        nonZeroAddress(_wethAddress)
        nonZeroAddress(_uniswapV3Factory)
        nonZeroAddress(_stakingV2)
        nonZeroAddress(_poolAddressTOSETH)
        external onlyProxyOwner
    {
        require(address(tos) == address(0), "already initialized");

        tos = IERC20(_tos);
        calculator = _calculator;
        wethAddress = _wethAddress;
        uniswapV3Factory = _uniswapV3Factory;
        mintRateDenominator = 1;
        stakingV2 = _stakingV2;
        poolAddressTOSETH = _poolAddressTOSETH;
    }

    function isTreasury() public pure returns (bool) {
        return true;
    }

}