// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.0;


interface IMultiVaultToken {
    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) external;

    function burn(address account, uint256 amount) external;
    function mint(address account, uint256 amount) external;
}