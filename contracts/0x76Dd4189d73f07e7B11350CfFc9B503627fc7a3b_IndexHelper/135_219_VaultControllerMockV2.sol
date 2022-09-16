// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.13;

import "./VaultControllerMock.sol";

contract VaultControllerMockV2 is VaultControllerMock {
    function test() external pure returns (string memory) {
        return "Success";
    }

    function expectedWithdrawableAmount() external view virtual override returns (uint) {
        return VaultStakingMock(staking).withdrawable() + 1;
    }
}