// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
// pragma abicoder v2;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

uint256 constant BASE = 1000000000000000000;

contract DIFX is ERC20("DigitalFinancialExch", "DIFX") {
    constructor(
        address _vestingContract,
        address _publicSale,
        address _launchpad,
        address _staking,
        address _airdrops,
        address _advisory,
        address _bounty
    ) {
        // mint for private sale with 1 years vesting
        _mint(_vestingContract, 37125000 * BASE);

        // mint for private sale with 2 years vesting
        _mint(_vestingContract, 37125000 * BASE);

        // mint for Strategic Development
        _mint(_vestingContract, 110000000 * BASE);

        // mint for Founders
        _mint(_vestingContract, 66000000 * BASE);

        // mint for Core Team
        _mint(_vestingContract, 27500000 * BASE);

        // mint for Public Sale
        _mint(_publicSale, 99000000 * BASE);

        // mint for Launchpad
        _mint(_launchpad, 74250000 * BASE);

        // mint for Staking
        _mint(_staking, 55000000 * BASE);

        // mint for Airdrops, Referrals & New Account Registration
        _mint(_airdrops, 27500000 * BASE);

        // mint for advisory panal
        _mint(_advisory, 11000000 * BASE);

        // mint for bounty
        _mint(_bounty, 5500000 * BASE);
    }
}