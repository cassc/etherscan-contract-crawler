// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.18;

/**
 * @title LendPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Bend Governance
 * @author Bend
 **/
interface ILendPoolAddressesProvider {
    function getLendPool() external view returns (address);

    function getLendPoolLoan() external view returns (address);
}