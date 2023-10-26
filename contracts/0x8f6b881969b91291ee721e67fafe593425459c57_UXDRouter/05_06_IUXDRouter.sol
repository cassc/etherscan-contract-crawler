// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {IDepository} from "../integrations/IDepository.sol";

interface IUXDRouter {
    function registerDepository(address depository, address asset)
        external;

    function unregisterDepository(address depository, address asset)
        external;

    function findDepositoryForDeposit(address asset, uint256 amount)
        external
        view
        returns (address);

    function findDepositoryForRedeem(address asset, uint256 redeemAmount)
        external
        view
        returns (address);
}