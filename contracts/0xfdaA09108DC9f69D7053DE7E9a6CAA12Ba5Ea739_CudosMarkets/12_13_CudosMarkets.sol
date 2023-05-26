// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./CudosAccessControls.sol";
import "hardhat/console.sol";

contract CudosMarkets is ReentrancyGuard {
    using SafeMath for uint256;

    struct Payment {
        uint32 paymentId;
        address payee;
        uint256 amount;
        PaymentStatus status;
        bytes cudosAddress;
    }

    enum PaymentStatus {
        Locked,
        Withdrawable,
        Returned,
        Withdrawn
    }

    CudosAccessControls public immutable cudosAccessControls;
    mapping(uint32 => Payment) public payments;
    mapping(address => uint32[]) public paymentIdsByAddress;
    
    address private relayerAddress;
    uint32 private nextPaymentId;

    event NftMinted(
        uint32 paymentId,
        uint256 amount,
        address indexed sender,
        bytes cudosAddress
    );
    event WithdrawalsUnlocked(uint32 paymentId);
    event PaymentsWithdrawn(address payee);
    event FinishedPaymentsWithdrawn(address withdrawer);
    event ChangedRelayerAddress(address relayerAddress);

    modifier onlyAdmin() {
        require(
            cudosAccessControls.hasAdminRole(msg.sender),
            "Recipient is not an admin!"
        );
        _;
    }

    modifier onlyRelayer() {
        require(
            msg.sender == relayerAddress,
            "Msg sender not the relayer."
        );
        _;
    }

    constructor(CudosAccessControls _cudosAccessControls) payable {
        require(
            address(_cudosAccessControls) != address(0) &&
                Address.isContract(address(_cudosAccessControls)),
            "Invalid CudosAccessControls address!"
        );
        cudosAccessControls = _cudosAccessControls;
        nextPaymentId = 1;
        relayerAddress = msg.sender;
    }

    function setRelayerAddress(address _relayerAddress)
        external
        nonReentrant
        onlyAdmin
    {
        require(_relayerAddress != address(0), "Invalid relayer address");

        relayerAddress = _relayerAddress;

        emit ChangedRelayerAddress(_relayerAddress);
    }

    function sendPayment(bytes memory cudosAddress)
        external
        payable
        nonReentrant
    {
        require(msg.value > 0, "Amount must be positive!");
        require(cudosAddress.length != 0, "CudosAddress cannot be empty!");

        Payment storage payment = payments[nextPaymentId];
        payment.paymentId = nextPaymentId;
        payment.payee = msg.sender;
        payment.amount = msg.value;
        payment.cudosAddress = cudosAddress;

        paymentIdsByAddress[msg.sender].push(nextPaymentId);
        nextPaymentId += 1;

        emit NftMinted(payment.paymentId, msg.value, msg.sender, cudosAddress);
    }

    function unlockPaymentWithdraw(uint32 paymentId)
        external
        onlyRelayer
        nonReentrant
    {
        require(payments[paymentId].amount > 0, "Non existing paymentId!");
        require(
            payments[paymentId].status == PaymentStatus.Locked,
            "Payment is not locked!"
        );
        payments[paymentId].status = PaymentStatus.Withdrawable;
        
        emit WithdrawalsUnlocked(paymentId);
    }

    function withdrawPayments() external nonReentrant {
        require(paymentIdsByAddress[msg.sender].length != 0,
            "no payments for that address"
        );

        uint32[] memory ids = paymentIdsByAddress[msg.sender];
        uint256 totalAmount;
        for (uint256 i = 0; i < ids.length; ++i) {
            Payment storage payment = payments[ids[i]];
            if (payment.status != PaymentStatus.Withdrawable) {
                continue;
            }

            totalAmount += payment.amount;
            payment.status = PaymentStatus.Returned;
        }

         require(totalAmount > 0,
            "Nothing to withdraw"
        );

        payable(msg.sender).transfer(totalAmount);

        emit PaymentsWithdrawn(msg.sender);
    }

    function withdrawFinishedPayments() external onlyAdmin nonReentrant {
        uint256 withdrawableBalance = 0;
        for (uint32 i = 1; i < nextPaymentId; ++i) {
            Payment storage payment = payments[i];
            if (payment.status == PaymentStatus.Locked) {
                withdrawableBalance += payment.amount;
                payment.status = PaymentStatus.Withdrawn;
            }
        }

        require(withdrawableBalance > 0,
            "Nothing to withdraw"
        );

        payable(msg.sender).transfer(withdrawableBalance);

        emit FinishedPaymentsWithdrawn(msg.sender);
    }

    function getPaymentStatus(uint32 paymentId)
        external
        view
        returns (PaymentStatus)
    {
        require(payments[paymentId].amount > 0, "Non existing paymentId!");

        return payments[paymentId].status;
    }

    function getPayments() external view returns (Payment[] memory) {
        uint32[] memory ids = paymentIdsByAddress[msg.sender];
        Payment[] memory paymentsFiltered = new Payment[](ids.length);

        for (uint256 i = 0; i < ids.length; ++i) {
            paymentsFiltered[i] = payments[ids[i]];
        }

        return paymentsFiltered;
    }
}