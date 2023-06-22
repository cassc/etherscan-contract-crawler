// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./PipelineProxy.sol";

/// @notice Used for entering the pool from any token(swap + enter pool)
/// @dev User can pass any CallParams, and call any arbitrary contract
contract Pipeline {
	using SafeERC20 for IERC20;

	struct CallParams {
		address inToken; // Address of token contract
		uint256 amount; // Amount of tokens
		address target; // Address of contract to be called
		bytes callData; // callData with wich `target` token would be called
	}

	struct CallParamsWithChunks {
		address inToken; // Address of token contract
		address target; // Address of contract to be called
		bytes[] callDataChunks; // CallParams without amount. Amount will be added between chunks
	}

	address public pipelineProxy; // User approve for this address. And we take user tokens from this address
	mapping(address => mapping(address => bool)) approved; // Contract => token => approved

	address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; 
	uint256 constant MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

	event PipelineProxyChanged(address indexed newPipelineProxy);

	constructor() {
		PipelineProxy proxy = new PipelineProxy(address(this));
		proxy.transferOwnership(msg.sender);
		pipelineProxy = address(proxy);
	}

	/// @dev call to swapper should swap tokens and transfer them to this contract
	///		 This function can call any other function. So contract should not have any assets, or they will be lost!!!
	/// @param swapData data to call swapper
	/// @param targetData data to call target
	/// @param distToken address of token that user will gain
	/// @param minAmount minimum amount of distToken that user will gain(revert if less)
	/// @param checkFinalBalance If true - send remaining distTokens from contract to caller
	function run(
		CallParams memory swapData,
		CallParamsWithChunks memory targetData,
		address distToken,
		uint256 minAmount,
		bool checkFinalBalance
	) external payable {
		require(swapData.target != pipelineProxy, "Swapper can't be PipelineProxy");
		require(targetData.target != pipelineProxy, "Target can't be PipelineProxy");

		uint256 amountBeforeSwap = getBalance(distToken, msg.sender);

		if (swapData.inToken != ETH_ADDRESS) {
			PipelineProxy(pipelineProxy).transfer(swapData.inToken, msg.sender, swapData.amount);
			approveIfNecessary(swapData.target, swapData.inToken);
		}

		(bool success,) = swapData.target.call{value: msg.value}(swapData.callData);
		require(success, "Can't swap");

		uint256 erc20Balance;
		uint256 ethBalance;

		if (targetData.inToken != ETH_ADDRESS) {
			erc20Balance = IERC20(targetData.inToken).balanceOf(address(this));
			require(erc20Balance > 0, "Zero token balance after swap");
			approveIfNecessary(targetData.target, targetData.inToken);
		} else {
			ethBalance = address(this).balance;
			require(ethBalance > 0, "Zero eth balance after swap");
		}

		(success,) = callFunctionUsingChunks(targetData.target, targetData.callDataChunks, erc20Balance, ethBalance);
		require(success, "Can't mint");

		uint256 distTokenAmount;

		if (checkFinalBalance) {
			if (distToken != ETH_ADDRESS) {
				distTokenAmount = IERC20(distToken).balanceOf(address(this));

				if (distTokenAmount > 0) {
					IERC20(distToken).safeTransfer(msg.sender, distTokenAmount);
				}
			} else {
				distTokenAmount = address(this).balance;

				if (distTokenAmount > 0) {
					(success, ) = payable(msg.sender).call{value: distTokenAmount}('');
					require(success, "Can't transfer eth");
				}
			}
		}

		uint256 amountAfterSwap = getBalance(distToken, msg.sender);
		require(amountAfterSwap - amountBeforeSwap >= minAmount, "Not enough token received");
	}

	/// @dev Same as zipIn, but have extra intermediate step
	///      Call to swapper should swap tokens and transfer them to this contract
	///		 This function can call any other function. So contract should not have any assets, or they will be lost!!!
	/// @param swapData data to call swapper
	/// @param poolData data to call pool
	/// @param targetData data to call target
	/// @param distToken address of token that user will gain
	/// @param minAmount minimum amount of distToken that user will gain(revert if less)
	/// @param checkFinalBalance If true - send remaining distTokens from contract to caller
	function runWithPool(
		CallParams memory swapData,
		CallParamsWithChunks memory poolData,
		CallParamsWithChunks memory targetData,
		address distToken,
		uint256 minAmount,
		bool checkFinalBalance
	) external payable {
		require(swapData.target != pipelineProxy, "Swap address can't be equal to PipelineProxy");
		require(poolData.target != pipelineProxy, "Pool address can't be equal to PipelineProxy");
		require(targetData.target != pipelineProxy, "Target address can't be equal to PipelineProxy");

		uint256 amountBeforeSwap = getBalance(distToken, msg.sender);

		if (swapData.inToken != ETH_ADDRESS) {
			PipelineProxy(pipelineProxy).transfer(swapData.inToken, msg.sender, swapData.amount);
			approveIfNecessary(swapData.target, swapData.inToken);
		}

		(bool success, ) = swapData.target.call{value: msg.value}(swapData.callData);
		require(success, "Can't swap");

		uint256 erc20Balance;
		uint256 ethBalance;

		if (poolData.inToken != ETH_ADDRESS) {
			erc20Balance = IERC20(poolData.inToken).balanceOf(address(this));
			require(erc20Balance > 0, "Zero token balance after swap");
			approveIfNecessary(poolData.target, poolData.inToken);
		} else {
			ethBalance = address(this).balance;
			require(ethBalance > 0, "Zero eth balance after swap");
		}

		(success, ) = callFunctionUsingChunks(poolData.target, poolData.callDataChunks, erc20Balance, ethBalance); 
		require(success, "Can't call pool");

		if (targetData.inToken != ETH_ADDRESS) {
			erc20Balance = IERC20(targetData.inToken).balanceOf(address(this));
			ethBalance = 0;
			require(erc20Balance > 0, "Zero token balance after pool");
			approveIfNecessary(targetData.target, targetData.inToken);
		} else {
			ethBalance = address(this).balance;
			require(ethBalance > 0, "Zero eth balance after pool");
		}

		(success, ) = callFunctionUsingChunks(targetData.target, targetData.callDataChunks, erc20Balance, ethBalance);
		require(success, "Can't mint");

		uint256 distTokenAmount;

		if (checkFinalBalance) {
			if (distToken != ETH_ADDRESS) {
				distTokenAmount = IERC20(distToken).balanceOf(address(this));

				if (distTokenAmount > 0) {
					IERC20(distToken).safeTransfer(msg.sender, distTokenAmount);
				}
			} else {
				distTokenAmount = address(this).balance;

				if (distTokenAmount > 0) {
					(success, ) = payable(msg.sender).call{value: distTokenAmount}('');
					require(success, "Can't transfer eth");
				}
			}
		}

		uint256 amountAfterSwap = getBalance(distToken, msg.sender);
		require(amountAfterSwap - amountBeforeSwap >= minAmount, "Not enough token received");
	}

	/// @dev Create CallParams using `packCallData` and call contract using it
	/// @param _contract Contract address to be called
	/// @param _chunks Chunks of call data without value paraeters. Value will be added between chunks 
	/// @param _value Value of word to which it will change 
	/// @param _ethValue How much ether we should send with call
	/// @return success - standart return from call
	/// @return result - standart return from call
	function callFunctionUsingChunks(
		address _contract,
		bytes[] memory _chunks,
		uint256 _value,
		uint256 _ethValue
	)
		internal
		returns (bool success, bytes memory result)
	{
		(success, result) = _contract.call{value: _ethValue}(packCallData(_chunks, _value));
	}

	/// @dev Approve infinite token approval to target if it hasn't done earlier 
	/// @param target Address for which we give approval
	/// @param token Token address
	function approveIfNecessary(address target, address token) internal {
		if (!approved[target][token]) {
			IERC20(token).safeApprove(target, MAX_INT);
			approved[target][token] = true;
		}
	}

	/// @dev Return eth balance if token == ETH_ADDRESS, and erc20 balance otherwise
	function getBalance(address token, address addr) internal view returns(uint256 res) {
		if (token == ETH_ADDRESS) {
			res = addr.balance;
		} else {
			res = IERC20(token).balanceOf(addr);
		}
	}


	/// @dev Create single bytes array by concatenation of chunks, using value as delimiter
	/// 	 Trying to do concatenation with one command, 
	///		 	but if num of chunks > 6, do it through many operations(not gas efficient) 
	/// @param _chunks Bytes chanks. Obtained by omitting value from callDat
	/// @param _value Number, that will be used as delimiter
	function packCallData(
		bytes[] memory _chunks, 
		uint256 _value
	) 
		internal 
		pure 
		returns(bytes memory callData) 
	{
        uint256 n = _chunks.length;

        if (n == 1) {
            callData = abi.encodePacked(_chunks[0]);
        } else if (n == 2) {
            callData = abi.encodePacked(_chunks[0], _value, _chunks[1]);
        } else if (n == 3) {
            callData = abi.encodePacked(_chunks[0], _value, _chunks[1], _value, _chunks[2]);
        } else if (n == 4) {
            callData = abi.encodePacked(_chunks[0], _value, _chunks[1], _value, _chunks[2], _value, _chunks[3]);
        } else if (n == 5) {
            callData = abi.encodePacked(
            	_chunks[0], _value, 
            	_chunks[1], _value, 
            	_chunks[2], _value, 
            	_chunks[3], _value, 
            	_chunks[4]
            );
        } else if (n == 6) {
            callData = abi.encodePacked(
            	_chunks[0], _value, 
            	_chunks[1], _value, 
            	_chunks[2], _value, 
            	_chunks[3], _value, 
            	_chunks[4], _value, 
            	_chunks[5]);
        } else {
            callData = packCallDataAny(_chunks, _value);
        }
    }

    /// @dev Do same as `packCallData`, but for arbitrary amount of chunks. Not gas efficient
    function packCallDataAny(
    	bytes[] memory _chunks, 
    	uint256 _value
    ) 
    	internal 
    	pure 
    	returns(bytes memory callData) 
    {
        uint i;

        for (i = 0; i < _chunks.length - 1; i++) {
            callData = abi.encodePacked(callData, _chunks[i], _value);
        }

        callData = abi.encodePacked(callData, _chunks[i]);
    }

	// We need this function for swap from token to ether
	receive() external payable {}
}