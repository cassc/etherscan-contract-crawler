// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

interface IPToken {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;

    function deposit(address to, uint256 amount) external;
    function withdraw(address to, uint256 amount) external;

    function tokenUnderlying() external view returns(address);

    function checkAuthorizedCaller(address caller) external view returns (bool);
    function checkIfDepositWithdrawEnabled() external view returns (bool);
}