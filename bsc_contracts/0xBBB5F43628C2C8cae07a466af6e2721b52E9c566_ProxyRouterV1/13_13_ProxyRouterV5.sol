// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

library SafeMath {
	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return a - b;
	}

	/**
	 * @dev Returns the multiplication of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `*` operator.
	 *
	 * Requirements:
	 *
	 * - Multiplication cannot overflow.
	 */
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		return a * b;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers, reverting on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator.
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return a / b;
	}
}

contract ProxyRouterV1 is Initializable, UUPSUpgradeable, PausableUpgradeable, OwnableUpgradeable {
	// Aggregation router v5 address
	address private constant AGGREGATION_ROUTER_V5 = 0x1111111254EEB25477B68fb85Ed929f73A960582;

	address private constant NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

	// Define system fee
	uint256 private fee;

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}

	function initialize(uint256 _fee) public initializer {
		fee = _fee;

		__Pausable_init();
		__Ownable_init();
		__UUPSUpgradeable_init();
	}

	function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

	function pause() public onlyOwner {
		_pause();
	}

	function unpause() public onlyOwner {
		_unpause();
	}

	/**
	 * @dev Emitted when swap is sussesfull
	 */
	event Swap(
		address indexed sender,
		address indexed receiver,
		address srcToken,
		address dstToken,
		uint256 amount,
		uint256 returnAmount,
		uint256 feePercent,
		uint256 feeAmount
	);

	/**
	 * @dev Emitted when Referral is sussesfull
	 */
	event Referral(uint256 refPercent, uint256 refAmount, address indexed refAddress, bool refStatus);

	struct SwapDescription {
		address srcToken;
		address dstToken;
		address srcReceiver;
		address dstReceiver;
		uint256 amount;
		uint256 minReturnAmount;
		uint256 flags;
	}

	struct ReferralStr {
		address payable to;
		uint256 percentage;
	}

	// Function to receive Native coin. msg.data must be empty
	receive() external payable {}

	// Fallback function is called when msg.data is not empty
	fallback() external payable {}

	function swap(
		bytes calldata _data,
		ReferralStr memory referral,
		uint256 amount
	) external payable {
		(, SwapDescription memory desc, , ) = abi.decode(_data[4:], (address, SwapDescription, bytes, bytes));

		require(amount > 0, "amount must be > 0");

		require(desc.amount > 0, "desc.amount must be > 0");

		require(amount > desc.amount, "amount must be > desc.amount");

		(uint256 feeAmount, uint256 finalAmount) = calculateFee(amount, desc.amount);

		bytes memory result;
		bool succ;

		if (desc.srcToken == NATIVE_ADDRESS) {
			require(msg.value == amount, "value is incorrect!");

			(succ, result) = address(AGGREGATION_ROUTER_V5).call{ value: finalAmount }(_data);

			require(succ, "An error has occurred (NATIVE)!");
		} else {
			bool userApproveStatus = IERC20Upgradeable(desc.srcToken).approve(address(this), amount);

			require(userApproveStatus, "The user approve has an error!");

			bool transferStatus = IERC20Upgradeable(desc.srcToken).transferFrom(msg.sender, address(this), amount);

			require(transferStatus, "The transfer has an error!");

			bool approveStatus = IERC20Upgradeable(desc.srcToken).approve(AGGREGATION_ROUTER_V5, finalAmount);

			require(approveStatus, "The approve has an error!");

			(succ, result) = address(AGGREGATION_ROUTER_V5).call(_data);

			require(succ, "An error has occurred (ERC20)!");
		}

		(uint256 returnAmount, ) = abi.decode(result, (uint256, uint256));

		// send some value to referral
		(bool sent, uint256 referralAmount) = calculateRefferal(feeAmount, referral, desc.srcToken);

		emit Swap(msg.sender, desc.srcReceiver, desc.srcToken, desc.dstToken, amount, returnAmount, fee, feeAmount);

		if (sent) emit Referral(referral.percentage, referralAmount, referral.to, sent);
	}

	/**
	 * Calculate the percentage of referral users
	 */
	function calculateRefferal(
		uint256 amount,
		ReferralStr memory referral,
		address token
	) private returns (bool, uint256) {
		// Check max percentage is 50%
		if (referral.percentage > 5000) return (false, 0);

		if (referral.percentage == 0) return (false, 0);

		// Calculate fee amount
		uint256 referralAmount = SafeMath.div(SafeMath.mul(amount, referral.percentage), 10000);

		bool sent;
		// Send amount to referral user
		if (token == NATIVE_ADDRESS) (sent, ) = referral.to.call{ value: referralAmount }("");
		else sent = IERC20Upgradeable(token).transferFrom(address(this), referral.to, referralAmount);

		if (sent) return (true, referralAmount);

		return (false, 0);
	}

	/**
	 * @dev Calculation of system fee
	 */
	function calculateFee(uint256 amount, uint256 descAmount) private view returns (uint256, uint256) {
		// Calculate fee amount
		uint256 feeAmount = SafeMath.div(SafeMath.mul(amount, fee), 10000);

		// Calculate Final Amount for swap
		uint256 finalAmount = SafeMath.sub(amount, feeAmount);

		require(finalAmount == descAmount, "The value is not correct");

		return (feeAmount, finalAmount);
	}

	/**
	 * @dev Set new system fee
	 * This fee will be minimum 0 and maximum 3%
	 * Default 0.3% = 0.3 * 10**2 => 30
	 * Maximum 3% = 3 * 10**2 => 300
	 */
	function setFee(uint256 _fee) public onlyOwner returns (uint256) {
		// check fee is Less equal to 3%
		require(_fee <= 300, "The maximum fee is 3%");

		// Set new fee
		fee = _fee;

		return _fee;
	}

	/**
	 * @dev Get currenf system fee
	 * Divide it by 100 to get the fee percentage.
	 */
	function getFee() public view returns (uint256) {
		return fee;
	}

	/**
	 * Transfer system fee from contract to address
	 */
	function withdraw(
		address token,
		address payable receiver,
		uint256 amount
	) external onlyOwner returns (bool) {
		require(amount > 0, "The amount is zero!");

		bool sent;
		// Send amount to address
		if (token == NATIVE_ADDRESS) (sent, ) = receiver.call{ value: amount }("");
		else sent = IERC20Upgradeable(token).transferFrom(address(this), receiver, amount);

		return sent;
	}
}