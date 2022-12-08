//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/finance/VestingWallet.sol";

contract VestingWalletFactory {
    event DeployedVestingWallet(
        address vestingWalletAddress,
        address beneficiaryAddress,
        uint64 startTimestamp,
        uint64 durationSeconds
    );

    function createVestingWallet(
        address[] memory beneficiaryAddressList,
        uint64[] memory startTimestampList,
        uint64[] memory durationSecondsList
    ) public {
        require(
            beneficiaryAddressList.length == startTimestampList.length,
            "Need to same length of each array"
        );
        require(
            durationSecondsList.length == startTimestampList.length,
            "Need to same length of each array"
        );
        for (uint64 i = 0; i < beneficiaryAddressList.length; i++) {
            VestingWallet vestingWallet = new VestingWallet(
                beneficiaryAddressList[i],
                startTimestampList[i],
                durationSecondsList[i]
            );
            emit DeployedVestingWallet(
                address(vestingWallet),
                beneficiaryAddressList[i],
                startTimestampList[i],
                durationSecondsList[i]
            );
        }
    }
}