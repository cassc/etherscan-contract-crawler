/**
                                                         __
     _____      __      ___    ___     ___     __       /\_\    ___
    /\ '__`\  /'__`\   /'___\ / __`\  /'___\ /'__`\     \/\ \  / __`\
    \ \ \_\ \/\ \_\.\_/\ \__//\ \_\ \/\ \__//\ \_\.\_  __\ \ \/\ \_\ \
     \ \ ,__/\ \__/.\_\ \____\ \____/\ \____\ \__/.\_\/\_\\ \_\ \____/
      \ \ \/  \/__/\/_/\/____/\/___/  \/____/\/__/\/_/\/_/ \/_/\/___/
       \ \_\
        \/_/

    The sweetest DeFi portfolio manager.

**/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./SweetVault_v6.sol";

// TODO write test as first initialization didn't work
contract SweetVault_v6_Baby is SweetVault_v6 {
    function _getExpectedOutput(
        address[] memory _path
    ) internal virtual override view returns (uint) {
        FarmInfo memory _farmInfo = farmInfo;

        uint pending = IFarm(_farmInfo.farm).pendingReward(_farmInfo.pid, address(this));

        uint rewards = _currentBalance(_farmInfo.rewardToken) + pending;

        if (rewards == 0) {
            return 0;
        }

        uint[] memory amounts = router.getAmountsOut(rewards, _path);

        return amounts[amounts.length - 1];
    }
}