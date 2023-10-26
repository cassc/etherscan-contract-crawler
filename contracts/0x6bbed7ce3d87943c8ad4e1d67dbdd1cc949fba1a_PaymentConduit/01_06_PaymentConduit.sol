// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.16 <0.9.0;

import {Initializable} from
    "openzeppelin-contracts/proxy/utils/Initializable.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

/**
 * @notice Payment conduit contract intended to act as a receiver for
 * project-specific revenues (e.g. secondary revenues) to allow an easier cash
 * flow analysis.
 */
contract PaymentConduit is Initializable {
    using SafeERC20 for IERC20;
    using Address for address payable;

    /**
     * @notice The target of the conduit to which all funds will be forwarded.
     */
    address payable public target;

    /**
     * @notice A brief description of the conduit intended to identify it.
     */
    string public description;

    /**
     * @notice Initializes the PaymentConduit, akin to a constructor.
     * @dev MUST be called by the Factory in the same transaction as deployment.
     */
    function initialize(address payable target_, string calldata description_)
        external
        payable
        initializer
    {
        target = target_;
        description = description_;
    }

    receive() external payable {
        forwardETH();
    }

    /**
     * @notice Sends the current ETH balance to the target.
     */
    function forwardETH() public {
        target.sendValue(address(this).balance);
    }

    /**
     * @notice Sends the current balance of a given ERC20 token to the target.
     */
    function forwardERC20(IERC20 token) public {
        token.safeTransfer(target, token.balanceOf(address(this)));
    }
}