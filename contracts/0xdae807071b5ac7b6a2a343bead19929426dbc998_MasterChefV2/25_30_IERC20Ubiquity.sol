// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ERC20 Ubiquiti preset interface
/// @author Ubiquity Algorithmic Dollar
interface IERC20Ubiquity is IERC20 {
    // ----------- Events -----------
    event Minting(
        address indexed _to,
        address indexed _minter,
        uint256 _amount
    );

    event Burning(address indexed _burned, uint256 _amount);

    // ----------- State changing api -----------
    function burn(uint256 amount) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // ----------- Burner only state changing api -----------
    function burnFrom(address account, uint256 amount) external;

    // ----------- Minter only state changing api -----------
    function mint(address account, uint256 amount) external;
}