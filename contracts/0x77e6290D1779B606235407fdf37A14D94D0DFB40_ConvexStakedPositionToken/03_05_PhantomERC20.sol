// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.10;

import { IPhantomERC20 } from "../interfaces/IPhantomERC20.sol";

/// @dev PhantomERC20 is a pseudo-ERC20 that only implements totalSupply and balanceOf
/// @notice Used to track positions that do not issue an explicit share token
///         This is an abstract contract and balanceOf is implemented by concrete instances
abstract contract PhantomERC20 is IPhantomERC20 {
    address public immutable underlying;

    string public override symbol;
    string public override name;
    uint8 public immutable override decimals;

    constructor(
        address _underlying,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        underlying = _underlying;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return IPhantomERC20(underlying).totalSupply();
    }

    function transfer(address, uint256) external pure override returns (bool) {
        return false;
    }

    function allowance(address, address)
        external
        pure
        override
        returns (uint256)
    {
        return 0;
    }

    function approve(address, uint256) external pure override returns (bool) {
        return false;
    }

    function transferFrom(
        address,
        address,
        uint256
    ) external pure override returns (bool) {
        return false;
    }
}