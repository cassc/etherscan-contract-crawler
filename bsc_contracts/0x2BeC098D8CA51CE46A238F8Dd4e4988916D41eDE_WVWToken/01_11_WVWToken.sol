// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract WVWToken is ERC20, AccessControl {

    address public walletDistributionContract;
    address public owner;

    constructor(
        address _owner,
        address _walletDistributionContract
    ) ERC20("WVW Token", "WVW") {

        owner = _owner;
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
        walletDistributionContract = _walletDistributionContract;
        _mint(walletDistributionContract, 100000000 * 10**decimals());
    }
}