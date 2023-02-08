// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

import "./ICustomBill.sol";

interface ICustomBillRefillable is ICustomBill {
    function initialize(
        ICustomTreasury _customTreasury,
        BillCreationDetails memory _billCreationDetails,
        BillTerms memory _billTerms,
        BillAccounts memory _billAccounts,
        address[] memory _billRefillers
    ) external;

    function refillPayoutToken(uint256 _refillAmount) external;

    function grantRefillRole(address[] calldata _billRefillers) external;

    function revokeRefillRole(address[] calldata _billRefillers) external;
}