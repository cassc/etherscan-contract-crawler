// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Base} from  "../base/Base.sol";
import {IPaymentSplitter} from "../interfaces/IPaymentSplitter.sol";
import {LibPaymentSplitter} from "../libraries/LibPaymentSplitter.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract PaymentSplitterFacet is Base, IPaymentSplitter {
    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

    function init(address[] calldata _payees, uint256[] calldata _shares) external {
        LibPaymentSplitter.init(_payees, _shares);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     */
    function release(address payable account) external {
        LibPaymentSplitter.release(account);
    }

    /**
     * @dev Triggers a transfer to `account` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     */
    function release(IERC20 token, address account) external {
        LibPaymentSplitter.release(token, account);
    }

    function releaseAll() external {
        address[] storage payees = LibPaymentSplitter.paymentStorage().payees;
        for (uint256 i = 0; i < payees.length; i++) {
            LibPaymentSplitter.release(payable(payees[i]));
        }
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() external view returns (uint256) {
        return LibPaymentSplitter.totalShares();
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() external view returns (uint256) {
        return LibPaymentSplitter.totalReleased();
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) external view returns (uint256) {
        return LibPaymentSplitter.erc20TotalReleased(token);
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) external view returns (uint256) {
        return LibPaymentSplitter.shares(account);
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) external view returns (uint256) {
        return LibPaymentSplitter.released(account);
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) external view returns (uint256) {
        return LibPaymentSplitter.erc20Released(token, account);
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) external view returns (address) {
        return LibPaymentSplitter.payees(index);
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.
     */
    function releasable(address account) external view returns (uint256) {
        return LibPaymentSplitter.releasable(account);
    }

    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(IERC20 token, address account) external view returns (uint256) {
        return LibPaymentSplitter.releasable(token, account);
    }
}