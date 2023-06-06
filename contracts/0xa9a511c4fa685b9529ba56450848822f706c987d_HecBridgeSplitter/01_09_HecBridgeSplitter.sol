// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol';

interface IOwnableUpgradeable {
	function owner() external view returns (address);

	function renounceManagement() external;

	function pushManagement(address newOwner_) external;

	function pullManagement() external;
}

abstract contract OwnableUpgradeable is IOwnableUpgradeable, Initializable, ContextUpgradeable {
	address internal _owner;
	address internal _newOwner;

	event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
	event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	function __Ownable_init() internal onlyInitializing {
		__Ownable_init_unchained();
	}

	function __Ownable_init_unchained() internal onlyInitializing {
		_owner = msg.sender;
		emit OwnershipPushed(address(0), _owner);
	}

	function owner() public view override returns (address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(_owner == msg.sender, 'Ownable: caller is not the owner');
		_;
	}

	function renounceManagement() public virtual override onlyOwner {
		emit OwnershipPushed(_owner, address(0));
		_owner = address(0);
	}

	function pushManagement(address newOwner_) public virtual override {
		require(newOwner_ != address(0), 'Ownable: new owner is the zero address');
		emit OwnershipPushed(_owner, newOwner_);
		_newOwner = newOwner_;
	}

	function pullManagement() public virtual override {
		require(msg.sender == _newOwner, 'Ownable: must be new owner to pull');
		emit OwnershipPulled(_owner, _newOwner);
		_owner = _newOwner;
	}

	/**
	 * @dev This empty reserved space is put in place to allow future versions to add new
	 * variables without shifting down storage in the inheritance chain.
	 * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	 */
	uint256[49] private __gap;
}

/**
 * @title HecBridgeSplitter
 */
contract HecBridgeSplitter is OwnableUpgradeable, PausableUpgradeable {
	using SafeMathUpgradeable for uint256;
	using SafeERC20Upgradeable for IERC20Upgradeable;

	address public LiFiBridge;
	uint256 public CountDest; // Count of the destination wallets
	uint public minFeePercentage;
	address public DAO;
	string public version;

	// Struct Asset Info
	struct SendingAssetInfo {
		address sendingAssetId;
		uint256 sendingAmount;
		uint256 totalAmount;
		uint feePercentage;
	}

	/* ======== INITIALIZATION ======== */

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}

	/**
	 * @dev sets initials
	 */
	function initialize(uint256 _CountDest, address _bridge) external initializer {
		LiFiBridge = _bridge;
		CountDest = _CountDest;
		__Ownable_init();
		__Pausable_init();
	}

	///////////////////////////////////////////////////////
	//               USER CALLED FUNCTIONS               //
	///////////////////////////////////////////////////////

	/// @notice Performs a swap before bridging via HECTOR Bridge Splitter
	/// @param sendingAssetInfos Array Data used purely for sending assets
	/// @param fees Amounts of native coin amounts for bridge
	/// @param callDatas CallDatas from lifi sdk
	/// @param useSquid use Squid or Lifi
	/// @param squidTargetAddress use in executing squid bridge contract
	function Bridge(
		SendingAssetInfo[] memory sendingAssetInfos,
		uint256[] memory fees,
		bytes[] memory callDatas,
		bool useSquid,
		address squidTargetAddress
	) external payable {
		require(
			sendingAssetInfos.length > 0 &&
				sendingAssetInfos.length <= CountDest &&
				sendingAssetInfos.length == callDatas.length,
			'Splitter: bridge or swap call data is invalid'
		);
		require(
			(useSquid && squidTargetAddress != address(0)) ||
				(!useSquid && squidTargetAddress == address(0)),
			'Splitter: squid router is invalid'
		);

		address callTargetAddress = useSquid ? squidTargetAddress : LiFiBridge;
		for (uint256 i = 0; i < sendingAssetInfos.length; i++) {
			require(
				sendingAssetInfos[i].feePercentage >= minFeePercentage,
				'Spltter: invalid asset info'
			);

			if (sendingAssetInfos[i].sendingAssetId != address(0)) {
				IERC20Upgradeable srcToken = IERC20Upgradeable(sendingAssetInfos[i].sendingAssetId);

				require(
					srcToken.allowance(msg.sender, address(this)) > 0,
					'ERC20: transfer amount exceeds allowance'
				);

				uint256 calcBridgeAmount = sendingAssetInfos[i].sendingAmount;

				srcToken.safeTransferFrom(msg.sender, address(this), sendingAssetInfos[i].totalAmount);
				srcToken.approve(callTargetAddress, calcBridgeAmount);
			}

			if (msg.value > 0 && fees.length > 0 && fees[i] > 0) {
				(bool success, ) = payable(callTargetAddress).call{value: fees[i]}(callDatas[i]);
				require(success, 'Splitter: bridge swap transaction was failed');
				emit CallData(success, callDatas[i]);
			} else {
				(bool success, ) = payable(callTargetAddress).call(callDatas[i]);
				require(success, 'Splitter: bridge swap transaction was failed');
				emit CallData(success, callDatas[i]);
			}
			_takeFee(sendingAssetInfos[i]);
		}

		emit HectorBridge(msg.sender, sendingAssetInfos);
	}

	// Send Fee to DAO wallet
	function _takeFee(SendingAssetInfo memory sendingAssetInfo) internal returns (address, uint256) {
		uint256 feeAmount = (sendingAssetInfo.totalAmount * sendingAssetInfo.feePercentage) / 1000;
		if (sendingAssetInfo.sendingAssetId != address(0)) {
			IERC20Upgradeable token = IERC20Upgradeable(sendingAssetInfo.sendingAssetId);
			feeAmount = token.balanceOf(address(this)) < feeAmount
				? token.balanceOf(address(this))
				: feeAmount;
			token.safeTransferFrom(address(this), DAO, feeAmount);
			return (sendingAssetInfo.sendingAssetId, feeAmount);
		} else {
			feeAmount = address(this).balance < feeAmount ? address(this).balance : feeAmount;
			(bool success, ) = payable(DAO).call{value: feeAmount}('');
			require(success, 'Splitter: Fee has been taken successully');
			return (address(0), feeAmount);
		}
	}

	// Custom counts of detinations
	function setCountDest(uint256 _countDest) external onlyOwner {
		CountDest = _countDest;
		emit SetCountDest(_countDest);
	}

	// Set LiFiDiamond Address
	function setBridge(address _bridge) external onlyOwner {
		LiFiBridge = _bridge;
		emit SetBridge(_bridge);
	}

	// Set Minimum Fee Percentage
	function setMinFeePercentage(uint _feePercentage) external onlyOwner {
		minFeePercentage = _feePercentage;
		emit SetMinFeePercentage(_feePercentage);
	}

	// Set DAO wallet
	function setDAOWallet(address _daoWallet) external onlyOwner {
		DAO = _daoWallet;
		emit SetDAOWallet(_daoWallet);
	}

	// Set DAO wallet
	function setVersion(string memory _version) external onlyOwner {
		version = _version;
		emit SetVersion(_version);
	}

	// All events
	event SetCountDest(uint256 countDest);
	event SetMinFeePercentage(uint256 feePercentage);
	event SetBridge(address bridge);
	event SetDAOWallet(address daoWallet);
	event SetVersion(string _version);
	event CallData(bool success, bytes callData);
	event HectorBridge(address user, SendingAssetInfo[] sendingAssetInfos);
}