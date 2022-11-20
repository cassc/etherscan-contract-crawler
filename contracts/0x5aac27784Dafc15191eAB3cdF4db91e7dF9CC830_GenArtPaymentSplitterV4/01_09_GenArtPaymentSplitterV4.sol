// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../access/GenArtAccessUpgradable.sol";
import "../interface/IGenArtPaymentSplitterV4.sol";

contract GenArtPaymentSplitterV4 is
    Initializable,
    GenArtAccessUpgradable,
    IGenArtPaymentSplitterV4
{
    struct Payment {
        address[] payees;
        uint256[] shares;
    }

    event IncomingPayment(uint256 paymentType, address payee, uint256 amount);

    mapping(address => uint256) public _ethBalances;
    Payment private _payment;
    Payment private _paymentRoyalties;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner,
        address[] memory payeesMint,
        address[] memory payeesRoyalties,
        uint256[] memory sharesMint,
        uint256[] memory sharesRoyalties
    ) public initializer {
        __GenArtAccessUpgradable_init(owner, owner);
        _payment = Payment(payeesMint, sharesMint);
        _paymentRoyalties = Payment(payeesRoyalties, sharesRoyalties);
    }

    function splitPayment() external payable override {
        uint256 value = msg.value;
        require(value > 0, "nothing to receive");
        uint256 totalShares = getTotalShares(0);
        for (uint8 i; i < _payment.payees.length; i++) {
            address payee = _payment.payees[i];
            uint256 ethAmount = (value * _payment.shares[i]) / totalShares;
            unchecked {
                _ethBalances[payee] += ethAmount;
            }
            emit IncomingPayment(0, payee, ethAmount);
        }
    }

    function splitPaymentRoyalty() internal {
        uint256 totalShares = getTotalShares(1);
        for (uint8 i; i < _paymentRoyalties.payees.length; i++) {
            address payee = _paymentRoyalties.payees[i];
            uint256 ethAmount = (msg.value * _paymentRoyalties.shares[i]) /
                totalShares;
            unchecked {
                _ethBalances[payee] += ethAmount;
            }
            emit IncomingPayment(1, payee, ethAmount);
        }
    }

    /**
     *@dev Get total shares of collection
     * - `paymentType` pass "0" for _payments an "1" for _paymentRoyalties
     */
    function getTotalShares(uint8 paymentType)
        public
        view
        override
        returns (uint256)
    {
        Payment memory payment = paymentType == 0
            ? _payment
            : _paymentRoyalties;
        uint256 totalShares;
        for (uint8 i; i < payment.shares.length; i++) {
            unchecked {
                totalShares += payment.shares[i];
            }
        }

        return totalShares;
    }

    function release(address account) external override {
        uint256 amount = _ethBalances[account];
        require(amount > 0, "no funds to release");
        _ethBalances[account] = 0;
        payable(account).transfer(amount);
    }

    function releaseTokens(address token) external {
        uint256 totalShares = getTotalShares(1);
        uint256 totalBalance = IERC20(token).balanceOf(address(this));
        require(totalBalance > 0, "no funds to release");

        for (uint8 i; i < _paymentRoyalties.payees.length; i++) {
            address payee = _paymentRoyalties.payees[i];
            uint256 amount = (totalBalance * _paymentRoyalties.shares[i]) /
                totalShares;
            IERC20(token).transfer(payee, amount);
            emit IncomingPayment(1, payee, amount);
        }
    }

    function updatePayee(
        uint8 paymentType,
        uint256 payeeIndex,
        address newPayee
    ) external override {
        Payment storage payment = paymentType == 0
            ? _payment
            : _paymentRoyalties;
        address oldPayee = payment.payees[payeeIndex];
        require(oldPayee == _msgSender(), "sender is not current payee");
        payment.payees[payeeIndex] = newPayee;
    }

    receive() external payable {
        splitPaymentRoyalty();
    }
}