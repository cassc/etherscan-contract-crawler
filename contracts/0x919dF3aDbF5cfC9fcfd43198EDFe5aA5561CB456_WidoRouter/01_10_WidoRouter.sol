// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;

import "solmate/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@uniswap/v3-core/contracts/libraries/LowGasSafeMath.sol";
import "./interfaces/IWidoRouter.sol";
import "./interfaces/IWETH.sol";

error SlippageTooHigh(uint256 expectedAmount, uint256 actualAmount);

/// @title Wido Router
/// @notice Zap in or out of any ERC20 token, liquid or illiquid, in a single transaction.
/// @author Wido
contract WidoRouter is IWidoRouter, Ownable {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;
    using LowGasSafeMath for uint256;

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            abi.encodePacked("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
        );

    bytes32 private constant ORDER_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Order(address user,address fromToken,address toToken,uint256 fromTokenAmount,uint256 minToTokenAmount,uint32 nonce,uint32 expiration)"
            )
        );

    bytes32 public immutable DOMAIN_SEPARATOR;

    // Nonce for executing order with EIP-712 signatures.
    mapping(address => uint256) public nonces;

    // Address of the wrapped native token
    address public immutable wrappedNativeToken;

    // Address of fee bank
    address public bank;

    /// @notice Event emitted when the order is fulfilled
    /// @param order The order that was fulfilled
    /// @param recipient Recipient of the final tokens of the order
    /// @param sender The msg.sender
    /// @param feeBps Fee in basis points (bps)
    /// @param partner Partner address
    event FulfilledOrder(
        Order order,
        address recipient,
        address indexed sender,
        uint256 feeBps,
        address indexed partner
    );

    constructor(
        address _wrappedNativeToken,
        address _bank // uint256 _feeBps
    ) {
        require(_wrappedNativeToken != address(0) && _bank != address(0), "Addresses cannot be zero address");

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256("WidoRouter"), keccak256("1"), block.chainid, address(this))
        );

        wrappedNativeToken = _wrappedNativeToken;
        bank = _bank;
    }

    /// @notice Sets the bank address
    /// @param _bank The address of the new bank
    function setBank(address _bank) external onlyOwner {
        require(_bank != address(0), "Bank address cannot be zero address");
        bank = _bank;
    }

    /// @notice Transfers tokens or native tokens from the user
    /// @param user The address of the order user
    /// @param token The address of the token to transfer (address(0) for native token)
    /// @param amount The amount if tokens to transfer from the user
    /// @dev amount must == msg.value when token == address(0)
    /// @return uint256 The amount of tokens or native tokens transferred from the user to this contract
    function _pullTokens(
        address user,
        address token,
        uint256 amount
    ) internal returns (uint256) {
        if (token == address(0)) {
            require(msg.value > 0 && msg.value == amount, "Invalid amount or msg.value");
            return msg.value;
        }
        ERC20(token).safeTransferFrom(user, address(this), amount);
        return amount;
    }

    /// @notice Approve a token spending
    /// @param token The ERC20 token to approve
    /// @param spender The address of the spender
    /// @param amount The minimum allowance to grant to the spender
    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        ERC20 _token = ERC20(token);
        if (_token.allowance(address(this), spender) < amount) {
            _token.safeApprove(spender, type(uint256).max);
        }
    }

    /// @notice Executes steps in the route to transfer to token
    /// @param route Step data for token transformation
    /// @dev Updates the amount in the byte data with the current balance as to not leave any dust
    /// @dev Expects step data to be properly chained for the token transformation tokenA -> tokenB -> tokenC
    function _executeSteps(Step[] calldata route) private {
        for (uint256 i = 0; i < route.length; i++) {
            Step calldata step = route[i];

            uint256 balance = ERC20(step.fromToken).balanceOf(address(this));
            require(balance > 0, "Not enough balance for the step");
            _approveToken(step.fromToken, step.targetAddress, balance);

            bytes memory editedSwapData;
            if (step.amountIndex >= 0) {
                uint256 idx = uint256(int256(step.amountIndex));
                editedSwapData = bytes.concat(step.data[:idx], abi.encode(balance), step.data[idx + 32:]);
            } else {
                editedSwapData = step.data;
            }

            (bool success, bytes memory result) = step.targetAddress.call(editedSwapData);
            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }
        }
    }

    /// @notice Verifies if the order is valid
    /// @param order Order to be validated
    /// @param v v of the signature
    /// @param r r of the signature
    /// @param s s of the signature
    /// @return bool True if the order is valid
    function verifyOrder(
        Order calldata order,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view override returns (bool) {
        address recoveredAddress = ECDSA.recover(
            keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(ORDER_TYPEHASH, order)))),
            v,
            r,
            s
        );
        require(recoveredAddress != address(0) && order.user == recoveredAddress, "Invalid signature");
        require(order.nonce == nonces[order.user], "Invalid nonce");
        require(order.expiration == 0 || block.timestamp <= order.expiration, "Expired request");
        require(order.fromTokenAmount > 0, "Amount should be greater than 0");
        return true;
    }

    /// @notice Executes the validated order
    /// @param order Order to be executed
    /// @param route Route to execute for the token swap
    /// @param recipient The address of the final token receiver
    /// @param feeBps Fee in basis points (bps)
    /// @return toTokenBalance The final token balance sent to the recipient
    /// @dev Expects the steps in the route to transform order.fromToken to order.toToken
    /// @dev Expects at least order.minToTokenAmount to be transferred to the recipient
    function _executeOrder(
        Order calldata order,
        Step[] calldata route,
        address recipient,
        uint256 feeBps
    ) private returns (uint256 toTokenBalance) {
        _pullTokens(order.user, order.fromToken, order.fromTokenAmount);

        if (order.fromToken == address(0)) {
            IWETH(wrappedNativeToken).deposit{value: order.fromTokenAmount}();
            _collectFees(wrappedNativeToken, order.fromTokenAmount, feeBps);
        } else {
            uint256 fromTokenBalance = ERC20(order.fromToken).balanceOf(address(this));
            require(fromTokenBalance >= order.fromTokenAmount, "Balance lower than order amount");
            _collectFees(order.fromToken, fromTokenBalance, feeBps);
        }

        _executeSteps(route);

        if (order.toToken == address(0)) {
            toTokenBalance = ERC20(wrappedNativeToken).balanceOf(address(this));
            IWETH(wrappedNativeToken).withdraw(toTokenBalance);
        } else {
            toTokenBalance = ERC20(order.toToken).balanceOf(address(this));
        }
        if (toTokenBalance < order.minToTokenAmount) revert SlippageTooHigh(order.minToTokenAmount, toTokenBalance);

        if (order.toToken == address(0)) {
            recipient.safeTransferETH(toTokenBalance);
        } else {
            ERC20(order.toToken).safeTransfer(recipient, toTokenBalance);
        }
    }

    /// @notice Returns the amount of tokens or native tokens after accounting for fee
    /// @param fromToken Address of the token for the fee
    /// @param amount Amount of tokens to subtract the fee
    /// @param feeBps Fee in basis points (bps)
    /// @return uint256 The amount of token or native tokens for the order less the fee
    /// @dev Sends the fee to the bank to not maintain any balance in the contract
    /// @dev Does not charge fee if the input or final token is in the fee whitelist
    function _collectFees(
        address fromToken,
        uint256 amount,
        uint256 feeBps
    ) private returns (uint256) {
        require(feeBps <= 100, "Fee out of range");
        uint256 fee = amount.mul(feeBps) / 10000;
        ERC20(fromToken).safeTransfer(bank, fee);
        return amount - fee;
    }

    /// @notice Executes order to transform ERC20 token from order.fromToken to order.toToken
    /// @param order Order describing the expectation of the token transformation
    /// @param route Route describes the details of the token transformation
    /// @param feeBps Fee in basis points (bps)
    /// @param partner Partner address
    /// @return toTokenBalance Amount of the to token that resulted from executing the order
    function executeOrder(
        Order calldata order,
        Step[] calldata route,
        uint256 feeBps,
        address partner
    ) external payable override returns (uint256 toTokenBalance) {
        require(msg.sender == order.user, "Invalid order user");
        toTokenBalance = _executeOrder(order, route, order.user, feeBps);
        emit FulfilledOrder(order, msg.sender, order.user, feeBps, partner);
    }

    /// @notice Executes order to transform ERC20 token from order.fromToken to order.toToken
    /// @param order Order describing the expectation of the token transformation
    /// @param route Route describes the details of the token transformation
    /// @param recipient Destination address where the final tokens are sent
    /// @param feeBps Fee in basis points (bps)
    /// @param partner Partner address
    /// @return toTokenBalance Amount of the to token that resulted from executing the order
    function executeOrder(
        Order calldata order,
        Step[] calldata route,
        address recipient,
        uint256 feeBps,
        address partner
    ) external payable override returns (uint256 toTokenBalance) {
        require(msg.sender == order.user, "Invalid order user");
        toTokenBalance = _executeOrder(order, route, recipient, feeBps);
        emit FulfilledOrder(order, msg.sender, recipient, feeBps, partner);
    }

    /// @notice Executes the order with valid EIP-712 signature
    /// @param order Order describing the expectation of the token transformation
    /// @param route Expects a valid route to transform order.fromToken to order.toToken
    /// @param v v of the signature
    /// @param r r of the signature
    /// @param s s of the signation
    /// @param feeBps Fee in basis points (bps)
    /// @param partner Partner address
    /// @return toTokenBalance Amount of the to token that resulted from executing the order
    function executeOrderWithSignature(
        Order calldata order,
        Step[] calldata route,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 feeBps,
        address partner
    ) external override returns (uint256 toTokenBalance) {
        require(verifyOrder(order, v, r, s), "Invalid order");
        nonces[order.user]++;
        toTokenBalance = _executeOrder(order, route, order.user, feeBps);
        emit FulfilledOrder(order, msg.sender, order.user, feeBps, partner);
    }

    /// @notice Reverts if the native tokens are sent directly to the contract
    receive() external payable {
        require(msg.sender == wrappedNativeToken);
    }
}