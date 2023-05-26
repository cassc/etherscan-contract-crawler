// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "../interfaces/IBarn.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

contract MulticallMock {
    using SafeMath for uint256;

    IBarn barn;
    IERC20 bond;

    constructor(address _barn, address _bond) {
        barn = IBarn(_barn);
        bond = IERC20(_bond);
    }

    function multiDelegate(uint256 amount, address user1, address user2) public {
        bond.approve(address(barn), amount);

        barn.deposit(amount);
        barn.delegate(user1);
        barn.delegate(user2);
        barn.delegate(user1);
    }

    function multiDeposit(uint256 amount) public {
        bond.approve(address(barn), amount.mul(3));

        barn.deposit(amount);
        barn.deposit(amount);
        barn.deposit(amount);
    }
}