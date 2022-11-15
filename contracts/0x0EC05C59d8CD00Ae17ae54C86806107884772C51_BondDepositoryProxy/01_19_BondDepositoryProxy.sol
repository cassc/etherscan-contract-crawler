// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

import "./BondDepositoryStorage.sol";
import "./proxy/VaultProxy.sol";


contract BondDepositoryProxy is
    BondDepositoryStorage,
    VaultProxy
{

    function initialize(
        address _tos,
        address _staking,
        address _treasury,
        address _calculator,
        address _uniswapV3Factory
    )
        external onlyProxyOwner
        nonZeroAddress(_tos)
        nonZeroAddress(_staking)
        nonZeroAddress(_treasury)
        nonZeroAddress(_calculator)
        nonZeroAddress(_uniswapV3Factory)
    {
        require(address(tos) == address(0), "already initialized.");
        tos = IERC20(_tos);
        staking = IStaking(_staking);
        treasury = _treasury;
        calculator = _calculator;
        uniswapV3Factory = _uniswapV3Factory;
    }

    function isTreasury() public pure returns (bool) {
        return false;
    }

}