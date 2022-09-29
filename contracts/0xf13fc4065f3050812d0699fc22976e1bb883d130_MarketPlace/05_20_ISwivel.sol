// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.13;

import 'src/lib/Hash.sol';
import 'src/lib/Sig.sol';

// the behavioral Swivel Interface, Implemented by Swivel.sol
interface ISwivel {
    function initiate(
        Hash.Order[] calldata,
        uint256[] calldata,
        Sig.Components[] calldata
    ) external returns (bool);

    function exit(
        Hash.Order[] calldata,
        uint256[] calldata,
        Sig.Components[] calldata
    ) external returns (bool);

    function cancel(Hash.Order[] calldata) external returns (bool);

    function setAdmin(address) external returns (bool);

    function scheduleWithdrawal(address) external returns (bool);

    function scheduleFeeChange(uint16[4] calldata) external returns (bool);

    function blockWithdrawal(address) external returns (bool);

    function blockFeeChange() external returns (bool);

    function withdraw(address) external returns (bool);

    function changeFee(uint16[4] calldata) external returns (bool);

    function approveUnderlying(address[] calldata, address[] calldata)
        external
        returns (bool);

    function splitUnderlying(
        uint8,
        address,
        uint256,
        uint256
    ) external returns (bool);

    function combineTokens(
        uint8,
        address,
        uint256,
        uint256
    ) external returns (bool);

    function authRedeem(
        uint8,
        address,
        address,
        address,
        uint256
    ) external returns (bool);

    function redeemZcToken(
        uint8,
        address,
        uint256,
        uint256
    ) external returns (bool);

    function redeemVaultInterest(
        uint8,
        address,
        uint256
    ) external returns (bool);

    function redeemSwivelVaultInterest(
        uint8,
        address,
        uint256
    ) external returns (bool);
}