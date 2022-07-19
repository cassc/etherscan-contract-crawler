// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

error InvalidAddress();
error ClosingTimeMustBeGreaterThanOpeningTime();
error AcceptedTokensLimitExceeded();
error ICOClosed();
error NotAcceptedPaymentToken();
error CapExceeded();
error InvalidPaymentTokenDecimals();
error InvalidSignature();

/**
 * @title ICO
 */
contract ICO is Ownable, EIP712 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint8 private constant _ACCEPTED_PAYMENT_TOKENS_LIMIT = 5;
    uint8 private constant _PAYMENT_TOKENS_DECIMALS = 6;
    uint8 private constant _TOKEN_DECIMALS = 18;
    bytes32 private constant _WHITELIST_TYPEHASH = keccak256("Whitelist(address user)");

    uint256 public cap;
    uint256 public openingTime;
    uint256 public closingTime;
    uint256 public tokenPrice;
    address public wallet;
    address public authorizer;
    address[] private _acceptedPaymentTokens;

    struct TokenDeposit {
        mapping(address => uint256) perToken;
        uint256 total;
    }

    mapping(address => TokenDeposit) private _contributions;
    TokenDeposit private _totalContribution;

    mapping(address => uint256) public purchasedTokens;
    uint256 public totalPurchasedTokens;

    event BuyWithPermission(address indexed paymentToken, uint256 paidAmount, uint256 purchasedAmount);

    constructor(
        address walletAddress,
        address authorizerAddress,
        uint256 capValue,
        uint256 openingTimeValue,
        uint256 closingTimeValue,
        uint256 tokenPriceValue,
        address[] memory acceptedPaymentTokensValue
    ) EIP712("ICO", "1") {
        if (!_addressIsValid(walletAddress))
            revert InvalidAddress();
        if (!_addressIsValid(authorizerAddress))
            revert InvalidAddress();
        if (openingTimeValue > closingTimeValue)
            revert ClosingTimeMustBeGreaterThanOpeningTime();
        if (_acceptedPaymentTokens.length > _ACCEPTED_PAYMENT_TOKENS_LIMIT)
            revert AcceptedTokensLimitExceeded();

        for (uint i = 0; i < acceptedPaymentTokensValue.length; i++) {
            if (!_addressIsValid(acceptedPaymentTokensValue[i]))
                revert InvalidAddress();
            if (ERC20(acceptedPaymentTokensValue[i]).decimals() != _PAYMENT_TOKENS_DECIMALS)
                revert InvalidPaymentTokenDecimals();
        }

        wallet = walletAddress;
        authorizer = authorizerAddress;
        cap = capValue;
        openingTime = openingTimeValue;
        closingTime = closingTimeValue;
        tokenPrice = tokenPriceValue;
        _acceptedPaymentTokens = acceptedPaymentTokensValue;
    }

    function buyWithPermission(
        address paymentToken,
        uint256 amount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (!isAcceptedPaymentToken(paymentToken))
            revert NotAcceptedPaymentToken();
        if (!isOpen())
            revert ICOClosed();

        uint256 amountToBuy = amount.mul(10 ** _TOKEN_DECIMALS).div(tokenPrice);

        if (totalPurchasedTokens + amountToBuy > cap)
            revert CapExceeded();

        // Check signature - the address has to be whitelisted by authorizer
        bytes32 structHash = keccak256(abi.encode(_WHITELIST_TYPEHASH, _msgSender()));
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != authorizer)
            revert InvalidSignature();

        // Transfer sent tokens to wallet
        IERC20(paymentToken).safeTransferFrom(_msgSender(), wallet, amount);

        // Increase account contribution
        _contributions[_msgSender()].total += amount;

        // Increase account contribution per token
        _contributions[_msgSender()].perToken[paymentToken] += amount;

        // Increase total contribution
        _totalContribution.total += amount;

        // Increase total contribution per token
        _totalContribution.perToken[paymentToken] += amount;

        totalPurchasedTokens += amountToBuy;
        purchasedTokens[_msgSender()] += amountToBuy;

        emit BuyWithPermission(paymentToken, amount, amountToBuy);
    }

    function setCap(uint256 capValue) external onlyOwner {
        cap = capValue;
    }

    function setOpeningTime(uint256 time) external onlyOwner {
        openingTime = time;
    }

    function setClosingTime(uint256 time) external onlyOwner {
        closingTime = time;
    }

    function setTokenPrice(uint256 price) external onlyOwner {
        tokenPrice = price;
    }

    function setWallet(address walletAddress) external onlyOwner {
        wallet = walletAddress;
    }

    function setAuthorizer(address authorizerAddress) external onlyOwner {
        authorizer = authorizerAddress;
    }

    function setAcceptedPaymentTokens(address[] memory tokens) external onlyOwner {
        if (tokens.length > _ACCEPTED_PAYMENT_TOKENS_LIMIT) revert AcceptedTokensLimitExceeded();
        _acceptedPaymentTokens = tokens;
    }

    function isOpen() public view returns (bool) {
        return !(block.timestamp < openingTime || block.timestamp > closingTime);
    }

    function isAcceptedPaymentToken(address token) public view returns (bool) {
        for (uint i = 0; i < _acceptedPaymentTokens.length; i++) {
            if (_acceptedPaymentTokens[i] == token)
                return true;
        }
        return false;
    }

    function acceptedPaymentTokens() public view returns (address[] memory) {
        return _acceptedPaymentTokens;
    }

    function totalContribution() public view returns (uint256, address[] memory, uint256[] memory) {
        address[] memory tokens = new address[](_acceptedPaymentTokens.length);
        uint256[] memory amounts = new uint256[](_acceptedPaymentTokens.length);

        for (uint i = 0; i < _acceptedPaymentTokens.length; i++) {
            address token = _acceptedPaymentTokens[i];
            uint256 depositAmount = _totalContribution.perToken[token];
            tokens[i] = token;
            amounts[i] = depositAmount;
        }

        return (_totalContribution.total, tokens, amounts);
    }

    function contribution(address account) public view returns (uint256, address[] memory, uint256[] memory) {
        address[] memory tokens = new address[](_acceptedPaymentTokens.length);
        uint256[] memory amounts = new uint256[](_acceptedPaymentTokens.length);

        for (uint i = 0; i < _acceptedPaymentTokens.length; i++) {
            address token = _acceptedPaymentTokens[i];
            uint256 depositAmount = _contributions[account].perToken[token];
            tokens[i] = token;
            amounts[i] = depositAmount;
        }

        return (_contributions[account].total, tokens, amounts);
    }

    function _addressIsValid(address addr) internal pure returns (bool) {
        return addr != address(0);
    }
}