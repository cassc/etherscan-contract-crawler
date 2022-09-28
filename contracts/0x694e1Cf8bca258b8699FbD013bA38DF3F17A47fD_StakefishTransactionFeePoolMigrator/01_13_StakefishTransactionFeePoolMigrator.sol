// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "StakefishTransactionFeePool.sol";
import "IMigrator.sol";

contract StakefishTransactionFeePoolMigrator is
    StakefishTransactionFeePool,
    IMigrator
{
    using Address for address payable;

    function closePoolForWithdrawal() external override nonReentrant devOnly {
        require(isOpenForWithdrawal, "Pool is already closed for withdrawal");
        isOpenForWithdrawal = false;
    }

    function openPoolForWithdrawal() external override nonReentrant devOnly {
        require(!isOpenForWithdrawal, "Pool is already open for withdrawal");
        isOpenForWithdrawal = true;
    }

    // Enable contract to transfer balance to another contract
    function migrate(address payable toAddress) external override nonReentrant devOnly {
        require(toAddress != address(0), "Invalid toAddress");
        toAddress.sendValue(address(this).balance);
    }

}