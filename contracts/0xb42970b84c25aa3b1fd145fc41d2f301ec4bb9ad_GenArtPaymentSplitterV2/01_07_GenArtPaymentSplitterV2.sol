// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./GenArtAccess.sol";
import "./IGenArtPaymentSplitterV2.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract GenArtPaymentSplitterV2 is GenArtAccess, IGenArtPaymentSplitterV2 {
    struct Payment {
        address[] payees;
        uint256[] shares;
    }

    event IncomingPayment(
        address collection,
        uint256 paymentType,
        address payee,
        uint256 amount
    );

    mapping(address => uint256) public _balances;
    mapping(address => uint256) public _wethBalances;
    mapping(address => Payment) private _payments;
    mapping(address => Payment) private _paymentsRoyalties;
    address public _wethAddress;
    bool public _destoryed = false;

    constructor(address wethAddress_) GenArtAccess() {
        _wethAddress = wethAddress_;
    }

    /**
     * @dev Throws if called by any account other than the owner, admin or collection contract.
     */
    modifier onlyCollectionContractOrAdmin(bool isCollection) {
        address sender = _msgSender();
        require(
            isCollection || (owner() == sender) || admins[sender],
            "GenArtAccess: caller is not the owner nor admin"
        );
        _;
    }

    function addCollectionPayment(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) public override onlyAdmin {
        require(!_destoryed, "GenArtPaymentSplitterV2: contract is destroyed");
        require(
            shares.length > 0 && shares.length == payees.length,
            "GenArtPaymentSplitterV2: invalid arguments"
        );

        _payments[collection] = Payment(payees, shares);
    }

    function addCollectionPaymentRoyalty(
        address collection,
        address[] memory payees,
        uint256[] memory shares
    ) public override onlyAdmin {
        require(!_destoryed, "GenArtPaymentSplitterV2: contract is destroyed");
        require(
            shares.length > 0 && shares.length == payees.length,
            "GenArtPaymentSplitterV2: invalid arguments"
        );
        _paymentsRoyalties[collection] = Payment(payees, shares);
    }

    function sanityCheck(address collection, uint8 paymentType) internal view {
        require(!_destoryed, "GenArtPaymentSplitterV2: contract is destroyed");
        Payment memory payment = paymentType == 0
            ? _payments[collection]
            : _paymentsRoyalties[collection];
        require(
            payment.payees.length > 0,
            "GenArtPaymentSplitterV2: payment not found for collection"
        );
    }

    function splitPayment(address collection)
        public
        payable
        override
        onlyCollectionContractOrAdmin(_payments[msg.sender].payees.length > 0)
    {
        uint256 totalShares = getTotalSharesOfCollection(collection, 0);
        for (uint8 i; i < _payments[collection].payees.length; i++) {
            address payee = _payments[collection].payees[i];
            uint256 ethAmount = (msg.value * _payments[collection].shares[i]) /
                totalShares;
            unchecked {
                _balances[payee] += ethAmount;
            }
            emit IncomingPayment(collection, 0, payee, ethAmount);
        }
    }

    function splitPaymentRoyalty(address collection)
        public
        payable
        override
        onlyCollectionContractOrAdmin(
            _paymentsRoyalties[msg.sender].payees.length > 0
        )
    {
        uint256 totalShares = getTotalSharesOfCollection(collection, 1);
        for (uint8 i; i < _paymentsRoyalties[collection].payees.length; i++) {
            address payee = _paymentsRoyalties[collection].payees[i];
            uint256 ethAmount = (msg.value *
                _paymentsRoyalties[collection].shares[i]) / totalShares;
            unchecked {
                _balances[payee] += ethAmount;
            }
            emit IncomingPayment(collection, 1, payee, ethAmount);
        }
    }

    function splitPaymentRoyaltyWETH(address collection, uint256 wethAmount)
        public
        payable
        override
        onlyCollectionContractOrAdmin(
            _paymentsRoyalties[msg.sender].payees.length > 0
        )
    {
        uint256 totalShares = getTotalSharesOfCollection(collection, 1);
        for (uint8 i; i < _paymentsRoyalties[collection].payees.length; i++) {
            address payee = _paymentsRoyalties[collection].payees[i];
            uint256 wethAmountShare = (wethAmount *
                _paymentsRoyalties[collection].shares[i]) / totalShares;
            unchecked {
                _wethBalances[payee] += wethAmountShare;
            }
            emit IncomingPayment(collection, 1, payee, wethAmountShare);
        }
    }

    /**
     *@dev Get total shares of collection
     * - `paymentType` pass "0" for _payments an "1" for _paymentsRoyalties
     */
    function getTotalSharesOfCollection(address collection, uint8 paymentType)
        public
        view
        override
        returns (uint256)
    {
        sanityCheck(collection, paymentType);
        Payment memory payment = paymentType == 0
            ? _payments[collection]
            : _paymentsRoyalties[collection];
        uint256 totalShares;
        for (uint8 i; i < payment.shares.length; i++) {
            unchecked {
                totalShares += payment.shares[i];
            }
        }

        return totalShares;
    }

    function release(address account) public override {
        require(!_destoryed, "GenArtPaymentSplitterV2: contract is destroyed");
        uint256 amount = _balances[account];
        uint256 wethAmount = _wethBalances[account];
        require(
            amount > 0 || wethAmount > 0,
            "GenArtPaymentSplitterV2: no funds to release"
        );
        if (amount > 0) {
            _balances[account] = 0;
            payable(account).transfer(amount);
        }
        if (wethAmount > 0) {
            _wethBalances[account] = 0;
            IERC20(_wethAddress).transfer(account, wethAmount);
        }
    }

    function updatePayee(
        address collection,
        uint8 paymentType,
        uint256 payeeIndex,
        address newPayee
    ) public override {
        sanityCheck(collection, paymentType);
        Payment storage payment = paymentType == 0
            ? _payments[collection]
            : _paymentsRoyalties[collection];
        address oldPayee = payment.payees[payeeIndex];
        require(
            oldPayee == _msgSender(),
            "GenArtPaymentSplitterV2: sender is not current payee"
        );
        payment.payees[payeeIndex] = newPayee;
    }

    function getBalanceForAccount(address account)
        public
        view
        returns (uint256)
    {
        require(!_destoryed, "GenArtPaymentSplitterV2: contract is destroyed");
        return _balances[account];
    }

    function emergencyWithdraw() public onlyOwner {
        _destoryed = true;
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {
        payable(owner()).transfer(msg.value);
    }
}