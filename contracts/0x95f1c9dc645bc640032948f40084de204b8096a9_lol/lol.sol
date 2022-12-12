/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
}

contract lol {

    struct Invoice {
        uint invoiceId;
        uint merchantId;
        address from;
        uint coin;
        uint256 value;
    }

    IERC20 usdt = IERC20(address(0xdAC17F958D2ee523a2206206994597C13D831ec7));

    mapping (uint => Invoice) public invoices;

    function reciveFunds(uint _invoiceId, uint _merchantId, uint _coin, uint256 _value, address payable _to) public payable {
        Invoice memory newInvoice = Invoice(
            _invoiceId,
            _merchantId,
            msg.sender,
            _coin,
            _value
        );
        invoices[_invoiceId] = newInvoice;

        uint256 withdrawAmount = _value / 100 * 97 ;

        if (_coin == 1) {
            usdt.transfer(_to, withdrawAmount);
        } else if (_coin == 0) {
        _to.call{value: withdrawAmount}("");
        }
    }
}