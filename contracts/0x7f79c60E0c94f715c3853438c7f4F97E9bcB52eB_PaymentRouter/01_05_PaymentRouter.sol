// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {IERC20} from "./lib/IERC20.sol";
import {Iusdt} from "./lib/Iusdt.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract PaymentRouter is Ownable {

    Iusdt public usdt;
    address public paymentVault;
    uint256 public minDeposit; // in usd 
    uint256 public minDepositDecimals;
    bool public isWorking;

    mapping(address => bool) public availableTokens;

    event PaymentReceived(address indexed paymentToken, address indexed from, address to, uint256 amount);

    constructor(
        address paymentVault_,
        uint256 minDeposit_,
        uint256 minDepositDecimals_,
        Iusdt usdt_,
        address[] memory paymentTokens_
    ) {
        paymentVault = paymentVault_;
        minDeposit = minDeposit_;
        minDepositDecimals = minDepositDecimals_;
        usdt = usdt_;

        for (uint256 i = 0; i < paymentTokens_.length; i++) {
            availableTokens[paymentTokens_[i]] = true;
        }
    }

    function payToken(IERC20 paymentToken, uint256 amount) external {
        require(isWorking, "Sale isn't started");
        require(availableTokens[address(paymentToken)], "This token isn't available to deposit");
        require(paymentToken.balanceOf(msg.sender) >= amount, "Not enough balance");
        require(amount >= minDeposit * (10 ** paymentToken.decimals()) / minDepositDecimals, "Too low deposit");
        if (address(paymentToken) == address(usdt)) {
            usdt.transferFrom(msg.sender, paymentVault, amount);
        } else {
            paymentToken.transferFrom(msg.sender, paymentVault, amount);
        }
        
        emit PaymentReceived(address(paymentToken), msg.sender, paymentVault, amount);
    }

    function toggleWorking() external onlyOwner {
        isWorking = !isWorking;
    }

    function setAvailableToken(address _newToken) public onlyOwner {
        availableTokens[_newToken] = true;
    }

    function batchSetAvailableToken(address[] calldata _tokens) external onlyOwner {
        for(uint256 i = 0; i < _tokens.length; i++) {
            setAvailableToken(_tokens[i]);
        }
    }

    function unsetAvailableToken(address _token) public onlyOwner {
        availableTokens[_token] = false;
    }

    function batchUnsetAvailableToken(address[] calldata _tokens) external onlyOwner {
        for(uint256 i = 0; i < _tokens.length; i++) {
            unsetAvailableToken(_tokens[i]);
        }
    }

    function setPaymentVault(address _newPaymentVault) external onlyOwner {
        paymentVault = _newPaymentVault;
    }

    function setMinDeposit(uint256 _newMinDeposit, uint256 _minDepositDecimals) external onlyOwner {
        minDeposit = _newMinDeposit;
        minDepositDecimals = _minDepositDecimals;
    }
}