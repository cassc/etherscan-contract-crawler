// SPDX-License-Identifier: MIT
// Creator: @casareafer at 1TM.io

pragma solidity ^0.8.17;

import "./openzeppelin/Ownable.sol";
import "./PioneerPassLibrary.sol";

contract Stacking is Ownable {

    /**
    *   Stores the time when the staking for a token type starts - block.timestamp
    */

    mapping(uint256 => uint256) private StackingTimer;

    /**
    *   Stores whenever the Staking timer already started - It starts once after the first mint of a pass
    */

    mapping(uint256 => bool) private BoOoOmBaby;

    /**
    *   Stores a Timestamp per owned token type in an address
    */

    mapping(address => mapping(uint256 => uint256[])) private lastBoughtTimestamp;

    /**
    *   Staking Point x (Days holding / Total days from the presale)
    *
    *   NOTE: SELLING YOUR TOKENS ERASE YOUR HOLDING TIME >:)
    *
    *   MORE NOTES: SELLING YOUR TOKENS WILL ERASE YOUR HOLDING TIME STARTING FROM THE
    *   LATEST BOUGHT TOKEN ;)
    */

    function stakeTransfer(uint256[] memory _passId, uint256[] memory _amount, address _to, address _from) internal {
        if (_from != address(0)) {
            for (uint foo = 0; foo < _passId.length; foo++) {
                for (uint bar = 0; bar < _amount[foo]; bar++) {
                    lastBoughtTimestamp[_to][_passId[foo]].push(block.timestamp);
                    lastBoughtTimestamp[_from][_passId[foo]].pop();
                }
            }
        } else if (_to == address(0)) {
                for (uint bar = 0; bar < _amount[0]; bar++) {
                    lastBoughtTimestamp[_from][_passId[0]].pop();
                }
        } else {
            if (BoOoOmBaby[_passId[0]] != true) {
                BoOoOmBaby[_passId[0]] = true;
                StackingTimer[_passId[0]] = block.timestamp;
            }
            for (uint i = 0; i < _amount[0]; i++) {
                lastBoughtTimestamp[_to][_passId[0]].push(block.timestamp);
            }
        }
    }

    /**
    *   Get Stacking info
    */

    function getStakingTimer(uint256 _passId) external view returns (uint256){
        return StackingTimer[_passId];
    }

    function getStakes(uint256 _passId, address _user) external view returns (uint256[] memory){
        return lastBoughtTimestamp[_user][_passId];
    }

}