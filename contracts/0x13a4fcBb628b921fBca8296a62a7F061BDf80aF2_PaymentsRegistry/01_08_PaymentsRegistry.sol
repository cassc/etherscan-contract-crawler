// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract PaymentsRegistry is Ownable {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Payment {
        uint256 timestamp;
        address token;
        uint256 amount;
    }

    struct PaymentToken {
        address token;
        uint256 minDepositAmount;
        uint256 maxDepositAmount;
    }

    address public multisig;
    mapping(address => uint256) public totalPaymentAmount;
    mapping(address => uint256) public paymentTokenMinDepositAmount;
    mapping(address => uint256) public paymentTokenMaxDepositAmount;

    EnumerableSet.AddressSet private _paymentTokens;
    EnumerableSet.AddressSet private _paymentTokensWhitelist;
    mapping(address => mapping(address => uint256)) private _depositorTotalPaymentAmount;
    mapping(address => Payment[]) private _depositorPayments;

    function depositorTotalPaymentAmount(address depositor, address token) external view returns (uint256) {
        return _depositorTotalPaymentAmount[depositor][token];
    }

    function depositorPaymentsCount(address depositor) external view returns (uint256) {
        return _depositorPayments[depositor].length;
    }

    function depositorPayments(address depositor, uint256 index) external view returns (Payment memory) {
        return _depositorPayments[depositor][index];
    }

    function depositorPaymentsList(
        address depositor,
        uint256 offset,
        uint256 limit
    ) external view returns (Payment[] memory output) {
        Payment[] memory payments = _depositorPayments[depositor];
        uint256 paymentsLength = payments.length;
        if (offset >= paymentsLength) return output;
        uint256 to = offset + limit;
        if (paymentsLength < to) to = paymentsLength;
        output = new Payment[](to - offset);
        for (uint256 i = 0; i < output.length; i++) output[i] = payments[offset + i];
    }

    function paymentTokensCount() external view returns (uint256) {
        return _paymentTokens.length();
    }

    function paymentTokens(uint256 index) external view returns (address) {
        return _paymentTokens.at(index);
    }

    function paymentTokensContains(address token) external view returns (bool) {
        return _paymentTokens.contains(token);
    }

    function paymentTokensList(uint256 offset, uint256 limit) external view returns (address[] memory output) {
        uint256 tokensLength = _paymentTokens.length();
        if (offset >= tokensLength) return output;
        uint256 to = offset + limit;
        if (tokensLength < to) to = tokensLength;
        output = new address[](to - offset);
        for (uint256 i = 0; i < output.length; i++) output[i] = _paymentTokens.at(offset + i);
    }

    function paymentTokensWhitelistCount() external view returns (uint256) {
        return _paymentTokensWhitelist.length();
    }

    function paymentTokensWhitelist(uint256 index) external view returns (address) {
        return _paymentTokensWhitelist.at(index);
    }

    function paymentTokensWhitelistContains(address token) external view returns (bool) {
        return _paymentTokensWhitelist.contains(token);
    }

    function paymentTokensWhitelistList(uint256 offset, uint256 limit) external view returns (address[] memory output) {
        uint256 tokensWhitelistLength = _paymentTokensWhitelist.length();
        if (offset >= tokensWhitelistLength) return output;
        uint256 to = offset + limit;
        if (tokensWhitelistLength < to) to = tokensWhitelistLength;
        output = new address[](to - offset);
        for (uint256 i = 0; i < output.length; i++) output[i] = _paymentTokensWhitelist.at(offset + i);
    }

    event Deposited(address indexed depositor, address indexed multisig, address indexed token, uint256 amount);
    event MultisigUpdated(address multisig);
    event PaymentTokensWhitelistAdded(PaymentToken[] tokens);
    event PaymentTokensWhitelsitRemoved(address[] tokens);

    constructor (address multisig_, PaymentToken[] memory paymentTokens_) {
        _updateMultisig(multisig_);
        _addPaymentTokensWhitelist(paymentTokens_);
    }

    function deposit(address token, uint256 amount) external returns (bool) {
        require(_paymentTokensWhitelist.contains(token), "PaymentsRegistry: Token not whitelisted");
        require(amount >= paymentTokenMinDepositAmount[token], "PaymentsRegistry: Amount lt min");
        require(amount <= paymentTokenMaxDepositAmount[token], "PaymentsRegistry: Amount gt max");
        IERC20(token).safeTransferFrom(msg.sender, multisig, amount);
        _depositorPayments[msg.sender].push(Payment(block.timestamp, token, amount));
        _depositorTotalPaymentAmount[msg.sender][token] = _depositorTotalPaymentAmount[msg.sender][token] + amount;
        totalPaymentAmount[token] = totalPaymentAmount[token] + amount;
        emit Deposited(msg.sender, multisig, token, amount);
        return true;
    }

    function addPaymentTokensWhitelist(PaymentToken[] memory tokens_) external onlyOwner returns (bool) {
        _addPaymentTokensWhitelist(tokens_);
        return true;
    }

    function removePaymentTokensWhitelist(address[] memory tokens_) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < tokens_.length; i++) {
            address token = tokens_[i];
            _paymentTokensWhitelist.remove(token);
            delete paymentTokenMinDepositAmount[token];
        }
        emit PaymentTokensWhitelsitRemoved(tokens_);
        return true;
    }

    function updateMultisig(address multisig_) external onlyOwner returns (bool) {
        _updateMultisig(multisig_);
        return true;
    }

    function _updateMultisig(address multisig_) private {
        require(multisig_ != address(0), "PaymentsRegistry: Multisig is zero address");
        multisig = multisig_;
        emit MultisigUpdated(multisig_);
    }

    function _addPaymentTokensWhitelist(PaymentToken[] memory tokens_) private {
        for (uint256 i = 0; i < tokens_.length; i++) {
            PaymentToken memory tokenInfo = tokens_[i];
            require(tokenInfo.token != address(0), "PaymentsRegistry: Payment token is zero address");
            require(tokenInfo.maxDepositAmount >= tokenInfo.minDepositAmount, "PaymentsRegistry: Max lt min");
            _paymentTokensWhitelist.add(tokenInfo.token);
            _paymentTokens.add(tokenInfo.token);
            paymentTokenMinDepositAmount[tokenInfo.token] = tokenInfo.minDepositAmount;
            paymentTokenMinDepositAmount[tokenInfo.token] = tokenInfo.maxDepositAmount;
        }
        emit PaymentTokensWhitelistAdded(tokens_);
    }
}