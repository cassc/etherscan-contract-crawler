// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./invoiceMulti_V3.sol";
import "../../common/BaseInvoicesToken.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * @title Invoices for MultiFace DAO all networks
 * @notice Add createAndPay function
 */
contract InvoicesMultiV4 is InvoicesMultiV3, BaseInvoicesToken {
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function _create_invoice(
        uint256 _amount,
        address _seller,
        address _creator_addr,
        address _token
    ) internal returns (uint256) {
        require(tokenList[_token], "ERC20: token not in available list");
        require(_amount > feeCalculation(feeConst, ERC20Upgradeable(_token).decimals()), "Amount: need more amount");
        invoice_id = invoice_id.add(1);
        invoices[invoice_id] = Invoice(_amount, _seller, 0);
        invoiceCreator[invoice_id] = _creator_addr;
        invoiceToken[invoice_id] = _token;

        emit created(
            invoice_id,
            _amount,
            _seller,
            block.timestamp,
            _creator_addr,
            _token
        );
        return invoice_id;
    }

    /**
     * @notice Subscriber create invoice
     * @dev Send createInvoice event. State of invoice 0
     * @param _amount Amount of USDT for pay
     * @param _seller Address of seller
     * @param _token Address of token ERC20 for payment
     * @return Identifier of invoice
     */
    function create_invoice_token(
        uint256 _amount,
        address _seller,
        address _token
    ) external returns (uint256) {
        return _create_invoice(_amount, _seller, msg.sender, _token);
    }

    function _pay(
        uint256 _invoice_id,
        address _creator_addr
    ) internal override onlyAvailable(_invoice_id) {
        Invoice memory _invoice = invoices[_invoice_id];
        IERC20Upgradeable _token = usdt;
        if (invoiceToken[_invoice_id] != address(0)) {
            _token = IERC20Upgradeable(invoiceToken[_invoice_id]);
        }
        _token.safeTransferFrom(_creator_addr, address(this), _invoice.amount);

        (uint256 weiAmount, uint256 feeAmount) = getweiAmount(
            _invoice.amount,
            fee,
            invoiceCreator[_invoice_id],
            feeCalculation(feeConst, ERC20Upgradeable(address(_token)).decimals())
        );

        _token.safeTransfer(_invoice.seller, weiAmount);
        if (feeAmount > 0) {
            _token.safeTransfer(treasury, feeAmount);
            emit deductions(_invoice_id, feeAmount, block.timestamp);
        }
        invoices[_invoice_id].state = 1;
        emit paid(_invoice_id, _creator_addr);
    }

    /**
     * @notice Subscriber create invoice and pay it
     * @dev Send createInvoice event. State of invoice 0
     * @param _amount Amount of USDT for pay
     * @param _seller Address of seller
     * @param _token Address of token for payment
     */
    function create_and_pay(
        uint256 _amount,
        address _seller,
        address _token
    ) external {
        uint256 invoiceId = _create_invoice(
            _amount,
            _seller,
            msg.sender,
            _token
        );
        _pay(invoiceId, msg.sender);
    }
}