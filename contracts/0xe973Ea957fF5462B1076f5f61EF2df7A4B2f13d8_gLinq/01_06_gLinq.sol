// SPDX-License-Identifier: MIT

// A New Governance Paradigm Brought To You By Linq

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract gLinq is Ownable, ERC20 {
    address public LinqStakingContract;

    constructor(address staking_contract) ERC20("gLinq", "gLINQ") {
        _mint(msg.sender, 100000000 * 10**18);

        LinqStakingContract = staking_contract;
    }

    function setStakingContract(address new_contract) public onlyOwner {
        LinqStakingContract = new_contract;
    } 

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from != LinqStakingContract && to != LinqStakingContract) {
            require(
                false,
                "gLinq : No transfers allowed unless to or from staking contract"
            );
        } else {
            super._transfer(from, to, amount);
        }
    }
}