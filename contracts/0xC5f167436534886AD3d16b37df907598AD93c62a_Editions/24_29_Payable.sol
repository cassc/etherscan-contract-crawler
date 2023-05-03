// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████▓▀██████████████████████████████████████████████
// ██████████████████████████████████  ╙███████████████████████████████████████████
// ███████████████████████████████████    ╙████████████████████████████████████████
// ████████████████████████████████████      ╙▀████████████████████████████████████
// ████████████████████████████████████▌        ╙▀█████████████████████████████████
// ████████████████████████████████████▌           ╙███████████████████████████████
// ████████████████████████████████████▌            ███████████████████████████████
// ████████████████████████████████████▌         ▄█████████████████████████████████
// ████████████████████████████████████       ▄████████████████████████████████████
// ███████████████████████████████████▀   ,▄███████████████████████████████████████
// ██████████████████████████████████▀ ,▄██████████████████████████████████████████
// █████████████████████████████████▄▓█████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████
// ████████████████████████████████████████████████████████████████████████████████

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import "forge-std/console.sol";

import {AuthGuard} from "../core/AuthGuard.sol";

contract Payable is ReentrancyGuard, AuthGuard {
    using SafeERC20 for IERC20;

    constructor(address _registry) AuthGuard(_registry) {}

    event PaymentReceived(
        address buyer,
        address indexed seller,
        address indexed token,
        address plugin,
        uint256 unitPrice,
        uint256 quantity,
        uint256 protocolFee,
        uint64 indexed id
    );

    event ReferralPaymentReceived(
        address buyer,
        address indexed seller,
        address indexed curator,
        address token,
        address plugin,
        uint256 unitPrice,
        uint256 quantity,
        uint256 protocolFee,
        uint256 referralAmount,
        uint64 indexed id
    );

    event Withdrawn(
        address indexed token,
        address indexed recipient,
        uint256 amount
    );

    mapping(address => uint256) public nativeBalances;
    mapping(address => mapping(address => uint256)) public erc20Balances;

    /**
     * @notice Withdraw native _token s to the specified _recipient
     * @param _recipient  The address of the _recipient
     * @param _amount The amount to be withdrawn
     */
    function withdrawNative(
        address payable _recipient,
        uint256 _amount
    ) external nonReentrant {
        require(
            nativeBalances[_recipient] >= _amount,
            "Insufficient native token  balance"
        );
        nativeBalances[_recipient] -= _amount;
        (bool success, ) = _recipient.call{value: _amount}("");
        require(success, "Transfer failed.");
        emit Withdrawn(address(0), _recipient, _amount);
    }

    /**
     * @notice Withdraw ERC20 tokens to the specified recipient
     * @param _token The address of the ERC20 token
     * @param _recipient The address of the recipient
     * @param _amount The amount to be withdrawn
     */
    function withdrawERC20(
        address _token,
        address _recipient,
        uint256 _amount
    ) external nonReentrant {
        require(
            erc20Balances[_recipient][_token] >= _amount,
            "Insufficient token  balance"
        );
        erc20Balances[_recipient][_token] -= _amount;
        IERC20(_token).safeTransfer(_recipient, _amount);
        emit Withdrawn(_token, _recipient, _amount);
    }

    /**
     * @notice Withdraw native tokens as an admin to the specified recipient
     * @param _recipient The address of the recipient
     * @param _amount The amount to be withdrawn
     */
    function adminWithdrawNative(
        address payable _recipient,
        uint256 _amount
    ) external onlyAdmin nonReentrant {
        require(
            nativeBalances[address(0)] >= _amount,
            "Insufficient native token balance"
        );
        nativeBalances[address(0)] -= _amount;
        _recipient.transfer(_amount);
        emit Withdrawn(address(0), _recipient, _amount);
    }

    /**
     * @notice Withdraw ERC20 tokens as an admin to the specified recipient
     * @param _token The address of the ERC20 token
     * @param _recipient The address of the recipient
     * @param _amount The amount to be withdrawn
     */
    function adminWithdrawERC20(
        address _token,
        address _recipient,
        uint256 _amount
    ) external onlyAdmin nonReentrant {
        require(
            erc20Balances[address(0)][_token] >= _amount,
            "Insufficient token balance"
        );
        erc20Balances[address(0)][_token] -= _amount;
        IERC20(_token).safeTransfer(_recipient, _amount);
        emit Withdrawn(_token, _recipient, _amount);
    }

    /**
     * @notice Internal function to process native token payments
     * @param _buyer The address of the buyer
     * @param _seller The address of the seller
     * @param _unitPrice The unit price of the product
     * @param _quantity The quantity of the product purchased
     * @param _id The product ID
     */
    function _receiveNative(
        address _buyer,
        address _seller,
        uint256 _unitPrice,
        uint256 _quantity,
        uint64 _id
    ) internal {
        console.logUint(_unitPrice);
        console.logUint(_quantity);
        uint256 baseValue = _unitPrice * _quantity;
        uint256 protocolFee = calculateFee(_unitPrice, _quantity, address(0));
        uint256 totalValue = baseValue + protocolFee;

        console.logUint(msg.value);
        console.logUint(totalValue);
        require(msg.value >= totalValue, "Insufficient payment");

        nativeBalances[_seller] += baseValue;
        nativeBalances[address(0)] += protocolFee;

        emit PaymentReceived(
            _buyer,
            _seller,
            address(0),
            address(this),
            _unitPrice,
            _quantity,
            protocolFee,
            _id
        );
    }

    /**
     * @notice Internal function to process ERC20 token payments
     * @param _buyer The address of the buyer
     * @param _seller The address of the seller
     * @param _token The address of the ERC20 token
     * @param _unitPrice The unit price of the product
     * @param _quantity The quantity of the product purchased
     * @param _id The product ID
     */
    function _receiveERC20(
        address _buyer,
        address _seller,
        address _token,
        uint256 _unitPrice,
        uint256 _quantity,
        uint64 _id
    ) internal {
        uint256 baseValue = _unitPrice * _quantity;
        uint256 protocolFee = calculateFee(_unitPrice, _quantity, _token);
        uint256 totalValue = baseValue + protocolFee;

        IERC20(_token).safeTransferFrom(_buyer, address(this), totalValue);

        erc20Balances[_seller][_token] += baseValue;
        erc20Balances[address(0)][_token] += protocolFee;

        emit PaymentReceived(
            _buyer,
            _seller,
            _token,
            address(this),
            _unitPrice,
            _quantity,
            protocolFee,
            _id
        );
    }

    function _receiveNativeReferral(
        address _buyer,
        address _seller,
        address _curator,
        uint256 _unitPrice,
        uint256 _quantity,
        uint64 _id,
        uint256 _referralPercentage
    ) internal {
        uint256 baseValue = _unitPrice * _quantity;
        uint256 protocolFee = calculateFee(_unitPrice, _quantity, address(0));
        uint256 referralAmount = (baseValue * _referralPercentage) / 10000;
        uint256 totalValue = baseValue + protocolFee;

        require(msg.value >= totalValue, "Insufficient payment");

        nativeBalances[_seller] += (baseValue - referralAmount);
        nativeBalances[_curator] += referralAmount;
        nativeBalances[address(0)] += protocolFee;

        emit ReferralPaymentReceived(
            _buyer,
            _seller,
            _curator,
            address(0),
            address(this),
            _unitPrice,
            _quantity,
            protocolFee,
            referralAmount,
            _id
        );
    }

    function _receiveERC20Referral(
        address _buyer,
        address _seller,
        address _curator,
        address _token,
        uint256 _unitPrice,
        uint256 _quantity,
        uint64 _id,
        uint256 _referralPercentage
    ) internal {
        uint256 baseValue = _unitPrice * _quantity;
        uint256 protocolFee = calculateFee(_unitPrice, _quantity, _token);
        uint256 referralAmount = (baseValue * _referralPercentage) / 10000;
        uint256 totalValue = baseValue + protocolFee;

        IERC20(_token).safeTransferFrom(_buyer, address(this), totalValue);

        erc20Balances[_seller][_token] += (baseValue - referralAmount);
        erc20Balances[_curator][_token] += referralAmount;
        erc20Balances[address(0)][_token] += protocolFee;

        emit ReferralPaymentReceived(
            _buyer,
            _seller,
            _curator,
            _token,
            address(this),
            _unitPrice,
            _quantity,
            protocolFee,
            referralAmount,
            _id
        );
    }

    /**
     * @notice Calculate the fee for a given transaction
     * @param _price The unit price of the product
     * @param _quantity The quantity of the product purchased
     * @param _token The address of the token (native or ERC20)
     * @return The calculated fee
     */
    function calculateFee(
        uint256 _price,
        uint256 _quantity,
        address _token
    ) public view virtual returns (uint256) {
        // OVERRIDE THIS TO CHANGE PROTOCOL FEE STRUCTURE FOR A PLUGIN
        return 0;
    }

    /**
     * @notice Calculate the total value of a transaction, including fees
     * @param _unitPrice The unit price of the product
     * @param _quantity The
     * @param _token The address of the token (native or ERC20)
     * @return The total value required including fee
     */
    function calculateTotalValue(
        uint256 _unitPrice,
        uint256 _quantity,
        address _token
    ) public view returns (uint256) {
        uint256 baseValue = _unitPrice * _quantity;
        uint256 fee = calculateFee(_unitPrice, _quantity, _token);
        return baseValue + fee;
    }
}