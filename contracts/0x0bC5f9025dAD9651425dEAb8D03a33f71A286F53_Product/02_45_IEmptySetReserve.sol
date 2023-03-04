//SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

import "@equilibria/root/number/types/UFixed18.sol";

interface IEmptySetReserve {
    event Redeem(address indexed account, uint256 costAmount, uint256 redeemAmount);
    event Mint(address indexed account, uint256 mintAmount, uint256 costAmount);
    event Repay(address indexed account, uint256 repayAmount);

    function debt(address borrower) external view returns (UFixed18);
    function repay(address borrower, UFixed18 amount) external;
    function mint(UFixed18 amount) external;
    function redeem(UFixed18 amount) external;
}