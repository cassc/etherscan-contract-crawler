// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.7;

import "solmate/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IWidoRouter.sol";
import "./WidoTokenManager.sol";

error SlippageTooHigh(uint256 expectedAmount, uint256 actualAmount);

/// @title Wido Router
/// @notice Zap in or out of any ERC20 token, liquid or illiquid, in a single transaction.
/// @notice DO NOT APPROVE THIS CONTRACT FOR SPENDING YOUR TOKENS.
/// @author Wido
contract WidoRouter is IWidoRouter, Ownable, ReentrancyGuard {
    using SafeTransferLib for address;
    using SafeTransferLib for ERC20;

    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            abi.encodePacked("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
        );

    bytes32 private constant ORDER_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Order(OrderInput[] inputs,OrderOutput[] outputs,address user,uint32 nonce,uint32 expiration)OrderInput(address tokenAddress,uint256 amount)OrderOutput(address tokenAddress,uint256 minOutputAmount)"
            )
        );

    bytes32 private constant ORDER_INPUT_TYPEHASH =
        keccak256(abi.encodePacked("OrderInput(address tokenAddress,uint256 amount)"));

    bytes32 private constant ORDER_OUTPUT_TYPEHASH =
        keccak256(abi.encodePacked("OrderOutput(address tokenAddress,uint256 minOutputAmount)"));

    // Nonce for executing order with EIP-712 signatures.
    mapping(address => uint256) public nonces;

    // Address of the wrapped native token
    address public immutable wrappedNativeToken;

    // Address of fee bank
    address public bank;

    WidoTokenManager public immutable widoTokenManager;

    /// @notice Event emitted when the order is fulfilled
    /// @param order The order that was fulfilled
    /// @param sender The msg.sender
    /// @param recipient Recipient of the final tokens of the order
    /// @param feeBps Fee in basis points (bps)
    /// @param partner Partner address
    event FulfilledOrder(
        Order order,
        address indexed sender,
        address recipient,
        uint256 feeBps,
        address indexed partner
    );

    /// @notice Event emitted when the bank address is updated
    /// @param bank The updated address of the bank
    event SetBank(
        address bank
    );

    constructor(
        address _wrappedNativeToken,
        address _bank // uint256 _feeBps
    ) {
        require(_wrappedNativeToken != address(0) && _bank != address(0), "Addresses cannot be zero address");

        wrappedNativeToken = _wrappedNativeToken;
        bank = _bank;
        widoTokenManager = new WidoTokenManager();
    }

    /// @notice Sets the bank address
    /// @param _bank The address of the new bank
    function setBank(address _bank) external onlyOwner {
        require(_bank != address(0) && _bank != address(this), "Bank address cannot be zero address or Wido Router address");
        bank = _bank;
        emit SetBank(_bank);
    }

    /// @notice Approve a token spending
    /// @param token The ERC20 token to approve
    /// @param spender The address of the spender
    /// @param amount The minimum allowance to grant to the spender
    function _approveToken(address token, address spender, uint256 amount) internal {
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
        for (uint256 i = 0; i < route.length; ) {
            Step calldata step = route[i];

            require(step.targetAddress != address(widoTokenManager), "Wido: forbidden call to WidoTokenManager");

            uint256 balance;
            uint256 value;
            if (step.fromToken == address(0)) {
                value = address(this).balance;
                balance = value;
            } else {
                value = 0;
                balance = ERC20(step.fromToken).balanceOf(address(this));
                require(balance > 0, "Not enough balance for the step");
                _approveToken(step.fromToken, step.targetAddress, balance);
            }

            bytes memory editedSwapData;
            if (step.amountIndex >= 0) {
                uint256 idx = uint256(int256(step.amountIndex));
                editedSwapData = bytes.concat(step.data[:idx], abi.encode(balance), step.data[idx + 32:]);
            } else {
                editedSwapData = step.data;
            }

            (bool success, bytes memory result) = step.targetAddress.call{value: value}(editedSwapData);
            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            unchecked {
                i++;
            }
        }
    }

    function hash(OrderInput[] memory orderInput) internal pure returns (bytes32) {
        bytes32[] memory result = new bytes32[](orderInput.length);
        for (uint256 i = 0; i < orderInput.length; ) {
            result[i] = keccak256(abi.encode(ORDER_INPUT_TYPEHASH, orderInput[i]));
            unchecked {
                i++;
            }
        }
        return keccak256(abi.encodePacked(result));
    }

    function hash(OrderOutput[] memory orderOutput) internal pure returns (bytes32) {
        bytes32[] memory result = new bytes32[](orderOutput.length);
        for (uint256 i = 0; i < orderOutput.length; ) {
            result[i] = keccak256(abi.encode(ORDER_OUTPUT_TYPEHASH, orderOutput[i]));
            unchecked {
                i++;
            }
        }
        return keccak256(abi.encodePacked(result));
    }

    function hash(Order memory order) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ORDER_TYPEHASH,
                    hash(order.inputs),
                    hash(order.outputs),
                    order.user,
                    order.nonce,
                    order.expiration
                )
            );
    }

    /// @notice Verifies if the order is valid
    /// @param order Order to be validated
    /// @param v v of the signature
    /// @param r r of the signature
    /// @param s s of the signature
    /// @return bool True if the order is valid
    function verifyOrder(Order calldata order, uint8 v, bytes32 r, bytes32 s) public view override returns (bool) {
        bytes32 DOMAIN_SEPARATOR = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256("WidoRouter"), keccak256("1"), block.chainid, address(this))
        );
        address recoveredAddress = ECDSA.recover(
            keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, hash(order))),
            v,
            r,
            s
        );
        require(recoveredAddress != address(0) && order.user == recoveredAddress, "Invalid signature");
        require(order.nonce == nonces[order.user], "Invalid nonce");
        require(order.expiration == 0 || block.timestamp <= order.expiration, "Expired request");
        for (uint256 i = 0; i < order.inputs.length; ) {
            IWidoRouter.OrderInput calldata input = order.inputs[i];
            require(input.amount > 0, "Amount should be greater than 0");
            unchecked {
                i++;
            }
        }
        return true;
    }

    /// @notice Executes the validated order
    /// @param order Order to be executed
    /// @param route Route to execute for the token swap
    /// @param recipient The address of the final token receiver
    /// @param feeBps Fee in basis points (bps)
    /// @dev Expects the steps in the route to transform order.fromToken to order.toToken
    /// @dev Expects at least order.minToTokenAmount to be transferred to the recipient
    function _executeOrder(Order calldata order, Step[] calldata route, address recipient, uint256 feeBps) private {
        widoTokenManager.pullTokens(order.user, order.inputs);

        for (uint256 i = 0; i < order.inputs.length; ) {
            IWidoRouter.OrderInput calldata input = order.inputs[i];

            uint256 balance;
            if (input.tokenAddress == address(0)) {
                balance = address(this).balance;
            } else {
                balance = ERC20(input.tokenAddress).balanceOf(address(this));
            }
            require(balance >= input.amount, "Balance lower than order amount");
            _collectFees(input.tokenAddress, balance, feeBps);

            unchecked {
                i++;
            }
        }

        _executeSteps(route);

        for (uint256 i = 0; i < order.outputs.length; ) {
            IWidoRouter.OrderOutput calldata output = order.outputs[i];

            if (output.tokenAddress == address(0)) {
                uint256 balance = address(this).balance;
                if (balance < output.minOutputAmount) {
                    revert SlippageTooHigh(output.minOutputAmount, balance);
                }
                recipient.safeTransferETH(balance);
            } else {
                uint256 balance = ERC20(output.tokenAddress).balanceOf(address(this));
                if (balance < output.minOutputAmount) {
                    revert SlippageTooHigh(output.minOutputAmount, balance);
                }
                ERC20(output.tokenAddress).safeTransfer(recipient, balance);
            }

            unchecked {
                i++;
            }
        }
    }

    /// @notice Returns the amount of tokens or native tokens after accounting for fee
    /// @param fromToken Address of the token for the fee
    /// @param amount Amount of tokens to subtract the fee
    /// @param feeBps Fee in basis points (bps)
    /// @dev Sends the fee to the bank to not maintain any balance in the contract
    function _collectFees(address fromToken, uint256 amount, uint256 feeBps) private {
        require(feeBps <= 100, "Fee out of range");
        uint256 fee = (amount * feeBps) / 10000;
        if (fee > 0) {
            if (fromToken == address(0)) {
                bank.safeTransferETH(fee);
            } else {
                ERC20(fromToken).safeTransfer(bank, fee);
            }
        }
    }

    /// @notice Executes order to transform ERC20 token from order.fromToken to order.toToken
    /// @param order Order describing the expectation of the token transformation
    /// @param route Route describes the details of the token transformation
    /// @param feeBps Fee in basis points (bps)
    /// @param partner Partner address
    function executeOrder(
        Order calldata order,
        Step[] calldata route,
        uint256 feeBps,
        address partner
    ) external payable override nonReentrant {
        require(msg.sender == order.user, "Invalid order user");
        _executeOrder(order, route, order.user, feeBps);
        emit FulfilledOrder(order, msg.sender, order.user, feeBps, partner);
    }

    /// @notice Executes order to transform ERC20 token from order.fromToken to order.toToken
    /// @param order Order describing the expectation of the token transformation
    /// @param route Route describes the details of the token transformation
    /// @param recipient Destination address where the final tokens are sent
    /// @param feeBps Fee in basis points (bps)
    /// @param partner Partner address
    function executeOrder(
        Order calldata order,
        Step[] calldata route,
        address recipient,
        uint256 feeBps,
        address partner
    ) external payable override nonReentrant {
        require(msg.sender == order.user, "Invalid order user");
        _executeOrder(order, route, recipient, feeBps);
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
    function executeOrderWithSignature(
        Order calldata order,
        Step[] calldata route,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 feeBps,
        address partner
    ) external override nonReentrant {
        require(verifyOrder(order, v, r, s), "Invalid order");
        nonces[order.user]++;
        _executeOrder(order, route, order.user, feeBps);
        emit FulfilledOrder(order, msg.sender, order.user, feeBps, partner);
    }

    /// @notice Allow receiving of native tokens
    receive() external payable {}
}