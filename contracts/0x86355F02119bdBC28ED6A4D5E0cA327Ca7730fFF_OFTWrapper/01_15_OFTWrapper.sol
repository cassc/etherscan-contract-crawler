// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@layerzerolabs/solidity-examples/contracts/token/oft/v2/IOFTV2.sol";
import "@layerzerolabs/solidity-examples/contracts/token/oft/v2/fee/IOFTWithFee.sol";
import "@layerzerolabs/solidity-examples/contracts/token/oft/IOFT.sol";
import "./interfaces/IOFTWrapper.sol";

contract OFTWrapper is IOFTWrapper, Ownable, ReentrancyGuard {
    using SafeERC20 for IOFT;

    uint256 public constant BPS_DENOMINATOR = 10000;
    uint256 public constant MAX_UINT = 2**256 - 1; // indicates a bp fee of 0 that overrides the default bps

    uint256 public defaultBps;
    mapping(address => uint256) public oftBps;

    constructor(uint256 _defaultBps) {
        require(_defaultBps < BPS_DENOMINATOR, "OFTWrapper: defaultBps >= 100%");
        defaultBps = _defaultBps;
    }

    function setDefaultBps(uint256 _defaultBps) external onlyOwner {
        require(_defaultBps < BPS_DENOMINATOR, "OFTWrapper: defaultBps >= 100%");
        defaultBps = _defaultBps;
    }

    function setOFTBps(address _token, uint256 _bps) external onlyOwner {
        require(_bps < BPS_DENOMINATOR || _bps == MAX_UINT, "OFTWrapper: oftBps[_oft] >= 100%");
        oftBps[_token] = _bps;
    }

    function withdrawFees(
        address _oft,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IOFT(_oft).safeTransfer(_to, _amount);
        emit WrapperFeeWithdrawn(_oft, _to, _amount);
    }

    function sendOFT(
        address _oft,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        uint256 _minAmount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams,
        FeeObj calldata _feeObj
    ) external payable nonReentrant {
        uint256 amountToSwap = _getAmountAndPayFee(_oft, _amount, _minAmount, _feeObj);
        IOFT(_oft).sendFrom{value: msg.value}(msg.sender, _dstChainId, _toAddress, amountToSwap, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    function sendProxyOFT(
        address _proxyOft,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        uint256 _minAmount,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams,
        FeeObj calldata _feeObj
    ) external payable nonReentrant {
        address token = IOFTV2(_proxyOft).token();
        {
            uint256 amountToSwap = _getAmountAndPayFeeProxy(token, _amount, _minAmount, _feeObj);

            // approve proxy to spend tokens
            IOFT(token).safeApprove(_proxyOft, amountToSwap);
            IOFT(_proxyOft).sendFrom{value: msg.value}(address(this), _dstChainId, _toAddress, amountToSwap, _refundAddress, _zroPaymentAddress, _adapterParams);
        }

        // reset allowance if sendFrom() does not consume full amount
        if (IOFT(token).allowance(address(this), _proxyOft) > 0) IOFT(token).safeApprove(_proxyOft, 0);
    }

    function sendOFTV2(
        address _oft,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        uint256 _minAmount,
        IOFTV2.LzCallParams calldata _callParams,
        FeeObj calldata _feeObj
    ) external payable nonReentrant {
        uint256 amountToSwap = _getAmountAndPayFee(_oft, _amount, _minAmount, _feeObj);
        IOFTV2(_oft).sendFrom{value: msg.value}(msg.sender, _dstChainId, _toAddress, amountToSwap, _callParams);
    }

    function sendOFTFeeV2(
        address _oft,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        uint256 _minAmount,
        IOFTV2.LzCallParams calldata _callParams,
        FeeObj calldata _feeObj
    ) external payable nonReentrant {
        uint256 amountToSwap = _getAmountAndPayFee(_oft, _amount, _minAmount, _feeObj);
        IOFTWithFee(_oft).sendFrom{value: msg.value}(msg.sender, _dstChainId, _toAddress, amountToSwap, _minAmount, _callParams);
    }

    function sendProxyOFTV2(
        address _proxyOft,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        uint256 _minAmount,
        IOFTV2.LzCallParams calldata _callParams,
        FeeObj calldata _feeObj
    ) external payable nonReentrant {
        address token = IOFTV2(_proxyOft).token();
        uint256 amountToSwap = _getAmountAndPayFeeProxy(token, _amount, _minAmount, _feeObj);

        // approve proxy to spend tokens
        IOFT(token).safeApprove(_proxyOft, amountToSwap);
        IOFTV2(_proxyOft).sendFrom{value: msg.value}(address(this), _dstChainId, _toAddress, amountToSwap, _callParams);

        // reset allowance if sendFrom() does not consume full amount
        if (IOFT(token).allowance(address(this), _proxyOft) > 0) IOFT(token).safeApprove(_proxyOft, 0);
    }

    function sendProxyOFTFeeV2(
        address _proxyOft,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        uint256 _minAmount,
        IOFTV2.LzCallParams calldata _callParams,
        FeeObj calldata _feeObj
    ) external payable nonReentrant {
        address token = IOFTV2(_proxyOft).token();
        uint256 amountToSwap = _getAmountAndPayFeeProxy(token, _amount, _minAmount, _feeObj);

        // approve proxy to spend tokens
        IOFT(token).safeApprove(_proxyOft, amountToSwap);
        IOFTWithFee(_proxyOft).sendFrom{value: msg.value}(address(this), _dstChainId, _toAddress, amountToSwap, _minAmount, _callParams);

        // reset allowance if sendFrom() does not consume full amount
        if (IOFT(token).allowance(address(this), _proxyOft) > 0) IOFT(token).safeApprove(_proxyOft, 0);
    }

    function _getAmountAndPayFeeProxy(
        address _token,
        uint256 _amount,
        uint256 _minAmount,
        FeeObj calldata _feeObj
    ) internal returns (uint256) {
        (uint256 amountToSwap, uint256 wrapperFee, uint256 callerFee) = getAmountAndFees(_token, _amount, _feeObj.callerBps);
        require(amountToSwap >= _minAmount && amountToSwap > 0, "OFTWrapper: not enough amountToSwap");

        IOFT(_token).safeTransferFrom(msg.sender, address(this), amountToSwap + wrapperFee); // pay wrapper and move proxy tokens to contract
        if (callerFee > 0) IOFT(_token).safeTransferFrom(msg.sender, _feeObj.caller, callerFee); // pay caller

        emit WrapperFees(_feeObj.partnerId, _token, wrapperFee, callerFee);

        return amountToSwap;
    }

    function _getAmountAndPayFee(
        address _token,
        uint256 _amount,
        uint256 _minAmount,
        FeeObj calldata _feeObj
    ) internal returns (uint256) {
        (uint256 amountToSwap, uint256 wrapperFee, uint256 callerFee) = getAmountAndFees(_token, _amount, _feeObj.callerBps);
        require(amountToSwap >= _minAmount && amountToSwap > 0, "OFTWrapper: not enough amountToSwap");

        if (wrapperFee > 0) IOFT(_token).safeTransferFrom(msg.sender, address(this), wrapperFee); // pay wrapper
        if (callerFee > 0) IOFT(_token).safeTransferFrom(msg.sender, _feeObj.caller, callerFee); // pay caller

        emit WrapperFees(_feeObj.partnerId, _token, wrapperFee, callerFee);

        return amountToSwap;
    }

    function getAmountAndFees(
        address _token, // will be the token on proxies, and the oft on non-proxy
        uint256 _amount,
        uint256 _callerBps
    )
        public
        view
        override
        returns (
            uint256 amount,
            uint256 wrapperFee,
            uint256 callerFee
        )
    {
        uint256 wrapperBps;

        if (oftBps[_token] == MAX_UINT) {
            wrapperBps = 0;
        } else if (oftBps[_token] > 0) {
            wrapperBps = oftBps[_token];
        } else {
            wrapperBps = defaultBps;
        }

        require(wrapperBps + _callerBps < BPS_DENOMINATOR, "OFTWrapper: Fee bps >= 100%");

        wrapperFee = wrapperBps > 0 ? (_amount * wrapperBps) / BPS_DENOMINATOR : 0;
        callerFee = _callerBps > 0 ? (_amount * _callerBps) / BPS_DENOMINATOR : 0;
        amount = wrapperFee > 0 || callerFee > 0 ? _amount - wrapperFee - callerFee : _amount;
    }

    function estimateSendFee(
        address _oft,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _amount,
        bool _useZro,
        bytes calldata _adapterParams,
        FeeObj calldata _feeObj
    ) external view override returns (uint nativeFee, uint zroFee) {
        (uint256 amount, , ) = getAmountAndFees(_oft, _amount, _feeObj.callerBps);

        return IOFT(_oft).estimateSendFee(_dstChainId, _toAddress, amount, _useZro, _adapterParams);
    }

    function estimateSendFeeV2(
        address _oft,
        uint16 _dstChainId,
        bytes32 _toAddress,
        uint256 _amount,
        bool _useZro,
        bytes calldata _adapterParams,
        FeeObj calldata _feeObj
    ) external view override returns (uint nativeFee, uint zroFee) {
        (uint256 amount, , ) = getAmountAndFees(_oft, _amount, _feeObj.callerBps);

        return IOFTV2(_oft).estimateSendFee(_dstChainId, _toAddress, amount, _useZro, _adapterParams);
    }
}