// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Token dependencies
import {ERC20} from "solmate/tokens/ERC20.sol";
import {WETH} from "solmate/tokens/WETH.sol";

// Security dependencies
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {PausableUpgradeable} from "openzeppelin-upgradeable/security/PausableUpgradeable.sol";
import {OwnableUpgradeable} from "openzeppelin-upgradeable/access/OwnableUpgradeable.sol";

// Upgradability dependencies
import {Initializable} from "openzeppelin-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "openzeppelin-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// Import libraries
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ECDSAUpgradeable} from "openzeppelin-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

/// @title Swype On-Chain Protocol
/// @author raj, matt
contract Swype is Initializable, UUPSUpgradeable, PausableUpgradeable, OwnableUpgradeable, ReentrancyGuard {
    using SafeTransferLib for ERC20;
    using ECDSAUpgradeable for bytes32;

    /*********************************************************
     * ERRORS
     *********************************************************/

    error BANKING_TX_ID_USED();
    error SIGNATURE_USED();
    error INVALID_SIGNATURE();
    error INVALID_AMOUNT();
    error INSUFFICIENT_LIQUIDITY();
    error UNAPPROVED_EXCHANGE();
    error EXCHANGE_FAILED();

    /*********************************************************
     * EVENTS
     *********************************************************/

    event OnrampRequestFulFilled(string indexed bankingTxId, address token, uint256 amount);
    event OfframpRequest(string uid, address token, uint256 tokenAmount, uint256 fiatAmountToReceive);
    event FeeChanged(uint256 indexed newFee);
    event ExchangeApproved(address indexed exchange);
    event ExchangeRemoved(address indexed exchange);
    event SwypeSignerChanged(address indexed newSigner);

    /*********************************************************
     * STATE
     *********************************************************/

    /// @notice usdc
    ERC20 private _USDC;

    /// @notice weth
    WETH private _WETH;

    /// @notice Swype Signer Address
    address private _swypeSigner;

    /// @notice Has a signature been used
    mapping(bytes32 => bool) private _executedHashes;

    /// @notice Has a banking transactiond ID been used
    mapping(string => bool) private _usedBankingTxIds;

    /// @notice approved exchanges
    mapping(address => bool) public approvedExchanges;

    /// @notice fee charged (in basis points)
    uint24 public swypeFee;

    function initialize(
        address usdc_,
        address weth_,
        address swypeSigner_,
        uint24 swypeFee_
    ) external initializer {
        __Ownable_init();

        _USDC = ERC20(usdc_);
        _WETH = WETH(payable(weth_));

        _swypeSigner = swypeSigner_;

        swypeFee = swypeFee_;

        // Approve the Swype contract as an exchange for verification with USDC on-ramps
        approvedExchanges[address(this)] = true;
    }

    /*********************************************************
     * ONRAMP FUNCTIONS
     *********************************************************/

    /// @notice                 On-ramping to USDC
    /// @param bankingTxId      The banking transaction ID that user made to deposit funds to Swype
    /// @param amount           The amount of USDC to on-ramp
    /// @param recipient        The recipient of the USDC
    /// @param signature        The signature from Swype that the banking transaction was valid
    function onrampUsdc(
        string calldata bankingTxId,
        uint256 amount,
        address recipient,
        bytes calldata signature
    ) external whenNotPaused {
        bytes32 txHash = getTxHash(bankingTxId, address(_USDC), amount, 0, recipient);
        _onrampChecks(bankingTxId, address(this), signature, txHash);
        
        _usedBankingTxIds[bankingTxId] = true;
        _executedHashes[txHash] = true;

        // Calculate USDC amount to on-ramp after fees
        uint256 usdcAmountAfterFee = _amountAfterFee(amount);

        _USDC.safeTransfer(recipient, usdcAmountAfterFee);

        // Emit request fulfilled event
        emit OnrampRequestFulFilled(bankingTxId, address(_USDC), amount);
    }

    /// @notice                 On-ramping a specific amount of USD to the native asset
    /// @param bankingTxId      The banking transaction ID that user made to deposit funds to Swype
    /// @param exchange         The address of the exchange to swap on
    /// @param swapData         The pre-compiled swap data to pass to the exchange
    /// @param amount           The amount of USD to on-ramp to native asset
    /// @param recipient        The recipient of the native asset
    /// @param signature        The signature from Swype that the banking transaction was valid
    function onrampNativeExactIn(
        string calldata bankingTxId,
        address exchange,
        bytes calldata swapData,
        uint256 amount,
        address recipient,
        bytes calldata signature
    ) external whenNotPaused {
        bytes32 txHash = getTxHash(bankingTxId, address(0), amount, 0, recipient);
        _onrampChecks(bankingTxId, exchange, signature, txHash);

        _usedBankingTxIds[bankingTxId] = true;
        _executedHashes[txHash] = true;

        // Swap USDC to wrapped native token
        uint256 amountOut = _exactInSwap(exchange, swapData, address(_USDC), address(_WETH), address(this));

        // Unwrap native token
        _WETH.withdraw(amountOut);

        // Send native token to user
        SafeTransferLib.safeTransferETH(recipient, amountOut);

        // Emit request fulfilled event
        emit OnrampRequestFulFilled(bankingTxId, address(0), amount);
    }

    /// @notice                 On-ramping USD to a specific amount of native assets
    /// @param bankingTxId      The banking transaction ID that user made to deposit funds to Swype
    /// @param exchange         The address of the exchange to swap on
    /// @param swapData         The pre-compiled swap data to pass to the exchange
    /// @param amountOut        The amount of native asset to on-ramp to
    /// @param recipient        The recipient of the native asset
    /// @param signature        The signature from Swype that the banking transaction was valid
    function onrampNativeExactOut(
        string calldata bankingTxId,
        address exchange,
        bytes calldata swapData,
        uint256 amountOut,
        address recipient,
        bytes calldata signature
    ) external whenNotPaused {
        bytes32 txHash = getTxHash(bankingTxId, address(0), amountOut, 1, recipient);
        _onrampChecks(bankingTxId, exchange, signature, txHash);

        _usedBankingTxIds[bankingTxId] = true;
        _executedHashes[txHash] = true;

        // Swap USDC to wrapped native token
        uint256 amountReceived = _exactOutSwap(exchange, swapData, address(_WETH), amountOut, address(this));

        // Unwrap native token
        _WETH.withdraw(amountReceived);

        // Send native token to user
        SafeTransferLib.safeTransferETH(recipient, amountReceived);

        // Emit request fulfilled event
        emit OnrampRequestFulFilled(bankingTxId, address(0), amountReceived);
    }

    /// @notice                 On-ramping a specific amount of USD to a token
    /// @param bankingTxId      The banking transaction ID that user made to deposit funds to Swype
    /// @param exchange         The address of the exchange to swap on
    /// @param swapData         The pre-compiled swap data to pass to the exchange
    /// @param amount           The amount of USD to on-ramp to token
    /// @param tokenOut         The token to receive after swap
    /// @param recipient        The recipient of the token
    /// @param signature        The signature from Swype that the banking transaction was valid
    function onrampTokenExactIn(
        string calldata bankingTxId,
        address exchange,
        bytes calldata swapData,
        uint256 amount,
        address tokenOut,
        address recipient,
        bytes calldata signature
    ) external whenNotPaused {
        bytes32 txHash = getTxHash(bankingTxId, tokenOut, amount, 0, recipient);
        _onrampChecks(bankingTxId, exchange, signature, txHash);

        _usedBankingTxIds[bankingTxId] = true;
        _executedHashes[txHash] = true;

        // Swap USDC to token
        uint256 amountReceived = _exactInSwap(exchange, swapData, address(_USDC), tokenOut, address(this));

        // Send the token to the user
        SafeTransferLib.safeTransfer(ERC20(tokenOut), recipient, amountReceived);

        // Emit request fulfilled event
        emit OnrampRequestFulFilled(bankingTxId, tokenOut, amount);
    }

    /// @notice                 On-ramping USD to a specific amount of a token
    /// @param bankingTxId      The banking transaction ID that user made to deposit funds to Swype
    /// @param exchange         The address of the exchange to swap on
    /// @param swapData         The pre-compiled swap data to pass to the exchange
    /// @param tokenOut         The token to receive after swap
    /// @param amountOut        The amount of token to on-ramp to
    /// @param recipient        The recipient of the token
    /// @param signature        The signature from Swype that the banking transaction was valid
    function onrampTokenExactOut(
        string calldata bankingTxId,
        address exchange,
        bytes calldata swapData,
        address tokenOut,
        uint256 amountOut,
        address recipient,
        bytes calldata signature
    ) external whenNotPaused {
        bytes32 txHash = getTxHash(bankingTxId, tokenOut, amountOut, 1, recipient);
        _onrampChecks(bankingTxId, exchange, signature, txHash);

        _usedBankingTxIds[bankingTxId] = true;
        _executedHashes[txHash] = true;

        // Swap USDC to token
        uint256 amountReceived = _exactOutSwap(exchange, swapData, tokenOut, amountOut, address(this));

        // Send the token to the user
        SafeTransferLib.safeTransfer(ERC20(tokenOut), recipient, amountReceived);

        // Emit request fulfilled event
        emit OnrampRequestFulFilled(bankingTxId, tokenOut, amountReceived);
    }

    /*********************************************************
     * OFFRAMP FUNCTIONS
     *********************************************************/

    /// @notice                 Off-ramp USDC to USD in a bank account
    /// @param uid              The swype user ID to off-ramp to
    /// @param usdcAmount       The amount of USDC to off-ramp
    function offrampUsdc(
        string calldata uid,
        uint256 usdcAmount
    ) external whenNotPaused {
        // Send USDC to Swype
        _USDC.safeTransferFrom(msg.sender, address(this), usdcAmount);

        // Emit successful off-ramp event
        emit OfframpRequest(uid, address(_USDC), usdcAmount, _amountAfterFee(usdcAmount));
    }

    /// @notice                 Off-ramp a chain's native token to USD in a bank account
    /// @param uid              The swype user ID to off-ramp to
    /// @param exchange         The address of the exchange to swap on
    /// @param swapData         The pre-compiled swap data to pass to the exchange
    /// @param amount           The amount of native token to off-ramp
    function offrampNativeExactIn(
        string calldata uid,
        address exchange,
        bytes calldata swapData,
        uint256 amount
    ) external payable whenNotPaused {
        // Check that exchange is approved
        if (!approvedExchanges[exchange]) revert UNAPPROVED_EXCHANGE();

        // Check that value sent in matches function argument
        if (msg.value != amount) revert INVALID_AMOUNT();

        // Wrap native token
        _WETH.deposit{value: amount}();

        // Swap wrapped native token to USDC
        uint256 amountOut = _exactInSwap(exchange, swapData, address(_WETH), address(_USDC), address(this));

        // Emit successful off-ramp event
        emit OfframpRequest(uid, address(_WETH), amount, _amountAfterFee(amountOut));
    }

    /// @notice                 Off-ramp a chain's native token to a specific amount of USD in a bank account
    /// @param uid              The swype user ID to off-ramp to
    /// @param exchange         The address of the exchange to swap on
    /// @param swapData         The pre-compiled swap data to pass to the exchange
    /// @param expectedAmountIn The expected amount of native token to off-ramp
    /// @param usdcAmountOut    The amount of USDC to swap to to off-ramp as USD
    function offrampNativeExactOut(
        string calldata uid,
        address exchange,
        bytes calldata swapData,
        uint256 expectedAmountIn,
        uint256 usdcAmountOut
    ) external payable whenNotPaused {
        // Check that exchange is approved
        if (!approvedExchanges[exchange]) revert UNAPPROVED_EXCHANGE();

        // Check that value sent in matches function argument
        if (msg.value != expectedAmountIn) revert INVALID_AMOUNT();

        // Wrap native token
        _WETH.deposit{value: expectedAmountIn}();

        // Cache WETH balance
        uint256 wethBalanceBefore = _WETH.balanceOf(address(this));

        // Swap wrapped native token to USDC
        uint256 amountOut = _exactOutSwap(exchange, swapData, address(_USDC), usdcAmountOut, address(this));

        // Return any excess WETH to user
        uint256 excessWeth;
        uint256 wethBalanceAfter = _WETH.balanceOf(address(this));
        if (wethBalanceAfter > wethBalanceBefore) {
            excessWeth = wethBalanceAfter - wethBalanceBefore;
            _WETH.withdraw(excessWeth);
            SafeTransferLib.safeTransferETH(msg.sender, excessWeth);
        }

        // Emit successful off-ramp event
        emit OfframpRequest(uid, address(_WETH), expectedAmountIn - excessWeth, _amountAfterFee(amountOut));
    }

    /// @notice                 Off-ramp a token to USD in a bank account
    /// @param uid              The swype user ID to off-ramp to
    /// @param exchange         The address of the exchange to swap on
    /// @param swapData         The pre-compiled swap data to pass to the exchange
    /// @param token            The token to off-ramp from
    /// @param amount           The amount of token to off-ramp
    function offrampTokenExactIn(
        string calldata uid,
        address exchange,
        bytes calldata swapData,
        address token,
        uint256 amount
    ) external whenNotPaused {
        // Check that exchange is approved
        if (!approvedExchanges[exchange]) revert UNAPPROVED_EXCHANGE();

        // Get token from user
        ERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Swap token to USDC
        ERC20(token).safeApprove(exchange, amount);
        uint256 amountOut = _exactInSwap(exchange, swapData, token, address(_USDC), address(this));

        // Emit successful off-ramp event
        emit OfframpRequest(uid, token, amount, _amountAfterFee(amountOut));
    }

    /// @notice                 Off-ramp a token to a specific amount of USD in a bank account
    /// @param uid              The swype user ID to off-ramp to
    /// @param exchange         The address of the exchange to swap on
    /// @param swapData         The pre-compiled swap data to pass to the exchange
    /// @param token            The token to off-ramp from
    /// @param expectedAmountIn The expected amount of token to off-ramp
    /// @param usdcAmountOut    The amount of USDC to swap to to off-ramp as USD
    function offrampTokenExactOut(
        string calldata uid,
        address exchange,
        bytes calldata swapData,
        address token,
        uint256 expectedAmountIn,
        uint256 usdcAmountOut
    ) external whenNotPaused {
        // Check that exchange is approved
        if (!approvedExchanges[exchange]) revert UNAPPROVED_EXCHANGE();

        // Get token from user
        ERC20(token).safeTransferFrom(msg.sender, address(this), expectedAmountIn);

        // Swap token to USDC
        ERC20(token).safeApprove(exchange, expectedAmountIn);
        uint256 amountOut = _exactOutSwap(exchange, swapData, address(_USDC), usdcAmountOut, address(this));

        // Return any excess token to user
        uint256 excessToken;
        uint256 tokenBalanceAfter = ERC20(token).balanceOf(address(this));
        if (tokenBalanceAfter > expectedAmountIn) {
            excessToken = tokenBalanceAfter - expectedAmountIn;
            ERC20(token).safeTransfer(msg.sender, excessToken);
        }

        // Emit successful off-ramp event
        emit OfframpRequest(uid, token, expectedAmountIn - excessToken, _amountAfterFee(amountOut));
    }

    /*********************************************************
     * VIEW FUNCTIONS
     *********************************************************/

    /// @dev We pass the recipient_ variable as well so that external callers can create hashes
    ///      for different users. i.e. Swype can create a hash to sign that includes a user's address
    function getTxHash(
        string calldata bankingTxId_,
        address token_,
        uint256 amount_,
        uint8 unit_,
        address recipient_
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), bankingTxId_, token_, amount_, unit_, recipient_));
    }

    /*********************************************************
     * ADMIN FUNCTIONS
     *********************************************************/

    /// @notice             Approves a new exchange address
    /// @param exchange     The address of the exchange to approve
    function approveExchange(address exchange) external whenNotPaused onlyOwner {
        approvedExchanges[exchange] = true;

        // Add approvals
        _USDC.approve(exchange, type(uint256).max);
        _WETH.approve(exchange, type(uint256).max);
        emit ExchangeApproved(exchange);
    }

    /// @notice             Removes an exchange address from the approved list
    /// @param exchange     The address of the exchange to remove
    function removeExchange(address exchange) external whenNotPaused onlyOwner {
        approvedExchanges[exchange] = false;

        // Remove approvals
        _USDC.approve(exchange, 0);
        _WETH.approve(exchange, 0);
        emit ExchangeRemoved(exchange);
    }

    /// @notice             Pauses the contract
    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    /// @notice             Unpauses the contract
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

    /// @notice             Sets the swype fee
    /// @param newFee       The new fee
    function setSwypeFee(uint24 newFee) external whenNotPaused onlyOwner {
        swypeFee = newFee;
        emit FeeChanged(newFee);
    }

    /// @notice             Sets the swype signer
    /// @param newSigner    The new signer
    function setSwypeSigner(address newSigner) external whenNotPaused onlyOwner {
        _swypeSigner = newSigner;
        emit SwypeSignerChanged(newSigner);
    }

    /// @notice             Withdraws ERC20 tokens from the contract
    /// @param token        The address of the token to withdraw
    /// @param amount       The amount of tokens to withdraw
    function withdrawERC20(address token, uint256 amount) external whenNotPaused onlyOwner {
        ERC20(token).safeTransfer(msg.sender, amount);
    }

    /// @notice             Withdraws ETH from the contract
    /// @param amount       The amount of ETH to withdraw
    function withdrawETH(uint256 amount) external whenNotPaused onlyOwner {
        SafeTransferLib.safeTransferETH(msg.sender, amount);
    }

    /*********************************************************
     * INTERNALS
     *********************************************************/

    function _onrampChecks(
        string calldata bankingTxId_,
        address exchange_,
        bytes calldata signature_,
        bytes32 txHash_
    ) internal view {
        if (_usedBankingTxIds[bankingTxId_]) revert BANKING_TX_ID_USED();
        if (!approvedExchanges[exchange_]) revert UNAPPROVED_EXCHANGE();
        if (_executedHashes[txHash_]) revert SIGNATURE_USED();
        if (!_verifySignature(txHash_, signature_)) revert INVALID_SIGNATURE();
    }

    function _amountAfterFee(uint256 amount_) internal view returns (uint256 result) {
        assembly {
            let fee := mul(amount_, sload(swypeFee.slot))
            let feeDiv := div(fee, 10000)
            result := sub(amount_, feeDiv)
        }
    }

    function _getApprovalMarginOfError(uint256 amount_) internal pure returns (uint256 marginOfError) {
        assembly {
            marginOfError := div(amount_, 1000)
        }
    }

    function _exactInSwap(
        address exchange_,
        bytes calldata swapData_,
        address tokenIn_,
        address tokenOut_,
        address recipient_
    ) internal returns (uint256) {
        // Cache token balances before
        uint256 tokenInBalanceBefore = ERC20(tokenIn_).balanceOf(address(this));
        uint256 tokenOutBalanceBefore = ERC20(tokenOut_).balanceOf(recipient_);

        // Execute swap
        (bool success, ) = exchange_.call(swapData_);
        if (!success) revert EXCHANGE_FAILED();

        // Cache token balances after
        uint256 tokenInSpent;
        uint256 tokenOutReceived;

        unchecked {
            tokenInSpent = tokenInBalanceBefore - ERC20(tokenIn_).balanceOf(address(this));
            tokenOutReceived = ERC20(tokenOut_).balanceOf(recipient_) - tokenOutBalanceBefore;
        }

        if (tokenInSpent == 0 || tokenOutReceived == 0) revert EXCHANGE_FAILED();

        // Return tokens received
        return tokenOutReceived;
    }

    function _exactOutSwap(
        address exchange_,
        bytes calldata swapData_,
        address tokenOut_,
        uint256 outputTokenAmount_,
        address recipient_
    ) internal returns (uint256) {
        // Cache token balances before
        uint256 tokenOutBalanceBefore = ERC20(tokenOut_).balanceOf(recipient_);

        // Execute swap
        (bool success, ) = exchange_.call(swapData_);
        if (!success) revert EXCHANGE_FAILED();

        uint256 amountOut;
        unchecked {
            amountOut = ERC20(tokenOut_).balanceOf(recipient_) - tokenOutBalanceBefore;
        }

        // Verify that the correct amount of tokens were received
        if (amountOut < outputTokenAmount_) revert EXCHANGE_FAILED();

        return amountOut; 
    }

    function _verifySignature(bytes32 txHash_, bytes memory signature_) internal view returns (bool) {
        bytes32 ethSignedMessageHash = txHash_.toEthSignedMessageHash();
        return ethSignedMessageHash.recover(signature_) == _swypeSigner;
    }

    function _authorizeUpgrade(address newImplementation_) internal override onlyOwner {}

    /*********************************************************
     * FALLBACK FUNCTIONS
     *********************************************************/

    /// @notice Fallback function to receive ETH
    receive() external payable {}

    /// @notice Fallback function to receive ETH
    fallback() external payable {}
}