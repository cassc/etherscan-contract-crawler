// SPDX-License-Identifier: None

pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

// STRUCTURES

/**
 * @notice Holds order information
 * @member inputToken kind provided
 * @member totalAmount amount provided
 * @member outputToken kind asked
 * @member outMin minimum amount asked
 * @member maxGasPrice maximum gas price accepted
 * @member feeAmount fee amount agreed
 * @member deadline order deadline
 * @member salt random additional input to make order unique
 */
struct Order {
	address inputToken;
	uint256 totalAmount;
	address outputToken;
	uint256 outMin;
	uint256 maxGasPrice;
	uint256 feeAmount;
	uint256 deadline;
	uint256 salt;
}

/**
 * @notice Holds quote information
 * @member spender approved to execute swap
 * @member swapTarget contract executing swap
 * @member sellAmount slice order sell amount
 * @member swapCallData custom swap data
 */
struct Quote {
	address spender;
	address swapTarget;
	uint256 sellAmount;
	bytes swapCallData;
}

/**
 * @title Contract executing sliced order
 * @notice This contract executes individual slices of the original order.
 * @dev Contract is Ownable, supports EIP712 and EIP1271 signing standard and uses SafeERC20 for token operations
 */
contract AnbotoExecV1 is Ownable, EIP712 {
	using SafeERC20 for IERC20;

	/**
	 * @notice Event emitted when access to functions is approved or unapproved
	 * @dev Raised when setAnboto is called
	 * @param anboto indexed approved address to use
	 * @param set true if approved, otherwise false
	 */
	event SetAnboto(address indexed anboto, bool set);

	/// @dev 21000 is base tx gas
	uint256 private constant BASE_TX_GAS = 21_000;
	/// @notice Represents one hundred percent value
	uint256 public constant FULL_PERCENT = 100_00;
	/// @notice Represents maximum fee allowed
	uint256 public constant MAX_FEE = 1_00;


	mapping(bytes => uint256) public orderFulfilledAmount;
	/// @notice Holds gas tank balance by sender for potential fees
	mapping(address => uint256) public gasTank;
	/// @notice Holds anboto approved addresses for call access control
	mapping(address => bool) public isAnboto;

	/// @notice Contract constructor setting contract domain name and version
	constructor() EIP712("AnbotoExecV1", "1") {}

	/**
	 * @notice Execute individual slice of the original order
	 * Each call executes next slice until order is fulfilled
	 * Original order specifications are honored
	 * Gas should be deposited beforehand by maker
	 * Gas can be withdrawn afterwards by maker
	 * Portion of gas will be reimbursed to Anboto
	 * Portion of the output will be held as fee
	 * Un-swapped portion of the input will be returned to maker
	 * @dev This function also tracks gas usage by maker
	 * Requirements:
	 * - should be called by owner or anboto approved
	 * - should be called before deadline
	 * - should be called within specified gas price limit
	 * - should be called within specified fee limit
	 * - should be called with input and output tokens that differ
	 * - should be signed by order maker and order must be unchanged
	 * - should be called at most total slices times
	 * @param order user order specification
	 * @param quote Anboto order execution specification
	 * @param maker order maker
	 * @param sig original order signature
	 */
	function executeOrder(
		Order calldata order,
		Quote calldata quote,
		address maker,
		bytes memory sig
	) external trackGas(maker) {
		// Guard clauses
		_verify(order, maker, sig);

		// add sell amount to cumulative amount of sold amounts
		orderFulfilledAmount[sig] += quote.sellAmount;
		// verify cumulative amount does not exceed the order total amount
		require(orderFulfilledAmount[sig] <= order.totalAmount, "AnbotoExecV1::executeOrder: Order total amount exceeded");

		IERC20 inToken = IERC20(order.inputToken);
		IERC20 outToken = IERC20(order.outputToken);

		// PREPARE Order
		// get current input amount - these are collected fees for the token
		uint256 inputBalanceBefore = inToken.balanceOf(address(this));

		// get current output token amount - these are collected fees for the token
		uint256 outputBalanceBefore = outToken.balanceOf(address(this));

		// transfer appropriate amount of input token from the user to the contract
		uint256 sliceInputAmount = quote.sellAmount;
		inToken.safeTransferFrom(maker, address(this), sliceInputAmount);

		// approve spender
		inToken.safeApprove(quote.spender, sliceInputAmount);

		// EXECUTE Order
		{
			(bool success, bytes memory data) = quote.swapTarget.call(quote.swapCallData);
			if (!success) revert(_getRevertMsg(data));
		}

		// SLIPPAGE IN: input token is already checked to be inside slice parameters
		// get current input token amount after order execution - this includes any not-swapped input and accumulated fees
		uint256 inputBalanceAfter = inToken.balanceOf(address(this));

		// if we have more input tokens then before, return the supplementary tokens to the maker and reduce the order fulfillment amount
		if (inputBalanceAfter > inputBalanceBefore) {
			uint256 supplementraryTokens = inputBalanceAfter - inputBalanceBefore;
			orderFulfilledAmount[sig] -= supplementraryTokens;
			sliceInputAmount -= supplementraryTokens;
			inToken.safeTransfer(maker, supplementraryTokens);
		} else if (inputBalanceAfter < inputBalanceBefore) {
			// if we have less input tokens than before, revert transaction as fees tokens were used
			revert("AnbotoExecV1::executeOrder: Too much input token spent");
		}

		// SLIPPAGE OUT: verify output token is inside slice parameters (slippage)
		// get current output token amount after order execution - this includes swapped output and accumulated fees so accumulated fees are subtracted
		uint256 outputAmount = outToken.balanceOf(address(this)) - outputBalanceBefore;
		// order specifies the ratio outMin/totalAmount
		uint256 sliceOutMin = (order.outMin * sliceInputAmount) / order.totalAmount;
		// if we have less output tokens then required by contract, revert the transaction
		require(outputAmount >= sliceOutMin, "AnbotoExecV1::executeOrder: Output amount too low");

		// remove spender approval
		inToken.safeApprove(quote.spender, 0);

		// FEE
		// collect fee
		uint256 feeAmount = order.feeAmount;
		uint256 fee = _getFee(outputAmount, feeAmount);

		// TRANSFER swapped output token to the user, subtracted by the fee (fee stays on the contracts)
		outToken.safeTransfer(maker, outputAmount - fee);
	}

	/**
	 * @notice This function verifies the caller and maker parameters
	 * @dev
	 * Requirements:
	 * - should be called by owner or anboto approved
	 * - should be called before deadline
	 * - should be called within specified gas price limit
	 * - should be called within specified fee limit
	 * - should be called with input and output tokens that differ
	 * - should be signed by order maker and order must be unchanged
	 * - should be called at most total slices times
	 * - maker should have enough gas in the tank
	 * @param order user order specification
	 * @param maker order maker
	 * @param sig original order signature
	 */
	function _verify(
		Order calldata order,
		address maker,
		bytes memory sig
	) internal view {
		// VERIFY ORDER PARAMETERS
		// should be called by owner or Anboto approved accounts
		require(msg.sender == owner() || isAnboto[msg.sender], "AnbotoExecV1::_verify: Caller not Anboto");
		// VERIFY ORDER PARAMETERS
		// should be called before deadline
		require(block.timestamp <= order.deadline, "AnbotoExecV1::_verify: Order deadline passed");
		// should be called within specified gas price limit
		require(tx.gasprice <= order.maxGasPrice, "AnbotoExecV1::_verify: Gas price too high");
		// should be called within specified fee limit
		require(order.feeAmount <= MAX_FEE, "AnbotoExecV1::_verify: Fee too high");
		// should be called with input and output tokens that differ
		require(order.inputToken != order.outputToken, "AnbotoExecV1::_verify: Input and output token must differ");
		// should be signed by order maker
		require(isValidSignature(order, maker, sig), "AnbotoExecV1::_verify: Signer and Maker do not match");
	}

	// SIGNATURE
	/// @notice Represents order structure hash
	bytes32 private constant ORDER_TYPEHASH =
		keccak256(
			"Order(address inputToken,address outputToken,uint256 totalAmount,uint256 outMin,uint256 maxGasPrice,uint256 feeAmount,uint256 deadline,uint256 salt)"
		);

	/**
	 * @notice This function checks the validity of provided order signature
	 * It uses EIP712 and EIP1271 standard library
	 * If the singer is not the contract maker, or any of the order specification has
	 * been modified from the moment order was signed, this will return false
	 * @param order user order specification
	 * @param signer order signer
	 * @param sig original order signature
	 * @return true if signature is valid
	 */
	function isValidSignature(
		Order calldata order,
		address signer,
		bytes memory sig
	) public view returns (bool) {
		bytes32 digest = _hashTypedDataV4(_hashOrder(order));
		return SignatureChecker.isValidSignatureNow(signer, digest, sig);
	}

	/**
	 * @notice This hashes order structure for the purpose of checking signature validity
	 * @param order user order specification
	 * @return typed Order hash
	 */
	function _hashOrder(Order calldata order) internal pure returns (bytes32) {
		return
			keccak256(
				abi.encode(
					ORDER_TYPEHASH,
					order.inputToken,
					order.outputToken,
					order.totalAmount,
					order.outMin,
					order.maxGasPrice,
					order.feeAmount,
					order.deadline,
					order.salt
				)
			);
	}

	// GAS TANK
	/**
	 * @notice Deposit Gas
	 * @dev This function stores sent value to sender gas tank
	 */
	receive() external payable {
		depositGas();
	}

	/**
	 * @notice Deposit Gas
	 * @dev This function stores sent value to sender gas tank
	 */
	function depositGas() public payable {
		gasTank[msg.sender] += msg.value;
	}

	/**
	 * @notice Withdraw Gas
	 * @dev This function withdraws specified amount from sender gas tank
	 * Requirements:
	 * - should be called with amount less or equal to stored gas
	 * @param amount gas amount to withdraw
	 */
	function withdrawGas(uint256 amount) external {
		require(gasTank[msg.sender] >= amount, "AnbotoExecV1::withdrawGas: Not enough gas");

		unchecked {
			gasTank[msg.sender] -= amount;
		}

		(bool success, bytes memory data) = payable(msg.sender).call{value: amount}("");
		if (!success) revert(_getRevertMsg(data));
	}

	// RESTRICTED FUNCTIONS

	/**
	 * @notice Claim Fees for specified tokens
	 * @dev This function transfers all of specified token fees to specified address
	 * Requirements:
	 * - should be called by owner
	 * - should be called with non-zero destination address
	 * @param tokens list of tokens to claim fees on
	 * @param claimTo destination address
	 */
	function claimFees(IERC20[] calldata tokens, address claimTo) external onlyOwner {
		// guard against zero addresses
		require(claimTo != address(0), "AnbotoExecV1::claimFees: Cannot claim to zero address");

		for (uint256 i = 0; i < tokens.length; i++) {
			tokens[i].transfer(claimTo, tokens[i].balanceOf(address(this)));
		}
	}

	/**
	 * @notice Enable or disable address `anboto` to call contract functions
	 * @dev This function approves or un-approves addresses to use the contract
	 * emits SetAnboto event
	 * Requirements:
	 * - should be called by the owner
	 * @param anboto address to approve or un-approve
	 * @param set true to enable, false to disable
	 */
	function setAnboto(address anboto, bool set) external onlyOwner {
		isAnboto[anboto] = set;
		emit SetAnboto(anboto, set);
	}

	// PRIVATE FUNCTIONS
	/**
	 * @notice Calculates fee to collect
	 * @param amount output amount
	 * @param fee fee percent
	 * @return Fee collected
	 */
	function _getFee(uint256 amount, uint256 fee) private pure returns (uint256) {
		return (amount * fee) / FULL_PERCENT;
	}

	/**
	 * @notice This function decodes transaction error message
	 * @param _returnData encoded error message
	 * @return Decoded revert message
	 */
	function _getRevertMsg(bytes memory _returnData) private pure returns (string memory) {
		// if the _res length is less than 68, then the transaction failed silently (without a revert message)
		if (_returnData.length < 68) return "AnbotoExecV1::_getRevertMsg: Transaction reverted silently";
		assembly {
			// slice the sig hash
			_returnData := add(_returnData, 0x04)
		}
		return abi.decode(_returnData, (string)); // all that remains is the revert string
	}

	// MODIFIERS
	/**
	 * @notice This modifier tracks gas usage and throws if not enough gas left.
	 * @dev Used gas is reimbursed from the maker to the Anboto.
	 * Requirements:
	 * - maker should have enough gas in the tank
	 * @param maker order maker
	 */
	modifier trackGas(address maker) {
		uint256 gas = gasleft();
		_;
		unchecked {
			uint256 gasUsed = gas + BASE_TX_GAS + (msg.data.length * 10) - gasleft();

			uint256 coinGasUsed = gasUsed * tx.gasprice;

			// guard against lack of gas
			require(gasTank[maker] >= coinGasUsed, "AnbotoExecV1::trackGas: Not enough gas in the tank");

			gasTank[maker] -= coinGasUsed;

			// return used gas to the transaction executor
			(bool success, bytes memory data) = payable(tx.origin).call{value: coinGasUsed}("");
			if (!success) revert(_getRevertMsg(data));
		}
	}
}