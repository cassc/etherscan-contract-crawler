//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// ______  __  __   ______       _____    __  __   _____    ______
// /\__  _\/\ \_\ \ /\  ___\     /\  __-. /\ \/\ \ /\  __-. /\  ___\
// \/_/\ \/\ \  __ \\ \  __\     \ \ \/\ \\ \ \_\ \\ \ \/\ \\ \  __\
//   \ \_\ \ \_\ \_\\ \_____\    \ \____- \ \_____\\ \____- \ \_____\
//    \/_/  \/_/\/_/ \/_____/     \/____/  \/_____/ \/____/  \/_____/
//

import "./../core/CoreRewarder.sol";

contract TheDudesRewarder is CoreRewarder {
    constructor(
        address targetAddress,
        address rewardAddress,
        uint256 rewardRate,
        uint256 rewardFrequency,
        uint256 initialReward,
        uint256 boostRate
    )
        CoreRewarder(
            targetAddress,
            rewardAddress,
            rewardRate,
            rewardFrequency,
            initialReward,
            boostRate
        )
    {}
}