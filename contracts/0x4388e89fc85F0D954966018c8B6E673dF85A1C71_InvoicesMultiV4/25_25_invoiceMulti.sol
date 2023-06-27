// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../common/BaseInvoices.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title Invoices for MultiFace DAO nonBSC networks
 * @notice Accounting invoices for subscribers
 */
contract InvoicesMulti is BaseInvoices {
    using SafeMath for uint256;
    using SafeMath for uint16;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct Invoice {
        uint256 amount;
        address seller;
        uint8 state;
    }

    mapping(uint256 => Invoice) public invoices;
    uint256 public invoice_id;
    uint16 public fee;

    IERC20Upgradeable usdt;

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
     * @param timestamp time of ctreation
     * @param creator address of creator
     */
    event createInvoice(
        uint256 indexed invoice_id,
        uint256 amount,
        address indexed seller,
        string addInfo,
        uint256 timestamp,
        address creator
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
        address _usdt
    ) public initializer {
        fee = _fee;
        treasury = _treasury;
        usdt = IERC20Upgradeable(_usdt);
        feeConst = 1 * 1e18;

        __Ownable_init();
    }

    function set_treasury(address _treasury) external virtual onlyOwner {
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
        require(_amount > feeConst, "Amount: need more amount");
        invoice_id = invoice_id.add(1);
        invoices[invoice_id] = Invoice(_amount, _seller, 0);

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
    function pay(uint256 _invoice_id)
        external
        virtual
        onlyAvailable(_invoice_id)
    {
        Invoice memory _invoice = invoices[_invoice_id];
        uint256 allowance = usdt.allowance(msg.sender, address(this));
        require(_invoice.amount <= allowance, "Not enough USDT");
        usdt.safeTransferFrom(msg.sender, address(this), _invoice.amount);

        (uint256 weiAmount, uint256 feeAmount) = getweiAmount(
            _invoice.amount,
            fee
        );

        usdt.safeTransfer(_invoice.seller, weiAmount);
        if (feeAmount > 0) {
            usdt.safeTransfer(treasury, feeAmount);
            emit deductions(_invoice_id, feeAmount, block.timestamp);
        }
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
        virtual
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
    function set_fee(uint16 _fee) external virtual onlyOwner {
        fee = _fee;
    }

    /**
     * @notice Set usdt token
     * @dev Only for owner
     * @param _usdt Address of token
     */
    function setUSDT(address _usdt) external virtual onlyOwner {
        usdt = IERC20Upgradeable(_usdt);
    }
}