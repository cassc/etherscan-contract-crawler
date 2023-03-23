// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import './IERC20.sol';
import './Address.sol';
import './SafeERC20.sol';
import './ReentrancyGuard.sol';
import './Context.sol';
import './Ownable.sol';

contract PaydeceEscrow is ReentrancyGuard, Ownable {
    // 0.1 es 100 porque se multiplico por mil => 0.1 X 1000 = 100
    uint256 public feeSeller;
    uint256 public feeBuyer;
    uint256 public feesAvailableNativeCoin;
    using SafeERC20 for IERC20;
    mapping(uint => Escrow) public escrows;
    mapping(address => bool) whitelistedStablesAddresses;
    mapping(IERC20 => uint) public feesAvailable;

    event EscrowDeposit(uint indexed orderId, Escrow escrow);
    event EscrowComplete(uint indexed orderId, Escrow escrow);
    event EscrowDisputeResolved(uint indexed orderId);

    // Buyer defined as who buys usdt
    modifier onlyBuyer(uint _orderId) {
        require(
            msg.sender == escrows[_orderId].buyer,
            "Only Buyer can call this"
        );
        _;
    }

    // Seller defined as who sells usdt
    // modifier onlySeller(uint _orderId) {
    //     require(
    //         msg.sender == escrows[_orderId].seller,
    //         "Only Seller can call this"
    //     );
    //     _;
    // }

    enum EscrowStatus {
        Unknown,
        Funded,
        NOT_USED,
        Completed,
        Refund,
        Arbitration
    }

    struct Escrow {
        address payable buyer; //Comprador
        address payable seller; //Vendedor
        uint256 value; //Monto compra
        uint256 sellerfee; //Comision vendedor
        uint256 buyerfee; //Comision comprador
        IERC20 currency; //Moneda
        EscrowStatus status; //Estado
    }

    //uint256 private feesAvailable;  // summation of fees that can be withdrawn

    constructor() {
        feeSeller = 0;
        feeBuyer = 0;
    }

    // ================== Begin External functions ==================
    function setFeeSeller(uint256 _feeSeller) external onlyOwner {
        require(
            _feeSeller >= 0 && _feeSeller <= (1 * 1000),
            "The fee can be from 0% to 1%"
        );
        feeSeller = _feeSeller;
    }

    function setFeeBuyer(uint256 _feeBuyer) external onlyOwner {
        require(
            _feeBuyer >= 0 && _feeBuyer <= (1 * 1000),
            "The fee can be from 0% to 1%"
        );
        feeBuyer = _feeBuyer;
    }

    /* This is called by the server / contract owner */
    function createEscrow(
        uint _orderId,
        address payable _seller,
        uint256 _value,
        IERC20 _currency
    ) external virtual {
        require(
            escrows[_orderId].status == EscrowStatus.Unknown,
            "Escrow already exists"
        );

        require(
            whitelistedStablesAddresses[address(_currency)],
            "Address Stable to be whitelisted"
        );

        require(msg.sender != _seller, "seller cannot be the same as buyer");

        uint8 _decimals = _currency.decimals();
        //Obtiene el monto a transferir desde el comprador al contrato
        uint256 _amountFeeBuyer = ((_value * (feeBuyer * 10 ** _decimals)) /
            (100 * 10 ** _decimals)) / 1000;

        //Valida el Allowance
        uint256 _allowance = _currency.allowance(msg.sender, address(this));
        require(
            _allowance >= (_value + _amountFeeBuyer),
            "Seller approve to Escrow first"
        );

        //Transfer USDT to contract
        _currency.safeTransferFrom(
            msg.sender,
            address(this),
            (_value + _amountFeeBuyer)
        );

        escrows[_orderId] = Escrow(
            payable(msg.sender),
            _seller,
            _value,
            feeSeller,
            feeBuyer,
            _currency,
            EscrowStatus.Funded
        );

        emit EscrowDeposit(_orderId, escrows[_orderId]);
    }

    function createEscrowNativeCoin(
        uint _orderId,
        address payable _seller,
        uint256 _value
    ) external payable virtual {
        require(
            escrows[_orderId].status == EscrowStatus.Unknown,
            "Escrow already exists"
        );

        require(msg.sender != _seller, "seller cannot be the same as buyer");

        uint8 _decimals = 18;
        //Obtiene el monto a transferir desde el comprador al contrato
        uint256 _amountFeeBuyer = ((_value * (feeBuyer * 10 ** _decimals)) /
            (100 * 10 ** _decimals)) / 1000;

        require((_value + _amountFeeBuyer) <= msg.value, "Incorrect amount");

        escrows[_orderId] = Escrow(
            payable(msg.sender),
            _seller,
            _value,
            feeSeller,
            feeBuyer,
            IERC20(address(0)),
            EscrowStatus.Funded
        );

        emit EscrowDeposit(_orderId, escrows[_orderId]);
    }

    function releaseEscrowOwner(uint _orderId) external onlyOwner {
        _releaseEscrow(_orderId);
    }

    function releaseEscrowOwnerNativeCoin(uint _orderId) external onlyOwner {
        _releaseEscrowNativeCoin(_orderId);
    }

    /* This is called by the buyer wallet */
    function releaseEscrow(uint _orderId) external onlyBuyer(_orderId) {
        _releaseEscrow(_orderId);
    }

    function releaseEscrowNativeCoin(
        uint _orderId
    ) external onlyBuyer(_orderId) {
        _releaseEscrowNativeCoin(_orderId);
    }

    /// release funds to the buyer - cancelled contract
    function refundBuyer(uint _orderId) external nonReentrant onlyOwner {
        //require(escrows[_orderId].status == EscrowStatus.Refund,"Refund not approved");

        uint256 _value = escrows[_orderId].value;
        address _buyer = escrows[_orderId].buyer;
        IERC20 _currency = escrows[_orderId].currency;

        // dont charge seller any fees - because its a refund
        delete escrows[_orderId];

        _currency.safeTransfer(_buyer, _value);

        emit EscrowDisputeResolved(_orderId);
    }

    function refundBuyerNativeCoin(
        uint _orderId
    ) external nonReentrant onlyOwner {
        //require(escrows[_orderId].status == EscrowStatus.Refund,"Refund not approved");

        uint256 _value = escrows[_orderId].value;
        address _buyer = escrows[_orderId].buyer;

        // dont charge seller any fees - because its a refund
        delete escrows[_orderId];

        //Transfer call
        (bool sent, ) = payable(address(_buyer)).call{value: _value}("");
        require(sent, "Transfer failed.");

        emit EscrowDisputeResolved(_orderId);
    }

    function withdrawFees(IERC20 _currency) external onlyOwner {
        uint _amount;

        // This check also prevents underflow
        require(feesAvailable[_currency] > 0, "Amount > feesAvailable");

        _amount = feesAvailable[_currency];

        feesAvailable[_currency] -= _amount;

        _currency.safeTransfer(owner(), _amount);
    }

    function withdrawFeesNativeCoin() external onlyOwner {
        uint256 _amount;

        // This check also prevents underflow
        require(feesAvailableNativeCoin > 0, "Amount > feesAvailable");

        //_amount = feesAvailable[_currency];
        _amount = feesAvailableNativeCoin;

        feesAvailableNativeCoin -= _amount;

        //Transfer
        (bool sent, ) = payable(msg.sender).call{value: _amount}("");
        require(sent, "Transfer failed.");
    }

    // ================== End External functions ==================

    // ================== Begin External functions that are pure ==================
    function version() external pure virtual returns (string memory) {
        return "3.0.0";
    }

    // ================== End External functions that are pure ==================

    /// ================== Begin Public functions ==================
    function getState(uint _orderId) public view returns (EscrowStatus) {
        Escrow memory _escrow = escrows[_orderId];
        return _escrow.status;
    }

    // Get the amount of transaction
    function getValue(uint _orderId) public view returns (uint256) {
        Escrow memory _escrow = escrows[_orderId];
        return _escrow.value;
    }

    function addStablesAddresses(
        address _addressStableToWhitelist
    ) public onlyOwner {
        whitelistedStablesAddresses[_addressStableToWhitelist] = true;
    }

    function delStablesAddresses(
        address _addressStableToWhitelist
    ) public onlyOwner {
        whitelistedStablesAddresses[_addressStableToWhitelist] = false;
    }

    /// ================== End Public functions ==================

    // ================== Begin Private functions ==================
    function _releaseEscrow(uint _orderId) private nonReentrant {
        require(
            escrows[_orderId].status == EscrowStatus.Funded,
            "USDT has not been deposited"
        );

        uint8 _decimals = escrows[_orderId].currency.decimals();

        //Obtiene el monto a transferir desde el comprador al contrato        //sellerfee //buyerfee
        uint256 _amountFeeBuyer = ((escrows[_orderId].value *
            (escrows[_orderId].buyerfee * 10 ** _decimals)) /
            (100 * 10 ** _decimals)) / 1000;
        uint256 _amountFeeSeller = ((escrows[_orderId].value *
            (escrows[_orderId].sellerfee * 10 ** _decimals)) /
            (100 * 10 ** _decimals)) / 1000;

        //feesAvailable += _amountFeeBuyer + _amountFeeSeller;
        feesAvailable[escrows[_orderId].currency] +=
            _amountFeeBuyer +
            _amountFeeSeller;

        // write as complete, in case transfer fails
        escrows[_orderId].status = EscrowStatus.Completed;

        //Transfer to sellet Price Asset - FeeSeller
        escrows[_orderId].currency.safeTransfer(
            escrows[_orderId].seller,
            escrows[_orderId].value - _amountFeeSeller
        );

        emit EscrowComplete(_orderId, escrows[_orderId]);
        delete escrows[_orderId];
    }

    function _releaseEscrowNativeCoin(uint _orderId) private nonReentrant {
        require(
            escrows[_orderId].status == EscrowStatus.Funded,
            "USDT has not been deposited"
        );

        uint8 _decimals = 18; //Wei

        //Obtiene el monto a transferir desde el comprador al contrato        //sellerfee //buyerfee
        uint256 _amountFeeBuyer = ((escrows[_orderId].value *
            (escrows[_orderId].buyerfee * 10 ** _decimals)) /
            (100 * 10 ** _decimals)) / 1000;
        uint256 _amountFeeSeller = ((escrows[_orderId].value *
            (escrows[_orderId].sellerfee * 10 ** _decimals)) /
            (100 * 10 ** _decimals)) / 1000;

        //Registra los fees obtenidos para Paydece
        feesAvailableNativeCoin += _amountFeeBuyer + _amountFeeSeller;

        // write as complete, in case transfer fails
        escrows[_orderId].status = EscrowStatus.Completed;

        //Transfer to sellet Price Asset - FeeSeller
        (bool sent, ) = escrows[_orderId].seller.call{
            value: escrows[_orderId].value - _amountFeeSeller
        }("");
        require(sent, "Transfer failed.");

        emit EscrowComplete(_orderId, escrows[_orderId]);
        delete escrows[_orderId];
    }
    // ================== End Private functions ==================
}