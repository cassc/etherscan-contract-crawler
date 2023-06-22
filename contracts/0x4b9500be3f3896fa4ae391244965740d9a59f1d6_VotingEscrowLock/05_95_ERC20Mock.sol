//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.0;

import {
    ERC20Burnable,
    ERC20 as _ERC20
} from "@openzeppelin/contracts/token/ERC20/ERC20Burnable.sol";

/**
 * @title Commit Token
 * @notice Commit Token is used for redeeming stable coins, buying crypto products
 *      from the village market and mining vision tokens. It is minted by the admin and
 *      given to the contributors. The amount of mintable token is limited to the balance
 *      of redeemable stable coins. Therefore, it's 1:1 pegged to the given stable coin
 *      or expected to have higher value than the redeemable coin values.
 */
contract ERC20 is ERC20Burnable {
    address public minter;

    constructor() _ERC20("ERC20Mock", "MOCK") {
        minter = msg.sender;
    }

    modifier onlyMinter {
        require(msg.sender == minter, "Not a minter");
        _;
    }

    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    function setMinter(address _minter) public onlyMinter {
        minter = _minter;
    }
}