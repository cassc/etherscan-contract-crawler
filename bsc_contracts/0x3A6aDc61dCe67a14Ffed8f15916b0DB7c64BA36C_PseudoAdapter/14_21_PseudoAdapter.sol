// SPDX-License-Identifier: MIT

pragma solidity =0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAliumMulitichain.sol";
import "../interfaces/IEventLogger.sol";
import {Swap, EventData} from "../types/types.sol";
import "../RBAC.sol";
import "../abstractions/Multicall.sol";
import "../libs/ChainId.sol";
import "../FeeControl.sol";

contract PseudoAdapter is RBAC, Multicall, FeeControl {
	bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

	struct SwapInput {
		address token; // ERC20 or Wrapped core token
		address tokenTo; // Swap to token
		address to;
		uint amount;
		uint toChainID;
		string details;
	}

	uint256 public immutable aggregatorId;
	string public swapType;

	IAliumMulitichain public immutable aliumMultichain;

	constructor(
		IAliumMulitichain _aliumMultichain,
		address _admin,
		uint256 _aggregatorId,
		string memory _swapType
	) RBAC(_admin) {
		aliumMultichain = _aliumMultichain;
		aggregatorId = _aggregatorId;
		swapType = _swapType;
	}

	// TODO: add ecrecover + domain support
	function swapEth(SwapInput calldata _data)
		external
		payable
	{
		require(_data.token == address(0), "Only ether set");
		require(
			_data.toChainID != 0 &&
			_data.toChainID != ChainId.get(),
			"Invalid chain"
		);

		(, uint256 toFee) = calcFee(_data.amount);
		if (toFee != 0) {
			Address.sendValue(treasury, toFee);
		}
		address vault = aliumMultichain.vault();
		Address.sendValue(payable(vault), _data.amount - toFee);
		_log(_data);
	}

	function swapToken(SwapInput calldata _data)
		external
	{
		require(Address.isContract(_data.token), "Only token set");
		require(
			_data.toChainID != 0 &&
			_data.toChainID != ChainId.get(),
			"Invalid chain"
		);

		IERC20(_data.token).transferFrom(msg.sender, address(this), _data.amount);
		(, uint256 toFee) = calcFee(_data.amount);
		if (toFee != 0) {
			IERC20(_data.token).transfer(treasury, toFee);
		}
		address vault = aliumMultichain.vault();
		IERC20(_data.token).transfer(vault, _data.amount - toFee);
		_log(_data);
	}

	function _log(SwapInput calldata _data) internal {
		(uint256 amount, ) = calcFee(_data.amount);
		uint nonce = aliumMultichain.applyNonce();
		Swap memory swapDetails = Swap({
			operator: address(this),
			token: _data.token,
			from: msg.sender,
			to: _data.to,
			amount: amount,
			toChainID: _data.toChainID
		});
		aliumMultichain.applyTrade(nonce, swapDetails);
		EventData memory eventData = EventData({
			chains: [ChainId.get(), _data.toChainID],
			tokens: [_data.token, _data.tokenTo],
			parties: [msg.sender, _data.to],
			amountIn: amount,
			swapType: swapType,
			operator: address(this),
			exchangeId: nonce,
			aggregatorId: aggregatorId,
			details: _data.details
		});
		IEventLogger(aliumMultichain.eventLogger()).log(eventData);
	}
}