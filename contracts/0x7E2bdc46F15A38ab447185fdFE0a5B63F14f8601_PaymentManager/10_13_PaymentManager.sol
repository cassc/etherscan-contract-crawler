//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./utils/CallHelpers.sol";
import "./utils/EIP712.sol";
import "../interfaces/IAccessManager.sol";

contract PaymentManager is EIP712 {
    using SafeERC20 for ERC20;
    address public withdrawalAddress;

    bytes32 private immutable PAY_ETH_TYPEHASH = keccak256("PayEth(uint32 paymentId,address payer,uint256 value)");
    bytes32 private immutable PAY_STABLECOIN_TYPEHASH =
        keccak256("PayStablecoin(uint32 paymentId,address payer,uint256 value,address stablecoinAddress)");

    mapping(uint32 => bool) private paymentIdUsed;

    IAccessManager private accessManager;

    event PaidEth(address sender, uint256 amount, uint32 paymentId);
    event PaidStablecoin(address sender, uint256 amount, uint32 paymentId, address stablecoinAddress);

    constructor(address _accessManagerAddress, address _withdrawalAddress) EIP712("Payment", "1") {
        accessManager = IAccessManager(_accessManagerAddress);
        withdrawalAddress = _withdrawalAddress;
    }

    modifier isOperationalAddress() {
        require(accessManager.isOperationalAddress(msg.sender) == true, "You are not allowed to use this function");
        _;
    }

    modifier isPaymentIdUsed(uint32 _paymentId) {
        require(paymentIdUsed[_paymentId] == false, "This paymentId was used");
        _;
    }

    function setWithdrawalAddress(address _newWithdrawalAddress) external isOperationalAddress {
        withdrawalAddress = _newWithdrawalAddress;
    }

    function payInEth(uint32 _paymentId, bytes memory _signature) public payable isPaymentIdUsed(_paymentId) {
        bytes32 _hash = _hashTypedDataV4(keccak256(abi.encode(PAY_ETH_TYPEHASH, _paymentId, msg.sender, msg.value)));
        address recoverAddress = ECDSA.recover(_hash, _signature);

        require(accessManager.isOperationalAddress(recoverAddress) == true, "Incorrect pay signature");

        (bool success, bytes memory response) = withdrawalAddress.call{value: msg.value, gas: 5000}("");
        if (!success) {
            string memory message = CallHelpers.getRevertMsg(response);
            revert(message);
        }
        paymentIdUsed[_paymentId] = true;

        emit PaidEth(msg.sender, msg.value, _paymentId);
    }

    function payInStablecoin(
        uint32 _paymentId,
        address _stablecoinAddress,
        uint256 _value,
        bytes memory _signature
    ) public isPaymentIdUsed(_paymentId) {
        bytes32 _hash = _hashTypedDataV4(
            keccak256(abi.encode(PAY_STABLECOIN_TYPEHASH, _paymentId, msg.sender, _value, _stablecoinAddress))
        );

        address recoverAddress = ECDSA.recover(_hash, _signature);

        require(accessManager.isOperationalAddress(recoverAddress) == true, "Incorrect pay signature");

        ERC20 stablecoin = ERC20(_stablecoinAddress);

        stablecoin.safeTransferFrom(msg.sender, withdrawalAddress, _value);

        paymentIdUsed[_paymentId] = true;

        emit PaidStablecoin(msg.sender, _value, _paymentId, _stablecoinAddress);
    }
}