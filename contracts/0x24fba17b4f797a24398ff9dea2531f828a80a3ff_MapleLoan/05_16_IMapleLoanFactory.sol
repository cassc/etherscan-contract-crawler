// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { IMapleProxyFactory } from "../../modules/maple-proxy-factory/contracts/interfaces/IMapleProxyFactory.sol";

/// @title MapleLoanFactory deploys Loan instances.
interface IMapleLoanFactory is IMapleProxyFactory {

    /**
     *  @dev    Whether the proxy is a MapleLoan deployed by this factory.
     *  @param  proxy_  The address of the proxy contract.
     *  @return isLoan_ Whether the proxy is a MapleLoan deployed by this factory.
     */
    function isLoan(address proxy_) external view returns (bool isLoan_);

}