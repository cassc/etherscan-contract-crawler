// SPDX-License-Identifier: MIT
pragma solidity ^0.4.26;

//SidekickDistributor is a slightly more gas optimized version of Disperse.sol from Disperse.app
//
//@author: @sec0ndstate
//
// Made for getsidekick.xyz


//  ..._____._....._......_...._......_...._____.._....._........_._..........._.............
//  ../.____(_)...|.|....|.|..(_)....|.|..|..__.\(_)...|.|......(_).|.........|.|............
//  .|.(___.._..__|.|.___|.|.___..___|.|._|.|..|.|_.___|.|_._.__._|.|__.._..._|.|_.___.._.__.
//  ..\___.\|.|/._`.|/._.\.|/./.|/.__|.|/./.|..|.|./.__|.__|.'__|.|.'_.\|.|.|.|.__/._.\|.'__|
//  ..____).|.|.(_|.|..__/...<|.|.(__|...<|.|__|.|.\__.\.|_|.|..|.|.|_).|.|_|.|.||.(_).|.|...
//  .|_____/|_|\__,_|\___|_|\_\_|\___|_|\_\_____/|_|___/\__|_|..|_|_.__/.\__,_|\__\___/|_|...
//  .........................................................................................
//  .........................................................................................
//  .........................................................................................

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

contract SidekickDistributor {
    function distributeEther(address[] recipients, uint256[] values) external payable {
        for (uint256 i = 0; i < recipients.length; ++i)
            recipients[i].transfer(values[i]);
        assembly{
            let bal := balance(address())
            if gt(bal, 0) {
                if iszero(call(gas(), caller(), bal, 0, 0, 0, 0)) {
                    revert(0, 0)
                }
            }
        }
    }


    function distributeToken(IERC20 token, address[] recipients, uint256[] values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; ++i)
            total += values[i];
            if (token.transferFrom(msg.sender, address(this), total)) {
                for (i = 0; i < recipients.length; ++i)
                    token.transfer(recipients[i], values[i]);
            }
    }
}