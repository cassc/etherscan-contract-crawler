// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {PaymentSplitter} from "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title RoyaltySplitter
 * @author Lozz (@lozzereth / www.allthingsweb3.com)
 * @notice Adaption of PaymentSplitter that enables all payees to be paid in ERC20
 *         and ETH tokens in one transaction. Designed for Royalty Distribution.
 */
contract RoyaltySplitter is PaymentSplitter {
    constructor(address[] memory payees, uint256[] memory shares_)
        PaymentSplitter(payees, shares_)
    {}

    /**
     * @notice Release all of an ETH token for all shareholders
     */
    function releaseAll() public {
        for (uint256 i; ; ++i) {
            try this.payee(i) returns (address shareholder) {
                this.release(payable(shareholder));
            } catch (bytes memory) {
                break;
            }
        }
    }

    /**
     * @notice Release all of an ERC20 token for all shareholders
     * @param token ERC20 Token Address
     */
    function releaseAll(IERC20 token) public {
        for (uint256 i; ; ++i) {
            try this.payee(i) returns (address shareholder) {
                release(token, shareholder);
            } catch (bytes memory) {
                break;
            }
        }
    }
}