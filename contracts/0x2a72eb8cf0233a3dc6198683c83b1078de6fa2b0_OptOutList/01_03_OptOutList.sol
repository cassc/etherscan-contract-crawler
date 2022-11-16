// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "openzeppelin/access/Ownable.sol";

// Via the "opt-out" list, creators are able to disallow collections they
// own from being tradeable on Forward. The owner of the contract has the
// power of overriding the status of any collection (useful in cases when
// the collection doesn't follow the standard ownership interface).
contract OptOutList is Ownable {
    // Errors

    error AlreadySet();
    error Unauthorized();

    // Events

    event OptOutListUpdated(address token, bool optedOut);

    // Private fields

    // Use `uint256` instead of `bool` for gas-efficiency
    // Reference:
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/58f635312aa21f947cae5f8578638a85aa2519f5/contracts/security/ReentrancyGuard.sol#L23-L27
    mapping(address => uint256) private optOutStatus;

    // Public methods

    function setOptOutStatus(address token, bool status) external {
        if (msg.sender != Ownable(token).owner()) {
            revert Unauthorized();
        }

        _setOptOutStatus(token, status);
    }

    function optedOut(address token) external view returns (bool status) {
        return optOutStatus[token] == 1 ? true : false;
    }

    // Restricted methods

    function adminSetOptOutStatus(address token, bool status) external {
        if (msg.sender != owner()) {
            revert Unauthorized();
        }

        _setOptOutStatus(token, status);
    }

    // Internal methods

    function _setOptOutStatus(address token, bool status) internal {
        uint256 currentStatus = optOutStatus[token] == 1 ? 1 : 2;
        uint256 newStatus = status ? 1 : 2;
        if (currentStatus == newStatus) {
            revert AlreadySet();
        }

        optOutStatus[token] = newStatus;
        emit OptOutListUpdated(token, status);
    }
}