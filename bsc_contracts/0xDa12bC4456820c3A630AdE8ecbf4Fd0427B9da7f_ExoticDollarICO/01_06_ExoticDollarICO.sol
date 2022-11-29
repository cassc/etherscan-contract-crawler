// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "./interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {PaymentSplitter} from "./finance/PaymentSplitter.sol";
import {SafeERC20} from "./libraries/SafeERC20.sol";

error PausedICOError();
error NotActiveClaimError();
error ZeroAmountClaimableError();
error WrongTokenError();
error AddressZeroError();
error WrongBuyAmountError(uint256);
error ExeedsCapError();

contract ExoticDollarICO is Ownable, PaymentSplitter {
    using SafeERC20 for IERC20;
    mapping(address => bool) public purchaseTokens;
    mapping(address => uint256) public purchases;
    address public quoteToken;
    uint256 public price = 1e18; // 1$
    uint256 public minBuyAmount = 100 * 1e18;
    uint256 public cap = 100_000_000 * 1e9;
    uint32 public nativePrice;
    bool public isOn;
    bool public isClaimable;
    uint256 public raised;


    constructor(
        address payable ownerAddress,
        address payable devAddress,
        uint8 ownerShare,
        address _quoteToken
    ) PaymentSplitter(ownerAddress, devAddress, ownerShare) {
        quoteToken = _quoteToken;

        transferOwnership(ownerAddress);
    }

    function setQuoteToken(address _quoteToken) external onlyOwner {
        quoteToken = _quoteToken;
    }

    function setPurchaseToken(address _purchaseToken, bool _isPurchaseToken)
        external
        onlyOwner
    {
        if (!_isPurchaseToken) {
            delete purchaseTokens[_purchaseToken];
        }
        purchaseTokens[_purchaseToken] = _isPurchaseToken;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMinBuyAmount(uint32 amount) external onlyOwner {
        minBuyAmount = amount;
    }

    function setNativePrice(uint32 _price) external onlyOwner {
        nativePrice = _price;
    }

    function setState(bool _isOn, bool _isClaimable) external onlyOwner {
        isOn = _isOn;
        isClaimable = _isClaimable;
    }


    function deposit(uint256 amount) external onlyOwner {
        IERC20(quoteToken).safeTransferFrom(
            _msgSender(),
            address(this),
            amount
        );
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            (bool success, ) = payable(_msgSender()).call{value: amount}("");
            require(success, "");
        } else {
            IERC20(token).safeTransfer(_msgSender(), amount);
        }
    }

    function calculateQuoteAmount(uint256 amount)
        public
        view
        returns (uint256)
    {
        return (amount * 1e9) / price;
    }

    function _buy(address recipient) private {
        if (!isOn) revert PausedICOError();
        if (recipient == address(0)) revert AddressZeroError();
        uint256 amount = (msg.value * nativePrice) / 100;
        if (amount < minBuyAmount) revert WrongBuyAmountError(minBuyAmount);
        splitPayment();

        uint256 quoteAmount = calculateQuoteAmount(amount);
        raised += quoteAmount;
        purchases[recipient] += quoteAmount;
    }

    function _buy(
        address token,
        uint256 amount,
        address recipient
    ) private {
        if (!isOn) revert PausedICOError();
        if (recipient == address(0)) revert AddressZeroError();
        if (!purchaseTokens[token]) revert WrongTokenError();
        if (amount < minBuyAmount) revert WrongBuyAmountError(minBuyAmount);

        IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);
        splitPayment(token);

        uint256 quoteAmount = calculateQuoteAmount(amount);
        if (raised + quoteAmount > cap) revert ExeedsCapError();
        raised += quoteAmount;
        purchases[recipient] += quoteAmount;
    }

    function buy(
        address token,
        uint256 amount,
        address recipient
    ) public payable {
        if (token == address(0)) {
            return _buy(recipient);
        }
        _buy(token, amount, recipient);
    }

    function claim(address recipient) public {
        if (!isClaimable) revert NotActiveClaimError();
        if (recipient == address(0)) revert AddressZeroError();
        uint256 claimAmount = purchases[msg.sender];
        if (claimAmount == 0) revert ZeroAmountClaimableError();
        delete purchases[msg.sender];
        IERC20(quoteToken).safeTransfer(recipient, claimAmount);
    }

    receive() external payable {
        _buy(_msgSender());
    }

    fallback() external payable {
        _buy(_msgSender());
    }
}