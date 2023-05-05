// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.7.5;

import { TheopetraStaking } from "../Theopetra/Staking.sol";

contract rebaseHelper {

    function rebaseBatch(TheopetraStaking[] calldata stakingContracts, uint256 _periods) public {
        for (uint256 i; i < stakingContracts.length; ++i) {
            for (uint256 j; j < _periods; ++j) {
            stakingContracts[i].rebase();
            }
        }
    }

}