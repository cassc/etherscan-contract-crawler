// SPDX-License-Identifier: UNLICENSED
// Copyright (c) Eywa.Fi, 2021-2023 - all rights reserved
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../utils/Typecast.sol";
import "../utils/RequestIdLib.sol";
import "../interfaces/IBridgeV2.sol";
import "../interfaces/IValidatedDataReciever.sol";


contract GateKeeper is AccessControlEnumerable, Typecast, ReentrancyGuard {
    using Address for address;

    struct BaseFee {
        /// @dev chainId The ID of the chain for which the base fee is being set
        uint64 chainId;
        /// @dev payToken The token for which the base fee is being set; use 0x0 to set base fee in a native asset
        address payToken;
        /// @dev fee The amount of the base fee being set
        uint256 fee;
    }

    struct Rate {
        /// @dev chainId The ID of the chain for which the base fee is being set
        uint64 chainId;
        /// @dev payToken The token for which the base fee is being set; use 0x0 to set base fee in a native asset
        address payToken;
        /// @dev rate The rate being set
        uint256 rate;
    }

    /// @dev operator role id
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /// @dev bridge conract, can be changed any time
    address public bridge;
    /// @dev chainId => pay token => base fees
    mapping(uint64 => mapping(address => uint256)) public baseFees;
    /// @dev chainId => pay token => rate (per byte)
    mapping(uint64 => mapping(address => uint256)) public rates;
    /// @dev caller => discounts, [0, 10000]
    mapping(address => uint256) public discounts;

    event CrossChainCallPaid(address indexed sender, address indexed token, uint256 transactionCost);
    event BridgeSet(address bridge);
    event BaseFeeSet(uint64 chainId, address payToken, uint256 fee);
    event RateSet(uint64 chainId, address payToken, uint256 rate);
    event DiscountSet(address caller, uint256 discount);
    event FeesWithdrawn(address token, uint256 amount, address to);

    /**
     * @dev Constructor function for GateKeeper contract.
     *
     * @param bridge_ The address of the BridgeV2 contract.
     */
    constructor(address bridge_) {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        require(bridge_ != address(0), "GateKeeper: zero address");
        bridge = bridge_;
    }

    /**
     * @dev Returns same nonce as bridge (on request from same sender).
     */
    function getNonce() external view returns (uint256 nonce) {
        nonce = IBridgeV2(bridge).nonces(msg.sender);
    }

    /**
     * @notice Sets the address of the BridgeV2 contract.
     *
     * @dev Only the contract owner is allowed to call this function.
     *
     * @param bridge_ the address of the new BridgeV2 contract to be set.
     */
    function setBridge(address bridge_) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(bridge_ != address(0), "GateKeeper: zero address");
        bridge = bridge_;
        emit BridgeSet(bridge);
    }

    /**
     * @notice Sets the base fee for a given chain ID and token address.
     * The base fee represents the minimum amount of pay {TOKEN} required as transaction fee.
     * Use 0x0 as payToken address to set base fee in native asset.
     *
     * @param baseFees_ The array of the BaseFee structs.
     */
    function setBaseFee(BaseFee[] memory baseFees_) external onlyRole(OPERATOR_ROLE) {
        for (uint256 i = 0; i < baseFees_.length; ++i) {
            BaseFee memory baseFee = baseFees_[i];
            baseFees[baseFee.chainId][baseFee.payToken] = baseFee.fee;
            emit BaseFeeSet(baseFee.chainId, baseFee.payToken, baseFee.fee);
        }
    }

    /**
     * @notice Sets the rate for a given chain ID and token address.
     * The rate will be applied based on the length of the data being transmitted between the chains.
     *
     * @param rates_ The array of the Rate structs.
     */
    function setRate(Rate[] memory rates_) external onlyRole(OPERATOR_ROLE) {
        for (uint256 i = 0; i < rates_.length; ++i) {
            Rate memory rate = rates_[i];
            rates[rate.chainId][rate.payToken] = rate.rate;
            emit RateSet(rate.chainId, rate.payToken, rate.rate);
        }
    }

    /**
     * @notice Sets the discount for a given caller. Have to be in [0, 10000], where 10000 is 100%.
     *
     * @param caller The address of the caller for which the discount is being set;
     * @param discount The discount being set.
     */
    function setDiscount(address caller, uint256 discount) external onlyRole(OPERATOR_ROLE) {
        require(discount <= 10000, "GateKeeper: wrong discount");
        discounts[caller] = discount;
        emit DiscountSet(caller, discount);
    }

    /**
     * @notice Calculates the cost for a cross-chain operation in the specified token.
     *
     * @param payToken The address of the token to be used for fee payment. Use address(0) to pay with Ether;
     * @param dataLength The length of the data being transmitted in the cross-chain operation;
     * @param chainIdTo The ID of the destination chain;
     * @param sender The address of the caller requesting the cross-chain operation;
     * @return amountToPay The fee amount to be paid for the cross-chain operation.
     */
    function calculateCost(
        address payToken,
        uint256 dataLength,
        uint64 chainIdTo,
        address sender
    ) public view returns (uint256 amountToPay) {
        uint256 baseFee = baseFees[chainIdTo][payToken];
        uint256 rate = rates[chainIdTo][payToken];
        require(baseFee != 0, "GateKeeper: base fee not set");
        require(rate != 0, "GateKeeper: rate not set");
        (amountToPay) = _getPercentValues(baseFee + (dataLength * rate), discounts[sender]);
    }

    /**
     * @notice Calculates the final amount to be paid after applying a discount percentage to the original amount.
     *
     * @param amount The original amount to be paid;
     * @param basePercent The percentage of discount to be applied;
     * @return amountToPay The final amount to be paid after the discount has been applied.
     */
    function _getPercentValues(
        uint256 amount,
        uint256 basePercent
    ) private pure returns (uint256 amountToPay) {
        require(amount >= 10, "GateKeeper: amount is too small");
        uint256 discount = (amount * basePercent) / 10000;
        amountToPay = amount - discount;
    }

    /**
     * @notice Allows the owner to withdraw collected fees from the contract. Use address(0) to
     * withdraw native asset.
     *
     * @param token The token address from which the fees need to be withdrawn;
     * @param amount The amount of fees to be withdrawn;
     * @param to The address where the fees will be transferred.
     */
    function withdrawFees(address token, uint256 amount, address to) external onlyRole(OPERATOR_ROLE) nonReentrant {
        if (token == address(0)) {
            (bool sent,) = to.call{value: amount}("");
            require(sent, "GateKeeper: failed to send Ether");
        } else {
            SafeERC20.safeTransfer(IERC20(token), to, amount);
        }
        emit FeesWithdrawn(token, amount, to);
    }

    /**
     * @dev Sends data to a destination contract on a specified chain using the opposite BridgeV2 contract.
     * If payToken is address(0), the payment is made in Ether, otherwise it is made using the ERC20 token 
     * at the specified address.
     * The payment amount is calculated based on the data length and the specified chain ID and discount rate of the sender.
     *
     * Emits a PaymentReceived event after the payment has been processed.
     *
     * @param data The data (encoded with selector) which would be send to the destination contract;
     * @param to The address of the destination contract;
     * @param chainIdTo The ID of the chain where the destination contract resides;
     * @param payToken The address of the ERC20 token used to pay the fee or address(0) if Ether is used.
     */
    function sendData(
        bytes calldata data,
        address to,
        uint64 chainIdTo,
        address payToken
    ) external payable nonReentrant {
        uint256 amountToPay = calculateCost(payToken, data.length, chainIdTo, msg.sender);
        _proceedCrosschainFees(payToken, amountToPay);

        uint256 nonce = IBridgeV2(bridge).nonces(msg.sender);
        bytes32 requestId = RequestIdLib.prepareRequestId(
            castToBytes32(to),
            chainIdTo,
            castToBytes32(msg.sender),
            block.chainid,
            nonce
        );

        bytes memory info = abi.encodeWithSelector(
            IValidatedDataReciever.receiveValidatedData.selector,
            bytes4(data[:4]),
            msg.sender,
            block.chainid
        );

        bytes memory out = abi.encode(data, info);

        IBridgeV2(bridge).sendV2(
            IBridgeV2.SendParams({
                requestId: requestId,
                data: out,
                to: to,
                chainIdTo: chainIdTo
            }),
            msg.sender,
            nonce
        );
    }

    /**
     * @notice Proceeds with cross-chain fees payment in the specified token.
     *
     * @param payToken The address of the token to be used for fee payment.
     * @param transactionCost The amount of fees to be paid for the cross-chain operation.
     */
    function _proceedCrosschainFees(address payToken, uint256 transactionCost) private {
        emit CrossChainCallPaid(msg.sender, payToken, transactionCost);
        if (payToken == address(0)) {
            require(msg.value >= transactionCost, "GateKeeper: invalid payment amount");
        } else {
            SafeERC20.safeTransferFrom(IERC20(payToken), msg.sender, address(this), transactionCost);
        }
    }
}