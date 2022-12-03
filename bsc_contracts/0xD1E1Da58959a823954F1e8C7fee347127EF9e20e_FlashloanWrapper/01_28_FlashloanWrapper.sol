pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "../interfaces/IFlashloanWrapper.sol";
import "../interfaces/IFinisher.sol";
import "../interfaces/IAutoHedgeLeveragedPosition.sol";

contract FlashloanWrapper is
	Initializable,
	UUPSUpgradeable,
	OwnableUpgradeable,
	IFlashloanWrapper,
	IFlashBorrower
{
	function initialize(address bentoBox_) external initializer {
		__Ownable_init_unchained();
		sushiBentoBox = IBentoBox(bentoBox_);
		FLASH_LOAN_FEE = 50;
		FLASH_LOAN_FEE_PRECISION = 1e5;
	}

	using SafeERC20 for IERC20;

	IBentoBox public override sushiBentoBox;

	uint256 public override FLASH_LOAN_FEE;
	uint256 public override FLASH_LOAN_FEE_PRECISION;

	// TODO: change to call sushi's bentobox directly as this is redundant call and make the
	// finishRoute.target to be FlashloanWrapper
	function takeOutFlashLoan(
		IERC20 token,
		uint256 amount,
		bytes calldata data
	) external override {
		// Guarantee that the 1st argument of the forwarded callData
		// is the caller of this fcn, first 4 bytes are function selector
		FinishRoute memory fr = abi.decode(data[68:132], (FinishRoute));
		require(fr.flwCaller == msg.sender, "FLW: invalid caller");

		sushiBentoBox.flashLoan(IFlashBorrower(address(this)), fr.target, token, amount, data);
	}

	function getFeeFactor() external view override returns (uint256) {
		return 0;
	}

	function onFlashLoan(
		address sender,
		IERC20 token,
		uint256 amount,
		uint256 fee,
		bytes calldata data
	) external override {
		require(msg.sender == address(sushiBentoBox), "FLW: invalid caller");
		require(sender == address(this), "FLW: invalid sender");

		bytes4 sig = bytes4(data[0:4]);

		uint256 segmentLength = (data.length - 4) / 32;

		bytes32[] memory dataList = new bytes32[](segmentLength);
		uint256 startIndex;

		for (uint256 index = 0; index < segmentLength; index++) {
			startIndex = index * 32 + 4;
			dataList[index] = bytes32(data[startIndex:(startIndex + 32)]);
		}

		dataList[segmentLength - 1] = bytes32(fee);
		bytes memory newData = abi.encodePacked(sig, dataList);

		FinishRoute memory fr = abi.decode(data[68:132], (FinishRoute));
		fr.target.call(newData);
	}

	function setFlashloanFee(uint256 fee, uint256 precision) external onlyOwner {
		require(fee < precision, "FLW: invalid fee");
		FLASH_LOAN_FEE = fee;
		FLASH_LOAN_FEE_PRECISION = precision;
	}

	function repayFlashLoan(IERC20 token, uint256 amount) external override {
		token.safeTransferFrom(msg.sender, address(sushiBentoBox), amount);
		// emit FlashLoanRepaid(address(sushiBentoBox), amount);
	}

	function _authorizeUpgrade(address) internal override onlyOwner {}
}