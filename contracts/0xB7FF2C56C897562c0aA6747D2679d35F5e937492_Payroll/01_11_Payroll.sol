//SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IERC20Basic.sol";
import "./interfaces/IUniswap.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "./BytesLib.sol";

/**
 * @title Think and Dev Paymentbox
 * @author Think and Dev Team
 * @notice Swap and transfer multiple ERC20 pairs to multiple accounts in a single transaction.
 * Use any router address of any DEX that uses Uniswap protocol v2 or v3 to make swaps.
 */
contract Payroll is Initializable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using BytesLib for bytes;
    /**
     * Returns the address of the Uniswap protocol router, it could be v2 or v3.
     */
    address public swapRouter;
    address public feeAddress;
    uint256 public fee;
    uint256 public constant MANTISSA = 1e18;
    uint256 public version;

    /**
     * Returns if the contract is working with a v2 Uniswap protocol;
     * true means v2, false means v3.
     */
    bool public isSwapV2;

    struct Payment {
        address token;
        address[] receivers;
        uint256[] amountsToTransfer;
    }

    struct SwapV2 {
        uint256 amountOut;
        uint256 amountInMax;
        address[] path;
    }

    struct SwapV3 {
        uint256 amountOut;
        uint256 amountInMax;
        bytes path;
    }

    event SwapRouterChanged(address _swapRouter, bool _isSwapV2);
    event FeeChanged(uint256 _fee);
    event UpdatedVersion(uint256 _version);
    event FeeCharged(address _erc20TokenAddress, address _feeAddress, uint256 _fees);
    event FeeAddressChanged(address _feeAddress);
    event BatchPayment(address _erc20TokenAddress, address[] _receivers, uint256[] _amountsToTransfer);
    event SwapFinished(address _tokenIn, address _tokenOut, uint256 _amountReceived);

    /**
     * @param _swapRouter Router address to execute swaps.
     * @param _isSwapV2 Boolean to specify the version of the router; true means v2, false means v3.
     */
    function initialize(
        address _swapRouter,
        bool _isSwapV2,
        address _feeAddress,
        uint256 _fee
    ) public initializer {
        __ReentrancyGuard_init();
        __Ownable_init();
        _setSwapRouter(_swapRouter, _isSwapV2);
        _setFeeAddress(_feeAddress);
        _setFee(_fee);
        _setVersion(1);
    }

    /**
     * Set the fee that will be charged, fees are divided by mantissa
     * @param _fee Percentage that will be charged.
     */
    function setFee(uint256 _fee) external onlyOwner {
        _setFee(_fee);
    }

    function setVersion(uint256 _version) external onlyOwner {
        _setVersion(_version);
    }

    function _setVersion(uint256 _version) internal {
        require(_version > 0, "Payroll: Version can't be 0");
        version = _version;
        emit UpdatedVersion(_version);
    }

    function _setFee(uint256 _fee) internal {
        require(_fee < 3e16, "Payroll: Fee should be less than 3%");
        fee = _fee;
        emit FeeChanged(_fee);
    }

    /**
     * Set the address that will receive the fees.
     * @param _feeAddress Address that will receive the fees.
     */
    function setFeeAddress(address _feeAddress) external onlyOwner {
        _setFeeAddress(_feeAddress);
    }

    function _setFeeAddress(address _feeAddress) internal {
        require(_feeAddress != address(0), "Payroll: Fee address can't be 0");
        feeAddress = _feeAddress;
        emit FeeAddressChanged(_feeAddress);
    }

    /**
     * Set the SwapRouter and the version to be used.
     * @param _swapRouter Router address to execute swaps.
     * @param _isSwapV2 Boolean to specify the version of the router; true means v2, false means v3.
     */
    function setSwapRouter(address _swapRouter, bool _isSwapV2) external onlyOwner {
        _setSwapRouter(_swapRouter, _isSwapV2);
    }

    function _setSwapRouter(address _swapRouter, bool _isSwapV2) internal {
        require(_swapRouter != address(0), "Payroll: Cannot set a 0 address as swapRouter");
        isSwapV2 = _isSwapV2;
        swapRouter = _swapRouter;
        emit SwapRouterChanged(_swapRouter, _isSwapV2);
    }

    /**
     * Approves the following token to be used on swapRouter
     * @param _erc20TokenOrigin ERC20 token address to approve.
     */
    function approveTokens(address[] calldata _erc20TokenOrigin) external nonReentrant {
        for (uint256 i = 0; i < _erc20TokenOrigin.length; i++) {
            // approves the swapRouter to spend totalAmountToSpend of erc20TokenOrigin
            TransferHelper.safeApprove(_erc20TokenOrigin[i], address(swapRouter), type(uint256).max);
        }
    }

    /**
     * Perform the swap with Uniswap V3 and the transfer to the given addresses.
     * @param _erc20TokenOrigin ERC20 token address to swap for another.
     * @param _totalAmountToSwap Total amount of erc20TokenOrigin to spend in swaps.
     * @param _deadline The unix timestamp after a swap will fail.
     * @param _swaps The array of the Swaps data.
     * @param _payments The array of the Payment data.
     * @notice Currently the function only works with ERC20 tokens.
     */
    function performSwapV3AndPayment(
        address _erc20TokenOrigin,
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV3[] calldata _swaps,
        Payment[] calldata _payments
    ) external payable nonReentrant {
        require(!isSwapV2, "Payroll: Not uniswapV3");
        if (_swaps.length > 0) {
            _performSwapV3(_erc20TokenOrigin, _totalAmountToSwap, _deadline, _swaps);
        }

        _performMultiPayment(_payments);
    }

    /**
     * Perform the swap with Uniswap V3 to the given token addresses and amounts.
     * @param _erc20TokenOrigin ERC20 token address to swap for another.
     * @param _totalAmountToSwap Total amount of erc20TokenOrigin to spend in swaps.
     * @param _deadline The unix timestamp after a swap will fail.
     * @param _swaps The array of the Swaps data.
     */
    function performSwapV3(
        address _erc20TokenOrigin,
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV3[] calldata _swaps
    ) external nonReentrant returns (uint256) {
        require(!isSwapV2, "Payroll: Not uniswapV3");
        require(_swaps.length > 0, "Payroll: Empty swaps");
        return _performSwapV3(_erc20TokenOrigin, _totalAmountToSwap, _deadline, _swaps);
    }

    /**
     * Perform the swap with Uniswap V3 to the given token addresses and amounts.
     * @param _erc20TokenOrigin ERC20 token address to swap for another.
     * @param _totalAmountToSwap Total amount of erc20TokenOrigin to spend in swaps.
     * @param _deadline The unix timestamp after a swap will fail.
     * @param _swaps The array of the Swaps data.
     */
    function _performSwapV3(
        address _erc20TokenOrigin,
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV3[] calldata _swaps
    ) internal returns (uint256) {
        // transfer the totalAmountToSpend of erc20TokenOrigin from the msg.sender to this contract
        // msg.sender must approve this contract for erc20TokenOrigin
        TransferHelper.safeTransferFrom(_erc20TokenOrigin, msg.sender, address(this), _totalAmountToSwap);

        uint256 totalAmountIn = 0;
        for (uint256 i = 0; i < _swaps.length; i++) {
            require(_swaps[i].path.length > 0, "Payroll: Empty path");
            uint256 amountIn = IUniswapV3(swapRouter).exactOutput(
                IUniswapV3.ExactOutputParams({
                    path: _swaps[i].path,
                    recipient: msg.sender,
                    deadline: _deadline,
                    amountOut: _swaps[i].amountOut,
                    amountInMaximum: _swaps[i].amountInMax
                })
            );
            totalAmountIn = totalAmountIn + amountIn;
            emit SwapFinished(_erc20TokenOrigin, _swaps[i].path.toAddress(0), amountIn);
        }

        uint256 leftOver = IERC20Basic(_erc20TokenOrigin).balanceOf(address(this));
        if (leftOver > 0) {
            // return the leftover of _erc20TokenOrigin
            TransferHelper.safeTransfer(_erc20TokenOrigin, msg.sender, leftOver);
        }
        return totalAmountIn;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    /**
     * Perform the swap with Uniswap V2 and the transfer to the given addresses using Uniswap V2 interface.
     * @param _erc20TokenOrigin ERC20 token address to swap for another.
     * @param _totalAmountToSwap Total amount of erc20TokenOrigin to spend in swaps.
     * @param _deadline The unix timestamp after a swap will fail.
     * @param _swaps The array of the Swaps data.
     * @param _payments The array of the Payment data.
     * @notice Currently the function only works with ERC20 tokens.
     */
    function performSwapV2AndPayment(
        address _erc20TokenOrigin,
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV2[] calldata _swaps,
        Payment[] calldata _payments
    ) external payable nonReentrant {
        require(isSwapV2, "Payroll: Not uniswapV2");
        if (_swaps.length > 0) {
            _performSwapV2(_erc20TokenOrigin, _totalAmountToSwap, _deadline, _swaps);
        }

        _performMultiPayment(_payments);
    }

    /**
     * Perform the swap with Uniswap V2 to the given token addresses and amounts.
     * @param _erc20TokenOrigin ERC20 token address to swap for another.
     * @param _totalAmountToSwap Total amount of erc20TokenOrigin to spend in swaps.
     * @param _deadline The unix timestamp after a swap will fail.
     * @param _swaps The array of the Swaps data.
     */
    function performSwapV2(
        address _erc20TokenOrigin,
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV2[] calldata _swaps
    ) external nonReentrant returns (uint256) {
        require(isSwapV2, "Payroll: Not uniswapV2");
        require(_swaps.length > 0, "Payroll: Empty swaps");
        return _performSwapV2(_erc20TokenOrigin, _totalAmountToSwap, _deadline, _swaps);
    }

    /**
     * Perform the swap with Uniswap V2 to the given token addresses and amounts.
     * @param _erc20TokenOrigin ERC20 token address to swap for another.
     * @param _totalAmountToSwap Total amount of erc20TokenOrigin to spend in swaps.
     * @param _deadline The unix timestamp after a swap will fail.
     * @param _swaps The array of the Swaps data.
     */
    function _performSwapV2(
        address _erc20TokenOrigin,
        uint256 _totalAmountToSwap,
        uint32 _deadline,
        SwapV2[] calldata _swaps
    ) internal returns (uint256) {
        // transfer the totalAmountToSpend of erc20TokenOrigin from the msg.sender to this contract
        // msg.sender must approve this contract for erc20TokenOrigin
        TransferHelper.safeTransferFrom(_erc20TokenOrigin, msg.sender, address(this), _totalAmountToSwap);

        uint256 totalAmountIn = 0;
        for (uint256 i = 0; i < _swaps.length; i++) {
            require(_swaps[i].path.length > 0, "Payroll: Empty path");
            require(_swaps[i].path[0] == _erc20TokenOrigin, "Payroll: Swap not token origin");
            // return the amount spend of tokenIn
            uint256 amountIn = IUniswapV2(swapRouter).swapTokensForExactTokens(
                _swaps[i].amountOut,
                _swaps[i].amountInMax,
                _swaps[i].path,
                msg.sender,
                _deadline
            )[0];
            totalAmountIn = totalAmountIn + amountIn;
            address[] calldata path = _swaps[i].path;
            emit SwapFinished(_erc20TokenOrigin, path[path.length - 1], amountIn);
        }

        uint256 leftOver = IERC20Basic(_erc20TokenOrigin).balanceOf(address(this));
        if (leftOver > 0) {
            // return the leftover of _erc20TokenOrigin
            TransferHelper.safeTransfer(_erc20TokenOrigin, msg.sender, leftOver);
        }
        return totalAmountIn;
    }

    /**
     * Perform the payments to the given addresses and amounts, public method.
     * @param _payments The array of the Payment data.
     */
    function performMultiPayment(Payment[] calldata _payments) external payable nonReentrant {
        _performMultiPayment(_payments);
    }

    /**
     * Perform the payments to the given addresses and amounts, internal method.
     * @param _payments The array of the Payment data.
     */
    function _performMultiPayment(Payment[] calldata _payments) internal {
        uint256 totalETHSent = 0;
        for (uint256 i = 0; i < _payments.length; i++) {
            require(_payments[i].amountsToTransfer.length > 0, "Payroll: No amounts to transfer");
            require(
                _payments[i].amountsToTransfer.length == _payments[i].receivers.length,
                "Payroll: Arrays must have same length"
            );

            if (_payments[i].token != address(0)) {
                _performERC20Payment(_payments[i].token, _payments[i].receivers, _payments[i].amountsToTransfer);
            } else {
                totalETHSent =
                    totalETHSent +
                    _performETHPayment(_payments[i].token, _payments[i].receivers, _payments[i].amountsToTransfer);
            }
        }

        uint256 leftOver = msg.value - totalETHSent;
        if (leftOver > 1) {
            (bool success, ) = payable(msg.sender).call{value: leftOver}("");
            require(success, "Payroll: ETH leftOver transfer failed");
        }
    }

    /**
     * Performs the ERC20 payment to the given addresses.
     * @param _erc20TokenAddress The address of the ERC20 token to transfer.
     * @param _receivers The array of payment receivers.
     * @param _amountsToTransfer The array of payments' amounts to perform.
     * The amount will be transfered to the address on _receivers with the same index.
     */
    function _performERC20Payment(
        address _erc20TokenAddress,
        address[] calldata _receivers,
        uint256[] calldata _amountsToTransfer
    ) internal {
        uint256 acumulatedFee = 0;
        uint256 totalAmountSent = 0;

        for (uint256 i = 0; i < _receivers.length; i++) {
            require(_receivers[i] != address(0), "Payroll: Cannot send to a 0 address");
            totalAmountSent = totalAmountSent + _amountsToTransfer[i];
            TransferHelper.safeTransferFrom(_erc20TokenAddress, msg.sender, _receivers[i], _amountsToTransfer[i]);
        }
        emit BatchPayment(_erc20TokenAddress, _receivers, _amountsToTransfer);

        acumulatedFee = (totalAmountSent * fee) / MANTISSA;
        if (acumulatedFee > 0) {
            TransferHelper.safeTransferFrom(_erc20TokenAddress, msg.sender, feeAddress, acumulatedFee);
        }
        emit FeeCharged(_erc20TokenAddress, feeAddress, acumulatedFee);
    }

    /**
     * Performs the ETH payment to the given addresses.
     * @param _receivers The array of payment receivers.
     * @param _amountsToTransfer The array of payments' amounts to perform.
     * The amount will be transfered to the address on _receivers with the same index.
     */
    function _performETHPayment(
        address _erc20TokenAddress,
        address[] calldata _receivers,
        uint256[] calldata _amountsToTransfer
    ) internal returns (uint256) {
        uint256 acumulatedFee = 0;
        uint256 totalAmountSent = 0;

        for (uint256 i = 0; i < _receivers.length; i++) {
            require(_receivers[i] != address(0), "Payroll: Cannot send to a 0 address");
            totalAmountSent = totalAmountSent + _amountsToTransfer[i];

            (bool success, ) = payable(_receivers[i]).call{value: _amountsToTransfer[i]}("");
            require(success, "Payroll: ETH transfer failed");
        }
        emit BatchPayment(_erc20TokenAddress, _receivers, _amountsToTransfer);

        acumulatedFee = (totalAmountSent * fee) / MANTISSA;
        if (acumulatedFee > 0) {
            totalAmountSent = totalAmountSent + acumulatedFee;
            (bool success, ) = payable(feeAddress).call{value: acumulatedFee}("");
            require(success, "Payroll: ETH fee transfer failed");
        }
        emit FeeCharged(_erc20TokenAddress, feeAddress, acumulatedFee);

        return totalAmountSent;
    }
}