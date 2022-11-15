// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC1155Receiver.sol";
import "./IMultichainPortal.sol";
import "./ERC721Receiver.sol";
import "../external/Library.sol";
import "../external/IStargateReceiver.sol";
import "../external/IStargateRouter.sol";


// solhint-disable avoid-low-level-calls
error NotFromRouter();
contract MultichainPortal is
    IMultichainPortal,
    Initializable,
    Pausable,
    Ownable,
    ERC721Receiver,
    ERC1155Receiver,
    IStargateReceiver
{
    using SafeERC20 for IERC20;

    uint256 public fee;
    address public beneficiary;
    address public portalRouter;
    address public usdc;
    uint16 public lastChainId;
	bytes public lastSrcAddress;
	uint256 public lastNonce;
    address public stargateRouter;
    string public lastErr;

    event SwapCallError(string reason);

    function initialize(
        address _portalRouter,
        address _stargateRouter,
        address _beneficiary,
        address _usdc,
        uint256 _fee
    ) external initializer {
        portalRouter = _portalRouter;
        stargateRouter = _stargateRouter;
        beneficiary = _beneficiary;
        usdc = _usdc;
        fee = _fee;
    }

    receive() external payable {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /// @dev called by Stargate on destination chain
    function sgReceive(
        uint16 _chainId,
        bytes memory _srcAddress,
        uint256 _nonce,
        address _token,
        uint256 amountLD,
        bytes calldata payload
    ) external override {
		if (msg.sender != stargateRouter) revert NotFromRouter();
        
        lastChainId = _chainId;
		lastSrcAddress = _srcAddress;
		lastNonce = _nonce;
        
        _processRequest(_token, amountLD, payload);
	}

    /// @dev swaps erc20 tokens on source chain into usdc and sends to stargate
    function swapERC20AndSend(
        uint amountIn,
        uint amountUSDC,
        address user,
        address tokenIn,
        address swapRouter,
        bytes calldata swapArguments,
        IMultichainPortal.StargateArgs memory stargateArgs
    ) external payable override whenNotPaused {
        require(msg.value > 0, "stargate requires a msg.value to pay crosschain message"); //TODO: modifiers
        require(amountIn > 0, "error: swap() requires qty > 0");

        // if swaprouter address in address(0), assume tokenIn is usdc and do not swap
        IERC20 _tokenIn = IERC20(tokenIn);
        uint256 initialBalance = _tokenIn.balanceOf(address(this));
        if (swapRouter != address(0)) {
            _swapERC20(tokenIn, amountIn, user, swapRouter, swapArguments, initialBalance);
        }

        this.send{value:msg.value}(
            amountUSDC,
            stargateArgs.dstChainId,
            stargateArgs.srcPoolId,
            stargateArgs.dstPoolId,
            stargateArgs.minAmountOut,
            stargateArgs.lzTxObj,
            stargateArgs.receiver,
            stargateArgs.data
        );
    }

    /// @dev swaps native tokens on source chain into usdc and sends to stargate
    function swapNativeAndSend(
        uint amountIn,
        uint amountUSDC,
        uint lzFee,
        address user,
        address swapRouter,
        bytes calldata swapArguments,
        IMultichainPortal.StargateArgs memory stargateArgs
    ) external payable override whenNotPaused {
        require(msg.value > amountIn, "stargate requires a msg.value to pay crosschain message");
        require(amountIn > 0, "error: swap() requires qty > 0");

        // if swaprouter address in address(0), assume tokenIn is usdc and do not swap
        uint256 initialBalance = address(this).balance;
        if (swapRouter != address(0)) {
            (bool successfulSwap, bytes memory result) = swapRouter.call{value: amountIn}(
                swapArguments
            );

            if (!successfulSwap) {
                _extractReasonString(result);
            }
 
            uint256 swapCost = initialBalance - address(this).balance;
            uint256 overpayment = msg.value - swapCost - lzFee;

            (bool successfulReimbursement, ) = user.call{value: overpayment}("");
            require(successfulReimbursement, "reimbursement failed");
        }

        this.send{value:lzFee}(
            amountUSDC,
            stargateArgs.dstChainId,
            stargateArgs.srcPoolId,
            stargateArgs.dstPoolId,
            stargateArgs.minAmountOut,
            stargateArgs.lzTxObj,
            stargateArgs.receiver,
            stargateArgs.data
        );

    }

    /// @param qty The number of tokens to send
    /// @param dstChainId the destination chain id
    /// @param srcPoolId the source Stargate poolId
    /// @param dstPoolId the destination Stargate poolId 
    /// @param minAmountOut minimum amount of tokens allowed out
    /// @param lzTxObj the layer zero transaction object 
    /// @param receiver destination address, the sgReceive() implementer
    /// @param data The bytes containing the payload
    function send(
        uint qty,
        uint16 dstChainId,
        uint16 srcPoolId,
        uint16 dstPoolId,
        uint256 minAmountOut,
        IStargateRouter.lzTxObj memory lzTxObj,
        address receiver,
        bytes calldata data
    ) external payable {
        require(msg.sender == address(this), "can only be called by portal");
        require(msg.value > 0, "stargate requires a msg.value to pay crosschain message");
        require(qty > 0, "error: swap() requires qty > 0");

        
        (uint256 brydgeFee, uint256 postFeeAmountIn) = _calculateFee(qty);
        IERC20(usdc).safeTransfer(beneficiary, brydgeFee);

        IERC20(usdc).approve(address(stargateRouter), postFeeAmountIn);

        // Stargate's Router.swap() function sends the tokens to the destination chain.
        IStargateRouter(stargateRouter).swap{value:msg.value}(
            dstChainId,
            srcPoolId,
            dstPoolId,
            payable(beneficiary),                            // TODO: refund to user, not to beneficiary
            postFeeAmountIn,
            minAmountOut,
            lzTxObj,
            abi.encodePacked(receiver),
            data
        );
    }

    /// @dev decodes arguments and executes rawRequestData on destination chain
    function _processRequest(address _token, uint256 amountLD, bytes calldata rawRequestData) internal {
        (
            address user,
            address tokenOut,
            address swapRouter, // swap contract address
            bytes memory swapArguments, // swap contract arguments
            Types.ICall[] memory calls // call list
        ) = abi.decode(rawRequestData, (address, address, address, bytes, Types.ICall[]));

        try
            this.swapERC20AndCall(_token, tokenOut, amountLD, user, swapRouter, swapArguments, calls)
        {} catch Error(string memory reason) {
            // This is executed in case
            // revert was called inside getData
            // and a reason string was provided.
            emit SwapCallError(reason);
            lastErr = reason;
            IERC20(_token).safeTransfer(user, amountLD);
        } catch (bytes memory reason) {
            // This is executed in case revert() was used
            // or there was a failing assertion, division
            // by zero, etc. inside getData.
            if (reason.length < 68) emit SwapCallError("unknown error");
            // solhint-disable-next-line no-inline-assembly
            assembly {
                reason := add(reason, 0x04)
            }
            emit SwapCallError(abi.decode(reason, (string)));
            lastErr = abi.decode(reason, (string));
            IERC20(_token).safeTransfer(user, amountLD);
        }
        
    }

    /// @dev swap Native token for desired output token and execute calls on destination chain
    function swapNativeAndCall(
        address tokenOut,
        address user,
        address swapRouter,
        bytes calldata swapArguments,
        Types.ICall[] calldata calls
    ) external payable whenNotPaused {
        if (msg.sender != portalRouter && msg.sender != address(this)) {
            revert("Cannot be called directly");
        }

        IERC20 token = IERC20(tokenOut);
        uint256 initialOutBalance;
        if (tokenOut != address(0)) {
            initialOutBalance = token.balanceOf(address(this));
        } else {
            // Native token output
            initialOutBalance = address(this).balance;
        }

        uint256 initialBalance = address(this).balance;
        (uint256 brydgeFee, uint256 postFeeAmountIn) = _calculateFee(msg.value);
        (bool successfulFeePayment, ) = beneficiary.call{value: brydgeFee}("");
        require(successfulFeePayment, "Brydge fee payment failed");

        if (swapRouter != address(0)) {
            (bool successfulSwap, bytes memory result) = swapRouter.call{value: postFeeAmountIn}(
                swapArguments
            );

            if (!successfulSwap) {
                revert(_extractReasonString(result));
            }

            uint256 swapCost = initialBalance - address(this).balance;
            if (msg.value > swapCost) {
                (bool successfulReimbursement, ) = user.call{value: msg.value-swapCost}("");
                require(successfulReimbursement, "reimbursement failed");
            }
        }

        _handleCalls(calls);

        /// send any remaining tokens back to the user
        if (tokenOut != address(0)) {
            if (token.balanceOf(address(this)) > initialOutBalance) {
                token.safeTransfer(user, token.balanceOf(address(this)) - initialOutBalance);
            }
        } else {
            // Native token output
            if (address(this).balance > initialOutBalance) {
                (bool success, ) = user.call{value: address(this).balance - initialOutBalance}("");
                require(success, "reimbursement failed");
            }
        }
    }

    /// @dev swap erc20 for desired output token and execute calls on destination chain
    function swapERC20AndCall(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address user,
        address swapRouter,
        bytes calldata swapArguments,
        Types.ICall[] calldata calls
    ) external virtual whenNotPaused {
        if (msg.sender != portalRouter && msg.sender != address(this)) {
            revert("Cannot be called directly");
        }

        IERC20 token = IERC20(tokenOut);
        uint256 initialBalance;
        if (tokenOut == tokenIn) {
            initialBalance = token.balanceOf(address(this)) - amountIn;
        } else if (tokenOut != address(0)) {
            initialBalance = token.balanceOf(address(this));
        } else {
            // Native token output
            initialBalance = address(this).balance;
        }

        IERC20 _tokenIn = IERC20(tokenIn);
        uint256 inTokenBalance = _tokenIn.balanceOf(address(this));
        (uint256 brydgeFee,) = _calculateFee(amountIn);
        if (msg.sender != address(this)) { //not from stargate
            _tokenIn.safeTransfer(beneficiary, brydgeFee);
        }

        if (swapRouter != address(0)) {
            _swapERC20(tokenIn, amountIn, user, swapRouter, swapArguments, inTokenBalance);
        }

        _handleCalls(calls);

        /// send any remaining tokens back to the user
        if (tokenOut != address(0)) {
            if (token.balanceOf(address(this)) > initialBalance) {
                token.safeTransfer(user, token.balanceOf(address(this)) - initialBalance);
            }
        } else {
            // Native token output
            if (address(this).balance > initialBalance) {
                (bool success, ) = user.call{value: address(this).balance - initialBalance}("");
                require(success, "reimbursement failed");
            }
        }
    }

    function _handleCalls(Types.ICall[] calldata calls) internal {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory reason) = calls[i]._to.call{value: calls[i]._value}(
                calls[i]._calldata
            );

            if (!success) {
                revert(_extractReasonString(reason));
            }
        }
    }

    function _swapERC20(
        address tokenIn,
        uint256 amountIn,
        address user,
        address swapRouter,
        bytes calldata swapArguments,
        uint256 initialBalance
    ) internal {
        IERC20 token = IERC20(tokenIn);        
        _handleERC20Approval(tokenIn, swapRouter, amountIn);
        (bool successfulSwap, bytes memory result) = swapRouter.call(swapArguments);

        if (!successfulSwap) {
            revert(_extractReasonString(result));
        }

        uint256 swapCost = initialBalance - token.balanceOf(address(this));
        if (amountIn > swapCost) {
            token.safeTransfer(user, amountIn - swapCost);
        }
    }

    function _handleERC20Approval(
        address token,
        address operator,
        uint256 amount
    ) internal {
        if (IERC20(token).allowance(address(this), operator) < amount) {
            IERC20(token).approve(
                operator,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        }
    }

    function _calculateFee(uint256 amountIn) internal view returns (uint256, uint256) {
        uint256 brydgeFee = mulDiv(amountIn, fee, 1000);
        uint256 postFeeAmountIn = amountIn - brydgeFee;
        return (brydgeFee, postFeeAmountIn);
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        uint256 a = x / z;
        uint256 b = x % z; // x = a * z + b
        uint256 c = y / z;
        uint256 d = y % z; // y = c * z + d
        return a * c * z + a * d + b * c + (b * d) / z;
    }

    function _extractReasonString(bytes memory reason) internal pure returns (string memory) {
        if (reason.length < 68) return "swap failed";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            reason := add(reason, 0x04)
        }
        return abi.decode(reason, (string));
    }
}