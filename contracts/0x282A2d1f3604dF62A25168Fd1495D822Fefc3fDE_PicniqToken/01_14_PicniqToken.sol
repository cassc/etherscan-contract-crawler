// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./PicniqVesting.sol";
import "./PicniqTokenClaim.sol";
import "./utils/ERC20Permit.sol";

// solhint-disable no-inline-assembly, not-rely-on-time 
contract PicniqToken is ERC20Permit {

    PicniqVesting public vesting;
    PicniqTokenClaim public claim;

    constructor(uint256 supply, address treasury, address team, bytes32 merkleRoot_)
        ERC20("Picniq Finance", "SNACK")
    {
        uint256 teamAmount = supply * 15 / 100;
        uint256 airdropAmount = 463364 * 10 * 10**18;
        uint256 treasuryAmount = supply - teamAmount - airdropAmount;

        vesting = new PicniqVesting(IERC20(this));
        claim = new PicniqTokenClaim(IERC20(this), address(vesting), merkleRoot_, treasury);

        _mint(team, teamAmount);
        _mint(treasury, treasuryAmount);
        _mint(address(claim), airdropAmount);
    }
}