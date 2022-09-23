// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;
import "../IERC20.sol";
import "@uniswap/v3-periphery/contracts/libraries/Path.sol";
import "../trade_utils.sol";

interface ISwapRouter2 {
	/// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
	/// @dev The `msg.value` should not be trusted for any method callable from multicall.
	/// @param deadline The time by which this function must be called before failing
	/// @param data The encoded function data for each of the calls to make to this contract
	/// @return results The results from each of the calls passed in via data
	function multicall(uint256 deadline, bytes[] calldata data) external payable returns (bytes[] memory results);

	/// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
	/// @dev The `msg.value` should not be trusted for any method callable from multicall.
	/// @param previousBlockhash The expected parent blockHash
	/// @param data The encoded function data for each of the calls to make to this contract
	/// @return results The results from each of the calls passed in via data
	// function multicall(bytes32 previousBlockhash, bytes[] calldata data)
	// external
	// payable
	// returns (bytes[] memory results);
	struct ExactInputSingleParams {
		address tokenIn;
		address tokenOut;
		uint24 fee;
		address recipient;
		uint256 amountIn;
		uint256 amountOutMinimum;
		uint160 sqrtPriceLimitX96;
	}

	/// @notice Swaps `amountIn` of one token for as much as possible of another token
	/// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
	/// @return amountOut The amount of the received token
	function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

	struct ExactInputParams {
		bytes path;
		address recipient;
		uint256 amountIn;
		uint256 amountOutMinimum;
	}

	/// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
	/// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
	/// @return amountOut The amount of the received token
	function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);
	function WETH9() external returns(address);
}

interface Wmatic is IERC20 {
	function withdraw(uint256 amount) external;
}

