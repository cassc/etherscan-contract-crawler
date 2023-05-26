// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "../interfaces/IRewards.sol";

contract BarnMock {
    IRewards public r;
    uint256 public bondStaked;
    mapping(address => uint256) private balances;

    function setRewards(address rewards) public {
        r = IRewards(rewards);
    }

    function callRegisterUserAction(address user) public {
        return r.registerUserAction(user);
    }

    function deposit(address user, uint256 amount) public {
        callRegisterUserAction(user);

        balances[user] = balances[user] + amount;
        bondStaked = bondStaked + amount;
    }

    function withdraw(address user, uint256 amount) public {
        require(balances[user] >= amount, "insufficient balance");

        callRegisterUserAction(user);

        balances[user] = balances[user] - amount;
        bondStaked = bondStaked - amount;
    }

    function balanceOf(address user) public view returns (uint256) {
        return balances[user];
    }
}