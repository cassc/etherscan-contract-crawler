// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "../base/AdapterBase.sol";
import "../../interfaces/IWETH.sol";
import "../../interfaces/lido/ILido.sol";
import "../../interfaces/lido/IWstETH.sol";

contract LidoAdapter is AdapterBase {
    address public constant stETHAddr =
        0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant wstETHAddr =
        0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant referral = address(0);

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "LidoAdapter")
    {}

    event LidoSubmit(address account, uint256 amount);
    event LidoWrap(address account, uint256 stAmount, uint256 wstAmount);
    event LidoUnwrap(address account, uint256 wstAmount, uint256 stAmount);

    function submit(uint256 amount) external onlyDelegation {
        uint256 stAmount = ILido(stETHAddr).submit{value: amount}(referral);
        emit LidoSubmit(address(this), stAmount);
    }

    function submitWETH(uint256 amount) external onlyDelegation {
        IWETH(wethAddr).withdraw(amount);
        uint256 stAmount = ILido(stETHAddr).submit{value: amount}(referral);
        emit LidoSubmit(address(this), stAmount);
    }

    function wrap(uint256 amount) external onlyDelegation {
        uint256 WstETHAmount = IWstETH(wstETHAddr).wrap(amount);
        emit LidoWrap(address(this), amount, WstETHAmount);
    }

    function unwrap(uint256 amount) external onlyDelegation {
        uint256 stETHAmount = IWstETH(wstETHAddr).unwrap(amount);
        emit LidoUnwrap(address(this), amount, stETHAmount);
    }
}