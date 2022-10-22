// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./WithdrawableStorage.sol";
import "./WithdrawableInternal.sol";
import "./IWithdrawable.sol";

/**
 * @title Withdrawable
 * @notice Allow withdrwaing any ERC20 or native tokens from the contract.
 *
 * @custom:type eip-2535-facet
 * @custom:category Finance
 * @custom:provides-interfaces IWithdrawable
 */
contract Withdrawable is IWithdrawable, WithdrawableInternal {
    function withdraw(address[] calldata claimTokens, uint256[] calldata amounts) external {
        _withdraw(claimTokens, amounts);
    }

    function withdrawRecipient() external view override returns (address) {
        return _withdrawRecipient();
    }

    function withdrawRecipientLocked() external view override returns (bool) {
        return _withdrawRecipientLocked();
    }

    function withdrawPowerRevoked() external view override returns (bool) {
        return _withdrawPowerRevoked();
    }

    function withdrawMode() external view override returns (Mode) {
        return _withdrawMode();
    }

    function withdrawModeLocked() external view override returns (bool) {
        return _withdrawModeLocked();
    }
}