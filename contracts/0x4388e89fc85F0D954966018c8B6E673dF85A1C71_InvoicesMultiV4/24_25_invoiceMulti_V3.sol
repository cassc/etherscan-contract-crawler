// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./invoiceMulti_V2.sol";

/**
 * @title Invoices for MultiFace DAO nonBSC networks
 * @notice Add createAndPay function
 */
contract InvoicesMultiV3 is InvoicesMultiV2 {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function _create_invoice(
        uint256 _amount,
        address _seller,
        string calldata _addInfo,
        address _creator_addr
    ) internal returns (uint256) {
        require(_amount > feeConst, "Amount: need more amount");
        invoice_id = invoice_id.add(1);
        invoices[invoice_id] = Invoice(_amount, _seller, 0);
        invoiceCreator[invoice_id] = _creator_addr;

        emit createInvoice(
            invoice_id,
            _amount,
            _seller,
            _addInfo,
            block.timestamp,
            _creator_addr
        );
        return invoice_id;
    }

    function _pay(
        uint256 _invoice_id,
        address _creator_addr
    ) internal virtual onlyAvailable(_invoice_id) {
        Invoice memory _invoice = invoices[_invoice_id];
        usdt.safeTransferFrom(_creator_addr, address(this), _invoice.amount);

        (uint256 weiAmount, uint256 feeAmount) = getweiAmount(
            _invoice.amount,
            fee,
            invoiceCreator[_invoice_id],
            feeConst
        );

        usdt.safeTransfer(_invoice.seller, weiAmount);
        if (feeAmount > 0) {
            usdt.safeTransfer(treasury, feeAmount);
            emit deductions(_invoice_id, feeAmount, block.timestamp);
        }
        invoices[_invoice_id].state = 1;
        emit paid(_invoice_id, _creator_addr);
    }

    function create_invoice(
        uint256 _amount,
        address _seller,
        string calldata _addInfo
    ) external override returns (uint256) {
        return _create_invoice(_amount, _seller, _addInfo, msg.sender);
    }

    function pay(
        uint256 _invoice_id
    ) external override onlyAvailable(_invoice_id) {
        _pay(_invoice_id, msg.sender);
    }

    /**
     * @notice Subscriber create invoice and pay it
     * @dev Send createInvoice event. State of invoice 0
     * @param _amount Amount of USDT for pay
     * @param _seller Address of seller
     */
    function createAndPay(
        uint256 _amount,
        address _seller,
        string calldata _addInfo
    ) external {
        uint256 invoiceId = _create_invoice(
            _amount,
            _seller,
            _addInfo,
            msg.sender
        );
        _pay(invoiceId, msg.sender);
    }
}