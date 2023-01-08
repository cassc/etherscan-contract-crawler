// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

import {ILendPool} from "./ILendPool.sol";
import {ILendPoolLoan} from "./ILendPoolLoan.sol";

interface ILendPoolAddressesProvider {
    function getLendPool() external view returns (ILendPool);

    function getLendPoolLoan() external view returns (ILendPoolLoan);

    function getLendPoolConfigurator() external view returns (address);
}