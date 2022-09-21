// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./HectagonInvestment.sol";

contract HectagonInvestmentCouncil is HectagonInvestment {
    constructor(address _authority)
        HectagonInvestment(_authority, "Hectagon Investment Council", "HIC")
    {
        _mint(authority.governor(), 6);
    }
}