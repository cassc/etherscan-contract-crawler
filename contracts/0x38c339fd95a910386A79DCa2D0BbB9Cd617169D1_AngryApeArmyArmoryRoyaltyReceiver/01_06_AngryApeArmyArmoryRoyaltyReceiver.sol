// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@massless.io/smart-contract-library/contracts/utils/WithdrawalSplittable.sol";

contract AngryApeArmyArmoryRoyaltyReceiver is WithdrawalSplittable {
    address[] private beneficiary_wallets = [
        address(0x6ab71C2025442B694C8585aCe2fc06D877469D30),
        address(0x901FC05c4a4bC027a8979089D716b6793052Cc16),
        address(0xd196e0aFacA3679C27FC05ba8C9D3ABBCD353b5D)
    ];
    uint256[] private beneficiary_splits = [7000, 2000, 1000];

    constructor() {
        setBeneficiaries(beneficiary_wallets, beneficiary_splits);
    }
}