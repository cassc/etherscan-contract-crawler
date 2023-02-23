/**
 *Submitted for verification at BscScan.com on 2023-02-22
*/

// SPDX-License-Identifier: MIT

interface IAirdropClaimer{
    function mintShares(
        address _user
    )
        external;
}

pragma solidity ^0.8.17;

contract DistributeAirdropClaimer {
    IAirdropClaimer public immutable AirdropClaimer;

    constructor(
        address[] memory _userList,
        address _AirdropClaimer
    )
    {
        AirdropClaimer = IAirdropClaimer(
            _AirdropClaimer
        );

        for (uint256 i = 0; i < _userList.length; i++) {
          AirdropClaimer.mintShares(
              _userList[i]
          );
       }

    }
}