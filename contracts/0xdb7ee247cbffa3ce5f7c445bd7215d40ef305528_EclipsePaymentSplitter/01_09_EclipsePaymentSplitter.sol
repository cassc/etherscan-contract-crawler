// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {EclipseAccessUpgradable} from "../access/EclipseAccessUpgradable.sol";
import {IEclipsePaymentSplitter} from "../interface/IEclipsePaymentSplitter.sol";

contract EclipsePaymentSplitter is
    Initializable,
    EclipseAccessUpgradable,
    IEclipsePaymentSplitter
{
    struct Payment {
        address[] payees;
        uint24[] shares;
    }

    uint16 public DOMINATOR;
    uint16 public platformShare;
    uint16 public platformShareRoyalties;
    address public _platformPayout;

    mapping(address => uint256) public _ethBalances;
    Payment private _payment;
    Payment private _paymentRoyalties;

    event IncomingPayment(uint8 paymentType, address payee, uint256 amount);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address owner,
        address platformPayout,
        address[] memory payeesMint,
        address[] memory payeesRoyalties,
        uint24[] memory sharesMint,
        uint24[] memory sharesRoyalties
    ) public initializer {
        __EclipseAccessUpgradable_init(owner, owner, owner);
        DOMINATOR = 10_000;
        _checkShares(payeesMint, payeesRoyalties, sharesMint, sharesRoyalties);
        _platformPayout = platformPayout;
        platformShare = 750;
        platformShareRoyalties = 200;
        _payment = Payment(payeesMint, sharesMint);
        _paymentRoyalties = Payment(payeesRoyalties, sharesRoyalties);
    }

    function splitPayment() external payable override {
        require(msg.value > 0, "nothing to receive");
        uint256 value = (msg.value * platformShare) / DOMINATOR;
        unchecked {
            _ethBalances[_platformPayout] += value;
        }
        emit IncomingPayment(0, _platformPayout, value);
        _splitPaymentArtist(msg.value - value);
    }

    function _splitPaymentArtist(uint256 value) internal {
        uint256 totalShares = getTotalShares();
        for (uint8 i; i < _payment.payees.length; i++) {
            address payee = _payment.payees[i];
            uint256 ethAmount = (value * _payment.shares[i]) / totalShares;
            unchecked {
                _ethBalances[payee] += ethAmount;
            }
            emit IncomingPayment(0, payee, ethAmount);
        }
    }

    function _splitPaymentRoyalty() internal {
        require(msg.value > 0, "nothing to receive");
        uint256 totalShares = getTotalRoyaltyShares();

        uint256 value = (msg.value * platformShareRoyalties) / totalShares;
        unchecked {
            _ethBalances[_platformPayout] += value;
        }
        emit IncomingPayment(1, _platformPayout, value);
        _splitPaymentRoyaltyArtist(msg.value, totalShares);
    }

    function _splitPaymentRoyaltyArtist(
        uint256 value,
        uint256 totalShares
    ) internal {
        for (uint8 i; i < _paymentRoyalties.payees.length; i++) {
            address payee = _paymentRoyalties.payees[i];
            uint256 ethAmount = (value * _paymentRoyalties.shares[i]) /
                totalShares;
            unchecked {
                _ethBalances[payee] += ethAmount;
            }
            emit IncomingPayment(1, payee, ethAmount);
        }
    }

    /**
     *@dev Get total shares of collection
     */
    function getTotalShares() public view override returns (uint256) {
        uint256 totalShares;
        for (uint8 i; i < _payment.shares.length; i++) {
            unchecked {
                totalShares += _payment.shares[i];
            }
        }

        return totalShares;
    }

    /**
     *@dev Get total royalty shares of collection
     */
    function getTotalRoyaltyShares() public view override returns (uint256) {
        uint256 totalShares;
        for (uint8 i; i < _paymentRoyalties.shares.length; i++) {
            unchecked {
                totalShares += _paymentRoyalties.shares[i];
            }
        }

        return totalShares + platformShareRoyalties;
    }

    function release(address account) external override {
        uint256 amount = _ethBalances[account];
        require(amount > 0, "no funds to release");
        _ethBalances[account] = 0;
        payable(account).transfer(amount);
    }

    function releaseTokens(address token) external {
        uint256 totalShares = getTotalRoyaltyShares();
        uint256 totalBalance = IERC20(token).balanceOf(address(this));
        require(totalBalance > 0, "no funds to release");
        uint256 platformAmount = (totalBalance * platformShareRoyalties) /
            totalShares;
        IERC20(token).transfer(_platformPayout, platformAmount);
        emit IncomingPayment(1, _platformPayout, platformAmount);

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
        uint8 payeeIndex,
        address newPayee
    ) external override {
        Payment storage payment = paymentType == 0
            ? _payment
            : _paymentRoyalties;
        address oldPayee = payment.payees[payeeIndex];
        require(oldPayee == _msgSender(), "sender is not current payee");
        payment.payees[payeeIndex] = newPayee;
    }

    function _checkShares(
        address[] memory payeesMint,
        address[] memory payeesRoyalties,
        uint24[] memory sharesMint,
        uint24[] memory sharesRoyalties
    ) internal view {
        uint8 mintSharesCount = uint8(sharesMint.length);
        require(
            payeesMint.length == mintSharesCount &&
                payeesRoyalties.length == sharesRoyalties.length,
            "shares and payees must have same amount of entries"
        );
        uint24 sumShares;
        for (uint24 i = 0; i < mintSharesCount; i++) {
            sumShares += sharesMint[i];
        }
        require(sumShares == DOMINATOR, "sum of shares must equal DOMINATOR");
    }

    function getShares() public view returns (Payment memory) {
        return _payment;
    }

    receive() external payable {
        _splitPaymentRoyalty();
    }
}