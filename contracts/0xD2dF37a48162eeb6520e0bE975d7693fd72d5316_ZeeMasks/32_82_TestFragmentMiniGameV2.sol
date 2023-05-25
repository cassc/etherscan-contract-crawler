// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../mini-game/FragmentMiniGame.sol";

/// @notice mock FragmentMiniGame implementation for testing purposes
contract TestFragmentMiniGameV2 is FragmentMiniGame {
    // solhint-disable-next-line comprehensive-interface
    function version() external pure returns (string memory) {
        return "V2";
    }
}