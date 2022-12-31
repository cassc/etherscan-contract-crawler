// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IAliumMulitichain.sol";
import "../interfaces/IEventLogger.sol";
import {Swap, EventData} from "../types/types.sol";
import "../RBAC.sol";
import "../abstractions/Multicall.sol";
import "../libs/ChainId.sol";
import "../FeeControl.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title PseudoAdapter - It makes accounting incoming exchange requests.
 */
contract PseudoAdapter is RBAC, Multicall, FeeControl {
	using SafeERC20 for IERC20;

	// Transaction details.
	struct SwapInput {
		address token; // ERC20 or Wrapped core token
		address tokenTo; // Swap to token
		address to;
		uint256 amount;
		uint256 toChainID;
		string details;
		uint256 aggregatorId;
		string swapType;
		uint256 totalFee;
		uint256 deadline;
	}

	bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
	bytes32 public constant SIGNATURE_SIGNER_ROLE = keccak256("SIGNATURE_SIGNER_ROLE");

	// Alium multichain contract.
	IAliumMulitichain public immutable aliumMultichain;
	// EIP721 domain separator.
	bytes32 public immutable DOMAIN_SEPARATOR;
	// EIP721 type hash.
	bytes32 public constant SWAP_TYPEHASH = keccak256("Swap(address token,address tokenTo,address to,uint256 amount,uint256 toChainID,string details,uint256 aggregatorId,string swapType,uint256 totalFee,uint256 deadline)");
	// User request counter.
	mapping(address => uint256) public nonces;

	constructor(
		IAliumMulitichain _aliumMultichain,
		address _admin
	) FeeControl(_admin) {
		aliumMultichain = _aliumMultichain;

		DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
				keccak256(bytes("PseudoAdapter")),
				keccak256(bytes("1.0.3")),
				ChainId.get(),
				address(this)
			)
		);
	}

	/**
     * @dev Method accept ETHER payments.
     * @param _data - transaction details.
     * @param _typedDataHash - getTypedDataHash with nonce + keccak256 hashed `_data`
     * @param _signedMessage - ethereum signed `_typedDataHash` message.
     * @param _signature - signature of the `_typedDataHash` message.
	 */
	function swapEth(SwapInput calldata _data, bytes32 _typedDataHash, bytes32 _signedMessage, bytes memory _signature)
		external
		payable
	{
		address recoveredAddress = ECDSA.recover(_signedMessage, _signature);

		require(recoveredAddress != address(0), "Encoding signature error");
		require(AccessControl.hasRole(SIGNATURE_SIGNER_ROLE, recoveredAddress), "Unknown signer");

		bytes32 typeDataHash = getTypedDataHash(_data, nonces[msg.sender]++);

		require(keccak256(abi.encodePacked(typeDataHash)) == _typedDataHash, "Invalid typed data hash");
		require(getEthSignedMessage(_typedDataHash) == _signedMessage, "Invalid exchange details");

		require(_data.deadline >= block.timestamp, 'Deadline expired');
		require(
			_data.toChainID != 0 &&
			_data.toChainID != ChainId.get(),
			"Invalid chain"
		);

		address vault = aliumMultichain.vault();
		require(vault != address(0), "Vault not set");

		if (treasury != address(0)) {
			require(msg.value == _data.totalFee + _data.amount, "Cant charge ether");
			Address.sendValue(treasury, _data.totalFee);
		} else {
			require(msg.value == _data.amount, "Cant charge ether");
		}

		Address.sendValue(payable(vault), _data.amount);
		_log(_data);
	}

	/**
     * @dev Method accept ERC20 token payments.
     * @param _data - transaction details.
     * @param _typedDataHash - getTypedDataHash with nonce + keccak256 hashed `_data`
     * @param _signedMessage - ethereum signed `_typedDataHash` message.
     * @param _signature - signature of the `_typedDataHash` message.
	 */
	function swapToken(SwapInput calldata _data, bytes32 _typedDataHash, bytes32 _signedMessage, bytes memory _signature)
		external
		payable
	{
		address recoveredAddress = ECDSA.recover(_signedMessage, _signature);

		require(recoveredAddress != address(0), "Encoding signature error");
		require(AccessControl.hasRole(SIGNATURE_SIGNER_ROLE, recoveredAddress), "Unknown signer");

		bytes32 typeDataHash = getTypedDataHash(_data, nonces[msg.sender]++);

		require(keccak256(abi.encodePacked(typeDataHash)) == _typedDataHash, "Invalid typed data hash");
		require(getEthSignedMessage(_typedDataHash) == _signedMessage, "Invalid exchange details");

		require(_data.deadline >= block.timestamp, 'Deadline expired');
		require(
			_data.toChainID != 0 &&
			_data.toChainID != ChainId.get(),
			"Invalid chain"
		);

		if (treasury != address(0)) {
			require(msg.value == _data.totalFee, "Cant charge ether");
			Address.sendValue(treasury, _data.totalFee);
		} else {
			require(msg.value == 0, "Ether payment");
		}

		address vault = aliumMultichain.vault();
		require(vault != address(0), "Vault not set");

		IERC20(_data.token).safeTransferFrom(msg.sender, vault, _data.amount);

		_log(_data);
	}

	// @dev Fee setter. Overridden for prevent percent fee set.
	function setFee(uint256 _fee) external override onlyRole(DEFAULT_ADMIN_ROLE) {
		revert("DISABLED");
	}

	// @dev Hash transaction details with user nonce.
	function hashStruct(SwapInput calldata _input, uint256 _nonce) public pure returns (bytes32 hash) {
		hash = keccak256(
			abi.encode(
				SWAP_TYPEHASH,
				_input.token,
				_input.tokenTo,
				_input.to,
				_input.amount,
				_input.toChainID,
				keccak256(abi.encodePacked(_input.details)),
				_input.aggregatorId,
				keccak256(abi.encodePacked(_input.swapType)),
				_input.totalFee,
				_input.deadline,
				_nonce
			)
		);
	}

	/**
	 * @dev Helper for signature recover check.
	 */
	function recover(bytes32 _signedMessage, bytes memory _signature) public pure returns (address signer) {
		signer = ECDSA.recover(_signedMessage, _signature);
	}

	/**
     * @dev Helper for encode data by EIP712.
	 */
	function getTypedDataHash(SwapInput calldata _input, uint256 _nonce) public view returns (bytes32 hash) {
		hash = ECDSA.toTypedDataHash(DOMAIN_SEPARATOR, hashStruct(_input, _nonce));
	}

	/**
     * @dev Helper for get ethereum signed message.
	 */
	function getEthSignedMessage(bytes32 _hash) public pure returns (bytes32 hash) {
		hash = ECDSA.toEthSignedMessageHash(_hash);
	}

	/**
     * @dev Log data on Alium multichain.
	 */
	function _log(SwapInput calldata _data) internal {
		(uint256 amount, ) = calcFee(_data.amount);
		uint256 nonce = aliumMultichain.applyNonce();
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
			swapType: _data.swapType,
			operator: address(this),
			exchangeId: nonce,
			aggregatorId: _data.aggregatorId,
			details: _data.details
		});
		IEventLogger(aliumMultichain.eventLogger()).log(eventData);
	}
}