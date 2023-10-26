// SPDX-License-Identifier: LZBL-1.1
// Copyright 2023 LayerZero Labs Ltd.
// You may obtain a copy of the License at
// https://github.com/LayerZero-Labs/license/blob/main/LICENSE-LZBL-1.1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Role} from "../interfaces/IVaultManager.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library Governance {
    using SafeERC20 for IERC20;

    uint16 internal constant ONE_HUNDRED_PERCENT = 10000; // 100%
    uint16 internal constant RESERVE_FEE_BPS_CAP = 300; // 3%
    // A % fee is applicable on yield distribution for the vault service.
    uint16 internal constant REDEMPTION_FEE_BPS_CAP_MIN = 10; //0.1%

    struct Fee {
        uint16 bps;
        uint16 cap;
    }

    struct Info {
        mapping(Role => Fee) fees;
        mapping(Role => address) roles;
        uint operatorLastPing; // timestamp
    }

    event PaidRedemptionFee(address indexed to, uint amount);

    // ========================= Operator =========================
    function ping(Info storage _self) internal {
        _self.operatorLastPing = block.timestamp;
    }

    // ========================= Fees =========================
    function getRedemptionFee(Info storage _self, uint _amount) internal view returns (uint fee) {
        return (_amount * _self.fees[Role.FOUNDATION].bps) / ONE_HUNDRED_PERCENT;
    }

    function payRedemptionFee(Info storage _self, IERC20 _token, uint _amount) internal returns (uint) {
        uint fee = getRedemptionFee(_self, _amount);
        // pay redemption fee to operator
        address _to = _self.roles[Role.OPERATOR];
        _token.safeTransfer(_to, fee);
        emit PaidRedemptionFee(_to, fee);

        return _amount - fee;
    }
}