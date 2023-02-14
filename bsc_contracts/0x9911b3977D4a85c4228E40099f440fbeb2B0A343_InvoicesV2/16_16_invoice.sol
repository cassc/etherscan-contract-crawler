// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../common/ISubscribers.sol";
import "../../common/BaseProxy.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Invoices for MultiFace DAO
 * @notice Accounting invoices for subscribers
 */
contract Invoices is BaseProxy {
    using SafeMath for uint256;
    using SafeMath for uint16;

    struct Invoice {
        uint256 amount;
        address seller;
        uint8 state;
    }

    mapping(uint256 => Invoice) public invoices;
    uint256 public invoice_id;
    uint16 public fee;

    IERC20 usdt;

    address public subscribersAddr;
    address public treasury;

    /**
     * @notice Emitted when invoice was paid
     * @param invoice_id Identifier of invoice. Indexed
     * @param _payer Address of payer
     */
    event paid(uint256 indexed invoice_id, address _payer);

    /**
     * @notice Emitted when invoice was canceled
     * @param invoice_id Identifier of invoice. Indexed
     */
    event canceled(uint256 indexed invoice_id);

    /**
     * @notice Emitted when invoice was created
     * @param invoice_id Identifier of invoice. Indexed
     * @param amount Amount of USDT for pay
     * @param seller Address of seller. Indexed
     * @param addInfo Json with addition fields
     */
    event createInvoice(
        uint256 indexed invoice_id,
        uint256 amount,
        address indexed seller,
        string addInfo
    );

    modifier onlyAvailable(uint256 _invoice_id) {
        require(invoices[_invoice_id].state != 2, "Invoice: non-available");
        require(invoices[_invoice_id].state != 1, "Invoice: already paid");
        _;
    }

    modifier onlyOwnerSeller(uint256 _invoice_id) {
        require(
            msg.sender == invoices[_invoice_id].seller || msg.sender == owner(),
            "No access"
        );
        _;
    }

    function initialize(
        uint16 _fee,
        address _treasury,
        address _subscribersAddr,
        address _usdt
    ) public initializer {
        fee = _fee;
        treasury = _treasury;
        subscribersAddr = _subscribersAddr;
        usdt = IERC20(_usdt);

        __Ownable_init();
    }

    function set_treasury(address _treasury) external onlyOwner {
        treasury = _treasury;
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
    ) external virtual returns (uint256) {
        require(
            ISubscribers(subscribersAddr).isSubscribed(msg.sender),
            "Sender: non-subscriber"
        );
        invoice_id = invoice_id.add(1);
        invoices[invoice_id] = Invoice(_amount, _seller, 0);

        emit createInvoice(invoice_id, _amount, _seller, _addInfo);
        return invoice_id;
    }

    /**
     * @notice Invoice payment method. USDT send to contract then to seller
     * without fee. Fee send to treasury contract
     * @dev Send createInvoice event. State of invoice 1
     * @param _invoice_id Identifier of invoice.
     */
    function pay(uint256 _invoice_id) external onlyAvailable(_invoice_id) {
        Invoice memory _invoice = invoices[_invoice_id];
        uint256 allowance = usdt.allowance(msg.sender, address(this));
        require(_invoice.amount <= allowance, "Not enough USDT");
        usdt.transferFrom(msg.sender, address(this), _invoice.amount);
        uint256 main = 10000;
        uint256 weiAmount = _invoice.amount.mul(main.sub(fee)).div(main);
        usdt.transfer(_invoice.seller, weiAmount);
        usdt.transfer(treasury, _invoice.amount.sub(weiAmount));
        invoices[_invoice_id].state = 1;
        emit paid(_invoice_id, msg.sender);
    }

    /**
     * @notice Cancel by seller or admin invoice. It will not be possible to pay this invoice.
     * @dev Send canceled event. state of invoice 2
     * @param _invoice_id Identifier of invoice.
     */
    function cancel(uint256 _invoice_id)
        external
        onlyOwnerSeller(_invoice_id)
        onlyAvailable(_invoice_id)
    {
        invoices[_invoice_id].state = 2;
        emit canceled(_invoice_id);
    }

    /**
     * @notice Set fee for payment
     * @dev Only for owner
     * @param _fee Number 0 .. 10000. Mean 1 - to Treasury 0.01%
     */
    function set_fee(uint16 _fee) external onlyOwner {
        fee = _fee;
    }

    /**
     * @notice Set address of Subscribe contract for check status of subscriber (seller)
     * @dev Only for owner
     * @param _subscribersAddr Address of contract
     */
    function set_subscribersAddr(address _subscribersAddr) external onlyOwner {
        subscribersAddr = _subscribersAddr;
    }
}