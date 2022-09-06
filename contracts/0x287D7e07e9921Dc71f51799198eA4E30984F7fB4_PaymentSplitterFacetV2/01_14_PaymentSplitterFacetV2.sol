// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PaymentSplitterLibV2, IERC20} from "./PaymentSplitterLibV2.sol";
import {AccessControlModifiers} from "../AccessControl/AccessControlModifiers.sol";
import {PausableModifiers} from "../Pausable/PausableModifiers.sol";
import {DiamondInitializable} from "../../utils/DiamondInitializable.sol";

contract PaymentSplitterFacetV2 is
    AccessControlModifiers,
    DiamondInitializable,
    PausableModifiers
{
    function setPaymentSplitsV2(
        address[] memory payees,
        uint256[] memory shares_,
        bytes memory approvalSignature
    ) external onlyOwner whenNotPaused initializer("payment.splitter.v2") {
        PaymentSplitterLibV2.setPaymentSplits(
            payees,
            shares_,
            approvalSignature
        );
    }

    function releaseTokenV2(IERC20 token, address account)
        external
        whenNotPaused
        onlyOperator
    {
        PaymentSplitterLibV2.release(token, account);
    }

    function releaseV2(address payable account)
        external
        whenNotPaused
        onlyOperator
    {
        PaymentSplitterLibV2.release(account);
    }

    function payeeV2(uint256 index) public view returns (address) {
        return PaymentSplitterLibV2.payee(index);
    }

    function releasedTokenV2(IERC20 token, address account)
        public
        view
        returns (uint256)
    {
        return PaymentSplitterLibV2.released(token, account);
    }

    function releasedV2(address account) public view returns (uint256) {
        return PaymentSplitterLibV2.released(account);
    }

    function sharesV2(address account) public view returns (uint256) {
        return PaymentSplitterLibV2.shares(account);
    }

    function totalReleasedTokenV2(IERC20 token) public view returns (uint256) {
        return PaymentSplitterLibV2.totalReleased(token);
    }

    function totalReleasedV2() public view returns (uint256) {
        return PaymentSplitterLibV2.totalReleased();
    }

    function totalSharesV2() public view returns (uint256) {
        return PaymentSplitterLibV2.totalShares();
    }

    function getPaymentSplitsV2()
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        return PaymentSplitterLibV2.getPaymentSplits();
    }

    function releaseAllV2() public onlyOwner whenNotPaused nonReentrant {
        PaymentSplitterLibV2.releaseAll();
    }

    function releaseAllTokenV2(IERC20 token)
        public
        onlyOwner
        whenNotPaused
        nonReentrant
    {
        PaymentSplitterLibV2.releaseAllToken(token);
    }

    modifier nonReentrant() {
        PaymentSplitterLibV2.PaymentSplitterStorage
            storage ps = PaymentSplitterLibV2.paymentSplitterStorage();
        require(!ps._entered);
        ps._entered = true;
        _;
        ps._entered = false;
    }
}