contract UniswapProxy is Executor {
	using Path for bytes;
	// Variables
	address constant public ETH_CONTRACT_ADDRESS = 0x0000000000000000000000000000000000000000;
	uint constant public MAX = uint(-1);
	ISwapRouter2 public swaprouter02;
	Wmatic public wmatic;

	struct CallSummary {
		address to;
		address token;
		uint256 amount;
		bytes data;
	}

	/**
     * @dev Contract constructor
     * @param _swaproute02 uniswap routes contract address
     */
	constructor(ISwapRouter2 _swaproute02) payable {
		swaprouter02 = _swaproute02;
		wmatic = Wmatic(swaprouter02.WETH9());
	}

	function tradeInputSingle(ISwapRouter2.ExactInputSingleParams calldata params, bool isNative) external payable returns(address, uint) {
		checkApproved(IERC20(params.tokenIn), params.amountIn);
		uint amountOut = swaprouter02.exactInputSingle{value: msg.value}(params);
		require(amountOut >= params.amountOutMinimum, "lower than expected output");
		address returnToken = withdrawMatic(params.tokenOut, amountOut, isNative);
		return (returnToken, amountOut);
	}

	function tradeInput(ISwapRouter2.ExactInputParams calldata params, bool isNative) external payable returns(address, uint) {
		(address tokenIn,,) = params.path.decodeFirstPool();
		checkApproved(IERC20(tokenIn), params.amountIn);
		uint amountOut = swaprouter02.exactInput{value: msg.value}(params);
		bytes memory tempPath = params.path;
		address returnToken;
		while (true) {
			bool hasMultiplePools = tempPath.hasMultiplePools();
			// decide whether to continue or terminate
			if (hasMultiplePools) {
				tempPath = tempPath.skipToken();
			} else {
				(,returnToken,) = tempPath.decodeFirstPool();
				break;
			}
		}
		returnToken = withdrawMatic(returnToken, amountOut, isNative);
		return (returnToken, amountOut);
	}

	function multiTrades(uint256 deadline, bytes[] calldata data, IERC20 sellToken, address buyToken, uint256 sellAmount, bool isNative) external payable returns(address, uint) {
		checkApproved(sellToken, sellAmount);
		uint256 amountOut;
		bytes[] memory results = swaprouter02.multicall{value: msg.value}(deadline, data);
		for (uint i = 0; i < results.length; i++) {
			amountOut += abi.decode(results[i], (uint256));
		}
		address returnToken = withdrawMatic(buyToken, amountOut, isNative);

		return (returnToken, amountOut);
	}

	function _inspectTradeInputSingle(ISwapRouter2.ExactInputSingleParams calldata params, bool isNative) external view returns (bytes memory, CallSummary memory) {
		bytes memory rdata = abi.encodeWithSelector(0x421f4388, params, isNative);
		CallSummary memory cs = CallSummary(address(swaprouter02), params.tokenIn, params.amountIn,
			abi.encodeWithSelector(0x04e45aaf, params)
		);
		return (rdata, cs);
	}

	function _inspectTradeInput(ISwapRouter2.ExactInputParams calldata params, bool isNative) external view returns(bytes memory, CallSummary memory) {
		(address tokenIn,,) = params.path.decodeFirstPool();
		bytes memory rdata = abi.encodeWithSelector(0xc8dc75e6, params, isNative);
		CallSummary memory cs = CallSummary(address(swaprouter02), tokenIn, params.amountIn,
			abi.encodeWithSelector(0xb858183f, params)
		);
		return (rdata, cs);
	}

	function _inspectMultiTrades(uint256 deadline, bytes[] calldata data, IERC20 sellToken, address buyToken, uint256 sellAmount, bool isNative) external view returns (bytes memory, CallSummary memory) {
		bytes memory rdata = abi.encodeWithSelector(0x92171fd8, block.timestamp + 1000000000, data, sellToken, buyToken, sellAmount, isNative);
		CallSummary memory cs = CallSummary(address(swaprouter02), address(sellToken), sellAmount,
			abi.encodeWithSelector(0x5ae401dc, block.timestamp + 1000000000, data)
		);
		return (rdata, cs);
	}

	function checkApproved(IERC20 srcToken, uint256 amount) internal {
		if (msg.value == 0 && srcToken.allowance(address(this), address(swaprouter02)) < amount) {
			srcToken.approve(address(swaprouter02), MAX);
		}
	}

	function withdrawMatic(address tokenOut, uint256 amountOut, bool isNative) internal returns(address returnToken) {
		if (tokenOut == address(wmatic) && isNative) {
			// convert wmatic to matic
			// recipient in params must be this contract
			wmatic.withdraw(amountOut);
			returnToken = ETH_CONTRACT_ADDRESS;
			transfer(returnToken, amountOut);
		} else {
			returnToken = tokenOut;
		}
	}

	function transfer(address token, uint amount) internal {
		if (token == ETH_CONTRACT_ADDRESS) {
			require(address(this).balance >= amount, "IUP: transfer amount exceeds balance");
			(bool success, ) = msg.sender.call{value: amount}("");
			require(success, "IUP: transfer failed");
		} else {
			IERC20(token).transfer(msg.sender, amount);
			require(checkSuccess(), "IUP: transfer token failed");
		}
	}

	/**
     * @dev Check if transfer() and transferFrom() of ERC20 succeeded or not
     * This check is needed to fix https://github.com/ethereum/solidity/issues/4116
     * This function is copied from https://github.com/AdExNetwork/adex-protocol-eth/blob/master/contracts/libs/SafeERC20.sol
     */
	function checkSuccess() internal pure returns (bool) {
		uint256 returnValue = 0;

		assembly {
		// check number of bytes returned from last function call
			switch returndatasize()

			// no bytes returned: assume success
			case 0x0 {
				returnValue := 1
			}

			// 32 bytes returned: check if non-zero
			case 0x20 {
			// copy 32 bytes into scratch space
				returndatacopy(0x0, 0x0, 0x20)

			// load those bytes into returnValue
				returnValue := mload(0x0)
			}

			// not sure what was returned: don't mark as success
			default { }
		}
		return returnValue != 0;
	}

	/**
     * @dev Payable receive function to receive Ether from oldVault when migrating
     */
	receive() external payable {}
}