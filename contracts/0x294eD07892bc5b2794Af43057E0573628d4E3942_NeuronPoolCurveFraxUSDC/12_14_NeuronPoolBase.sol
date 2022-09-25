// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import { ERC20, IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { NeuronPoolCommon } from "./NeuronPoolCommon.sol";

abstract contract NeuronPoolBase is NeuronPoolCommon, ERC20, ReentrancyGuard {
    constructor(
        address _token,
        address _governance,
        address _controller
    )
        ERC20(
            string(abi.encodePacked("neuroned", IERC20Metadata(_token).name())),
            string(abi.encodePacked("neur", IERC20Metadata(_token).symbol()))
        )
    {
        token = IERC20Metadata(_token);
        tokenDecimals = uint256(token.decimals());
        governance = _governance;
        controller = _controller;
    }

    function balanceOf(address account) public view virtual override(ERC20, NeuronPoolCommon) returns (uint256) {
        return ERC20.balanceOf(account);
    }

    function _burn(address account, uint256 amount) internal override(NeuronPoolCommon, ERC20) {
        ERC20._burn(account, amount);
    }

    function _mint(address account, uint256 amount) internal override(NeuronPoolCommon, ERC20) {
        ERC20._mint(account, amount);
    }

    function decimals() public view override(NeuronPoolCommon, ERC20) returns (uint8) {
        return NeuronPoolCommon.decimals();
    }

    function totalSupply() public view override(NeuronPoolCommon, ERC20) returns (uint256) {
        return ERC20.totalSupply();
    }
}