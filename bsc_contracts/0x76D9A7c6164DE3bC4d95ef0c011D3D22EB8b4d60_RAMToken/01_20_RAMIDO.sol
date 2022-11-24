// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract RAMIDO is Ownable {

    uint256 public startTime;
    uint256 public endTime;

    address public token;
    address public payment;
    uint256 public priceInPayment;
    address public beneficiary;
    uint256 public maxSellAmount;
    uint256 public maxSellAmountInPaymentPerWallet;
    uint256 public totalSoldAmount;
    uint256 public totalSoldAmountInPayment;
    mapping (address => uint256) public soldAmountOf;
    mapping (address => uint256) public soldAmountInPaymentOf;
    mapping (address => uint256) public claimedAmountOf;
    uint256 public totalClaimedAmount;

    constructor(
        uint256 _startTime,
        uint256 _endTime,
        address _payment,
        uint256 _priceInPayment,
        address _beneficiary,
        uint256 _maxSellAmount,
        uint256 _maxSellAmountInPaymentPerWallet
    ) {
        _setDuration(_startTime, _endTime);
        _setPayment(_payment, _priceInPayment);

        beneficiary = _beneficiary;
        maxSellAmount = _maxSellAmount;
        maxSellAmountInPaymentPerWallet = _maxSellAmountInPaymentPerWallet;
    }

    function participate(uint256 amountInPayment) external {
        require(block.timestamp >= startTime, 'RAMIDO: not start yet.');
        require(block.timestamp < endTime, 'RAMIDO: already done.');

        uint256 _soldAmountInPayment = soldAmountInPaymentOf[msg.sender] + amountInPayment;
        require(_soldAmountInPayment <= maxSellAmountInPaymentPerWallet, 'RAMIDO: already bought.');

        IERC20 _payment = IERC20(payment);
        require(_payment.allowance(msg.sender, address(this)) >= amountInPayment, 'RAMIDO: insufficient allowance.');

        uint256 _soldAmount = amountInPayment * 1 ether / priceInPayment;
        uint256 _totalSoldAmount = totalSoldAmount + _soldAmount;
        require(_totalSoldAmount <= maxSellAmount, 'RAMIDO: already sold out.');

        totalSoldAmount = _totalSoldAmount;
        soldAmountOf[msg.sender] += _soldAmount;
        soldAmountInPaymentOf[msg.sender] = _soldAmountInPayment;
        totalSoldAmountInPayment += amountInPayment;
        SafeERC20.safeTransferFrom(
            _payment,
            msg.sender,
            beneficiary,
            amountInPayment
        );
    }

    function claim() external {
        require(block.timestamp >= endTime, 'RAMIDO: not done yet.');

        uint256 _claimableAmount = soldAmountOf[msg.sender] - claimedAmountOf[msg.sender];
        require(_claimableAmount > 0, 'RAMIDO: already claimed.');
        require(IERC20(token).balanceOf(address(this)) >= _claimableAmount, 'RAMIDO: insufficient balance.');

        totalClaimedAmount += _claimableAmount;
        claimedAmountOf[msg.sender] += _claimableAmount;
        SafeERC20.safeTransfer(
            IERC20(token),
            msg.sender,
            _claimableAmount
        );
    }

    function adjustBalance() external {
        require(block.timestamp >= endTime, 'RAMIDO: not done yet.');

        uint256 _balanceOfToken = IERC20(token).balanceOf(address(this));
        uint256 _unClaimAmount = totalSoldAmount - totalClaimedAmount;
        if (_balanceOfToken > _unClaimAmount) {
            SafeERC20.safeTransfer(
                IERC20(token),
                beneficiary,
                _balanceOfToken - _unClaimAmount
            );
        } else {
            SafeERC20.safeTransferFrom(
                IERC20(token),
                msg.sender,
                address(this),
                _unClaimAmount - _balanceOfToken
            );
        }
    }

    function setDuration(uint256 _startTime, uint256 _endTime) external onlyOwner {
        _setDuration(_startTime, _endTime);
    }

    function setPayment(address _payment, uint256 _priceInPayment) external onlyOwner {
        _setPayment(_payment, _priceInPayment);
    }

    function setMaxSellAmount(uint256 _maxSellAmount) external onlyOwner {
        maxSellAmount = _maxSellAmount;
    }

    function setMaxSellAmountInPaymentPerWallet(uint256 _maxSellAmountInPaymentPerWallet) external onlyOwner {
        maxSellAmountInPaymentPerWallet = _maxSellAmountInPaymentPerWallet;
    }

    function setToken(address _token) external onlyOwner {
        token = _token;
    }

    function setBeneficiary(address _beneficiary) external {
        require(msg.sender == beneficiary, 'RAMIDO: caller is not the beneficiary.');
        beneficiary = _beneficiary;
    }

    function _setDuration(uint256 _startTime, uint256 _endTime) private {
        require(_endTime > _startTime, 'RAMIDO: invalid duration.');
        startTime = _startTime;
        endTime = _endTime;
    }

    function _setPayment(address _payment, uint256 _priceInPayment) private {
        require(_payment != address(0), 'RAMIDO: payment not a valid ERC20.');
        payment = _payment;
        priceInPayment = _priceInPayment;
    }
}