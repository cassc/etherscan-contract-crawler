// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IErc20ForFactory is IERC20 {
    /// @dev mint
    /// pnlyFactory
    function mint(uint256 count) external;

    /// @dev mint to address
    /// pnlyFactory
    function mintTo(address account, uint256 count) external;

    /// @dev burn tokens
    /// onlyFactory
    function burn(address account, uint256 count) external;
}