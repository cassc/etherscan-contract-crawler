// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./invoice.sol";

contract InvoicesV2 is Invoices {
    using SafeMath for uint256;
    using SafeMath for uint16;

    struct Trial {
        uint256 endPeriod;
        uint8 count;
    }

    uint8 public trialCount;
    uint256 constant monthPeriod = 2592000;
    mapping(address => Trial) public sellers;

    /**
     * @notice Emitted when invoice was paid
     * @param invoice_id Identifier of invoice. Indexed
     * @param amount Amount of USDT for pay
     * @param seller Address of seller. Indexed
     * @param addInfo Json with addition fields
     * @param timestamp time of ctreation
     */
    event createInvoiceV2(
        uint256 indexed invoice_id,
        uint256 amount,
        address indexed seller,
        string addInfo,
        uint256 timestamp
    );

    /**
     * @notice Emitted when invoice was paid
     * @param invoice_id Identifier of invoice. Indexed
     * @param amount Amount of USDT for pay
     * @param seller Address of seller. Indexed
     * @param addInfo Json with addition fields
     * @param timestamp time of ctreation
     * @param creator address of creator
     */
    event createInvoiceV3(
        uint256 indexed invoice_id,
        uint256 amount,
        address indexed seller,
        string addInfo,
        uint256 timestamp,
        address creator
    );

    /**
     * @notice Emitted when invoice was added for address
     * @param seller Address of invoice owner. Indexed
     * @param endPeriod timestamp when will 30 days expired
     * @param count Count of created invoices
     */
    event addrInvoices(
        address indexed seller,
        uint256 endPeriod,
        uint256 count
    );

    /**
     * @notice Check if you can create invoice without subscribe (only 5 by 30 days)
     * @param _seller Address of seller
     * @return status of checking
     */
    function isTrial(address _seller) internal view returns (bool) {
        Trial memory _trial = sellers[_seller];
        return
            (block.timestamp <= _trial.endPeriod &&
                _trial.count < trialCount) ||
            (block.timestamp > _trial.endPeriod);
    }

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
    ) external override returns (uint256) {
        bool isSubscrider = ISubscribers(subscribersAddr).isSubscribed(
            msg.sender
        );
        require(
            isSubscrider || isTrial(msg.sender),
            "Sender: non-subscriber or end trial invoices"
        );
        invoice_id = invoice_id.add(1);
        invoices[invoice_id] = Invoice(_amount, _seller, 0);
        if (!isSubscrider) {
            Trial memory _trial = sellers[msg.sender];
            if (block.timestamp > _trial.endPeriod) {
                sellers[msg.sender] = Trial(
                    block.timestamp.add(monthPeriod),
                    1
                );
            } else {
                sellers[msg.sender].count = _trial.count + 1;
            }
            emit addrInvoices(
                msg.sender,
                sellers[msg.sender].endPeriod,
                sellers[msg.sender].count
            );
        }
        emit createInvoiceV3(
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
     * @notice Set count of free invoices by 30 days
     * @dev Only for owner
     * @param _trialCount Count of free invoices by trial period
     */
    function set_trialCount(uint8 _trialCount) external onlyOwner {
        trialCount = _trialCount;
    }
}