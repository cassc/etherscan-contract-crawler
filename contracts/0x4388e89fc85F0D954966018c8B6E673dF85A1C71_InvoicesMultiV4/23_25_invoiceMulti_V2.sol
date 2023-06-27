// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./invoiceMulti.sol";
import "../../common/BaseInvoicesEnterprice.sol";

/**
 * @title Invoices for MultiFace DAO nonBSC networks
 * @notice Accounting invoices for subscribers
 */
contract InvoicesMultiV2 is InvoicesMulti, BaseInvoicesEnterprice {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Subscriber create invoice
     * @dev Send createInvoice event. State of invoice 0
     * @param _amount Amount of USDT for pay
     * @param _seller Address of seller
     * @param _addInfo Json with addition fields for event
     * @return Identifier of invoice
     */
    function create_invoice(
        uint256 _amount,
        address _seller,
        string calldata _addInfo
    ) external virtual override returns (uint256) {
        require(_amount > feeConst, "Amount: need more amount");
        invoice_id = invoice_id.add(1);
        invoices[invoice_id] = Invoice(_amount, _seller, 0);
        invoiceCreator[invoice_id] = msg.sender;

        emit createInvoice(
            invoice_id,
            _amount,
            _seller,
            _addInfo,
            block.timestamp,
            msg.sender
        );
        return invoice_id;
    }

    /**
     * @notice Invoice payment method. USDT send to contract then to seller
     * without fee. Fee send to treasury contract
     * @dev Send createInvoice event. State of invoice 1
     * @param _invoice_id Identifier of invoice.
     */
    function pay(
        uint256 _invoice_id
    ) external virtual override onlyAvailable(_invoice_id) {
        Invoice memory _invoice = invoices[_invoice_id];
        uint256 allowance = usdt.allowance(msg.sender, address(this));
        require(_invoice.amount <= allowance, "Not enough USDT");
        usdt.safeTransferFrom(msg.sender, address(this), _invoice.amount);

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
        emit paid(_invoice_id, msg.sender);
    }
}