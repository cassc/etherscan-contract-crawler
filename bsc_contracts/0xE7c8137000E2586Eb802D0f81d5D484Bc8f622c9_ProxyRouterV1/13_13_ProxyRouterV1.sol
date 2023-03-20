// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract ProxyRouterV1 is Initializable, UUPSUpgradeable, PausableUpgradeable, OwnableUpgradeable {
	/**
	 * @dev Define settings struct
	 */
	struct Settings {
		address aggregationRouterV5;
		address aggregationRouterV4;
		address nativeAddress;
		uint256 fee;
		uint256 campaignPercentage;
		bool campaignStatus;
		bool referralStatus;
	}

	/**
	 * @dev Define swap description
	 */
	struct SwapDescription {
		address srcToken;
		address dstToken;
		address srcReceiver;
		address dstReceiver;
		uint256 amount;
		uint256 minReturnAmount;
		uint256 flags;
	}

	/**
	 * @dev Define referral description
	 */
	struct ReferralStr {
		address payable to;
		uint256 percentage;
	}

	/**
	 * @dev Emitted when swap is sussesfull
	 */
	event Swap(
		address indexed srcReceiver,
		address indexed dstReceiver,
		address srcToken,
		address dstToken,
		address router,
		uint256 amount,
		uint256 returnAmount,
		uint256 feePercent,
		uint256 feeAmount
	);

	/**
	 * @dev Emitted when Referral is sussesfull
	 */
	event Referral(address indexed refAddress, uint256 refAmount, uint256 refPercent);

	/**
	 * @dev Emitted when Transfer is sussesfull
	 */
	event Transfer(address token, address receiver, uint256 amount);

	/**
	 * @dev Emitted when Transfer with Swap is sussesfull
	 */
	event TransferWithSwap(
		address indexed srcReceiver,
		address indexed dstReceiver,
		address srcToken,
		address dstToken,
		address router,
		uint256 amount,
		uint256 returnAmount
	);

	/**
	 * @dev Emitted when Reward is sussesfull
	 */
	event Reward(
		address indexed srcReceiver,
		address indexed dstReceiver,
		address srcToken,
		address dstToken,
		address router,
		uint256 amount,
		uint256 returnAmount,
		uint256 campaignPercentage
	);

	/**
	 * @dev Define default settings
	 */
	Settings private defaultSettings;

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}

	/**
	 * @dev defines a initialize function that can be invoked at most once. In its scope,
	 */
	function initialize(uint256 _fee, uint256 _cmpPercentage, bool _refStatus, bool _cmpStatus) public initializer {
		// This code creates a structure called Settings and initializes it with the given values.
		defaultSettings = Settings(
			0x1111111254EEB25477B68fb85Ed929f73A960582,
			0xDef1C0ded9bec7F1a1670819833240f027b25EfF,
			0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE,
			_fee,
			_cmpPercentage,
			_cmpStatus,
			_refStatus
		);

		__Pausable_init();
		__Ownable_init();
		__UUPSUpgradeable_init();
	}

	/**
	 * @dev This function is used to authorize upgrade to a new contract implementation by only the contract owner.
	 */
	function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

	/**
	 * @dev This function is used to pause the contract functionality by only the contract owner.
	 */
	function pause() public onlyOwner {
		_pause();
	}

	/**
	 * @dev This function is used to resume the contract functionality after pausing it by only the contract owner.
	 */
	function unpause() public onlyOwner {
		_unpause();
	}

	/**
	 * @dev Function to receive Native coin. msg.data must be empty
	 */
	receive() external payable {}

	/**
	 * @dev Fallback function is called when msg.data is not empty
	 */
	fallback() external payable {}

	/**
	 * @dev swap function
	 */
	function swap(
		bytes calldata _data,
		bytes calldata _reward,
		ReferralStr calldata _referral,
		uint256 _amount,
		uint8 _version
	) external payable {
		uint256 feeAmount;
		uint256 finalAmount;
		bytes memory result;
		bool succ;

		(, SwapDescription memory desc, , ) = abi.decode(_data[4:], (address, SwapDescription, bytes, bytes));

		require(_amount > 0 && desc.amount > 0 && _amount > desc.amount, "Invalid arguments (amount)");

		(feeAmount, finalAmount) = _calculateFee(_amount, desc.amount);

		address aggregator = _version == 4 ? defaultSettings.aggregationRouterV4 : defaultSettings.aggregationRouterV5;

		if (desc.srcToken == defaultSettings.nativeAddress) {
			require(msg.value == _amount, "value is incorrect!");

			(succ, result) = aggregator.call{ value: finalAmount }(_data);
		} else {
			IERC20Upgradeable srcToken = IERC20Upgradeable(desc.srcToken);

			require(srcToken.transferFrom(msg.sender, address(this), _amount), "The transfer has an error!");

			require(srcToken.approve(aggregator, finalAmount), "The approve has an error!");

			(succ, result) = aggregator.call(_data);
		}

		require(succ, "An error has occurred!");

		(uint256 returnAmount, ) = abi.decode(result, (uint256, uint256));

		emit Swap(
			desc.srcReceiver,
			desc.dstReceiver,
			desc.srcToken,
			desc.dstToken,
			aggregator,
			_amount,
			returnAmount,
			defaultSettings.fee,
			feeAmount
		);

		// send some value to referral
		if (defaultSettings.referralStatus) _calculateRefferal(feeAmount, _referral, desc.srcToken);

		// send reward to users
		if (defaultSettings.campaignStatus) _campaignProcessing(_reward, feeAmount, _version);
	}

	/**
	 * @dev Calculate the percentage of referral users
	 */
	function _calculateRefferal(uint256 _amount, ReferralStr calldata _referral, address _token) private {
		// Check referral percentage
		if (_referral.percentage == 0 || _referral.percentage > 5000) return;

		uint256 referralAmount = (_amount * _referral.percentage) / 10000;

		if (_transfer(_token, _referral.to, referralAmount)) {
			emit Referral(_referral.to, referralAmount, _referral.percentage);
		}
	}

	/**
	 * @dev Calculation of system fee
	 */
	function _calculateFee(
		uint256 _amount,
		uint256 _descAmount
	) private view returns (uint256 feeAmount, uint256 finalAmount) {
		unchecked {
			// Calculate fee amount
			feeAmount = (_amount * defaultSettings.fee) / 10000;

			// Calculate Final Amount for swap
			finalAmount = _amount - feeAmount;
		}

		require(finalAmount == _descAmount, "The value is not correct");

		return (feeAmount, finalAmount);
	}

	/**
	 * @dev Set new system fee
	 * This fee will be minimum 0 and maximum 3%
	 * Default 0.3% = 0.3 * 10**2 => 30
	 * Maximum 3% = 3 * 10**2 => 300
	 */
	function setFee(uint256 _fee) public onlyOwner returns (bool) {
		// check fee is Less equal to 3%
		require(_fee <= 300, "The maximum fee is 3%");

		// Set new fee
		defaultSettings.fee = _fee;

		return true;
	}

	/**
	 * @dev Get currenf system fee
	 * Divide it by 100 to get the fee percentage.
	 */
	function getFee() public view returns (uint256) {
		return defaultSettings.fee;
	}

	/**
	 * @dev Set referral status
	 */
	function setReferral(bool _status) public onlyOwner returns (bool) {
		// Set new status
		defaultSettings.referralStatus = _status;

		return true;
	}

	/**
	 * @dev Get currenf referral status
	 */
	function getReferral() public view returns (bool) {
		return defaultSettings.referralStatus;
	}

	/**
	 * @dev Change campaign status
	 */
	function setCampaign(bool _status, uint256 _percentage) public onlyOwner returns (bool) {
		defaultSettings.campaignStatus = _status;

		defaultSettings.campaignPercentage = _percentage;

		return true;
	}

	/**
	 * @dev Get campaign status
	 */
	function getCampaign() public view returns (bool, uint256) {
		return (defaultSettings.campaignStatus, defaultSettings.campaignPercentage);
	}

	/**
	 * @dev Processing campaigns and sending rewards to user wallet
	 */
	function _campaignProcessing(bytes calldata _data, uint256 _feeAmount, uint8 _version) private returns (bool) {
		if (_data.length == 0) return false;

		(, SwapDescription memory desc, , ) = abi.decode(_data[4:], (address, SwapDescription, bytes, bytes));

		uint256 amount;
		unchecked {
			amount = (_feeAmount * defaultSettings.campaignPercentage) / 10000;
		}

		if (desc.amount != amount) return false;

		(bool status, uint256 returnAmount, address aggregator) = _transferAndSwap(
			desc.srcToken,
			amount,
			_data,
			false,
			_version
		);

		if (!status) return false;

		// emit Reward(address indexed receiver, address srcToken, address dstToken, uint256 amount, uint256 returnAmount);
		emit Reward(
			desc.srcReceiver,
			desc.dstReceiver,
			desc.srcToken,
			desc.dstToken,
			aggregator,
			amount,
			returnAmount,
			defaultSettings.campaignPercentage
		);

		return true;
	}

	/**
	 * @dev Transfer token from contract to receiver address
	 */
	function withdraw(address _token, address payable _receiver, uint256 _amount) external onlyOwner returns (bool) {
		require(_amount > 0, "The amount is zero!");

		require(_transfer(_token, _receiver, _amount), "An error has occurred!");

		emit Transfer(_token, _receiver, _amount);

		return true;
	}

	/**
	 * @dev Swap token from contract
	 */
	function withdrawWithSwap(bytes calldata _data, uint8 _version) external onlyOwner returns (bool) {
		(, SwapDescription memory desc, , ) = abi.decode(_data[4:], (address, SwapDescription, bytes, bytes));

		(, uint256 returnAmount, address aggregator) = _transferAndSwap(
			desc.srcToken,
			desc.amount,
			_data,
			true,
			_version
		);

		emit TransferWithSwap(
			desc.srcReceiver,
			desc.dstReceiver,
			desc.srcToken,
			desc.dstToken,
			aggregator,
			desc.amount,
			returnAmount
		);

		return true;
	}

	/**
	 * Transfer token amount to address
	 */
	function _transfer(address _token, address payable _receiver, uint256 _amount) private returns (bool status) {
		// Send amount to address
		if (_token == defaultSettings.nativeAddress) (status, ) = _receiver.call{ value: _amount }("");
		else status = IERC20Upgradeable(_token).transfer(_receiver, _amount);

		return status;
	}

	/**
	 * Transfer And Call token to aggregation router
	 */
	function _transferAndSwap(
		address _srcToken,
		uint256 _amount,
		bytes calldata _data,
		bool _throw,
		uint8 _version
	) private returns (bool, uint256, address) {
		bytes memory result;
		bool succ;

		address aggregator = _version == 4 ? defaultSettings.aggregationRouterV4 : defaultSettings.aggregationRouterV5;

		if (_srcToken == defaultSettings.nativeAddress) {
			(succ, result) = aggregator.call{ value: _amount }(_data);
		} else {
			IERC20Upgradeable srcToken = IERC20Upgradeable(_srcToken);

			bool status = srcToken.approve(aggregator, _amount);

			if (!status) {
				if (_throw) revert("The approve has an error!");
				else return (false, 0, address(0));
			}

			(succ, result) = aggregator.call(_data);
		}

		if (!succ) {
			if (_throw) revert("An error has occurred!");
			else return (false, 0, address(0));
		}

		(uint256 returnAmount, ) = abi.decode(result, (uint256, uint256));

		return (true, returnAmount, aggregator);
	}
}