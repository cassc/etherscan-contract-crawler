// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";

contract RewardToken is ERC20PresetMinterPauser {

    constructor()
    public
    ERC20PresetMinterPauser(
        "ETH2SOCKS Reward Token",
        "ETH2REWARD"
    )
    {}

    // Set the migrator contract. Can only be called by the owner.
    function addMinter(address minter) public {
        grantRole(MINTER_ROLE, minter);
    }
}