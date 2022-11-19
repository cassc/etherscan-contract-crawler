// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";

interface IFeeHandler {
    function getFeeInfo(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (uint256);

    function onFeeReceived(
        address sender,
        address recipient,
        uint256 amount,
        uint256 fee
    ) external;
}

contract TestFeeHandler is IFeeHandler, Ownable {
    IERC20 public token;
    address public feeRecipient;

    mapping(address => bool) public pairs;

    // Fee have 2 decimals, so 100 is equal to 1%, 525 is 5.25% and so on
    uint256 public p2pFee;
    uint256 public buyFee;
    uint256 public sellFee;

    event FeeUpdated(uint256 buyFee, uint256 sellFee, uint256 p2pFee);
    event FeeRecipientUpdated(address indexed oldFeeRecipient, address indexed newFeeRecipient);
    event SetPair(address indexed pair, bool enabled);

    constructor(
        IERC20 _token,
        address _feeRecipient,
        uint256 _buyFee,
        uint256 _sellFee,
        uint256 _p2pFee
    ) {
        token = _token;
        buyFee = _buyFee;
        sellFee = _sellFee;
        p2pFee = _p2pFee;
        feeRecipient = _feeRecipient;

        emit FeeUpdated(_buyFee, _sellFee, _p2pFee);
        emit FeeRecipientUpdated(address(0), _feeRecipient);
    }

    function getFeeInfo(
        address sender,
        address recipient,
        uint256
    ) external view override returns (uint256) {
        if (sender == address(this) || recipient == address(this)) return 0;

        // buy
        if (pairs[sender]) {
            return buyFee;
        }

        // sell
        if (pairs[recipient]) {
            return sellFee;
        }

        // p2p
        return p2pFee;
    }

    function onFeeReceived(
        address,
        address,
        uint256,
        uint256 fee
    ) external override {
        token.transfer(feeRecipient, fee);
    }

    function _setPair(address _pair, bool _enable) internal {
        pairs[_pair] = _enable;
        emit SetPair(_pair, _enable);
    }

    function setPair(address _pair, bool _enable) external onlyOwner {
        _setPair(_pair, _enable);
    }

    function setPairs(address[] memory _pairs, bool[] memory _enable) external onlyOwner {
        require(_pairs.length == _enable.length, "invalid length");
        for (uint256 i = 0; i < _pairs.length; i++) {
            _setPair(_pairs[i], _enable[i]);
        }
    }

    function setFee(
        uint256 _buyFee,
        uint256 _sellFee,
        uint256 _p2pFee
    ) external onlyOwner {
        buyFee = _buyFee;
        sellFee = _sellFee;
        p2pFee = _p2pFee;
        emit FeeUpdated(_buyFee, _sellFee, _p2pFee);
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        emit FeeRecipientUpdated(feeRecipient, _feeRecipient);
        feeRecipient = _feeRecipient;
    }
}