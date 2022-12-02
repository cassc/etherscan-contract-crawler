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
	}

	using SafeERC20 for IERC20;

	IBentoBox public override sushiBentoBox;

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

	// function onFlashLoan(
	//     address sender,
	//     IERC20 token,
	//     uint256 amount,
	//     uint256 fee,
	//     bytes calldata data
	// ) external override {
	//     require(msg.sender == address(sushiBentoBox), "FLW: invalid caller");
	//     (FlashLoanTypes loanType, address ahLpContract) = abi.decode(
	//         data[:64],
	//         (FlashLoanTypes, address)
	//     );
	//     // Should just use a `isDeposit` bool instead, could remove this check
	//     require(
	//         loanType == FlashLoanTypes.Deposit ||
	//             loanType == FlashLoanTypes.Withdraw,
	//         "FLW: invalid loan type"
	//     );
	//     require(ahLpContract != address(0), "FLW: invalid call data");

	//     emit FlashLoan(ahLpContract, token, amount, fee, uint256(loanType));

	//     if (loanType == FlashLoanTypes.Deposit) {
	//         IAutoHedgeLeveragedPosition(ahLpContract).initiateDeposit(
	//             amount,
	//             fee,
	//             data
	//         );
	//     } else {
	//         IAutoHedgeLeveragedPosition(ahLpContract).initiateWithdraw(
	//             amount,
	//             fee,
	//             data
	//         );
	//     }
	// }

	function onFlashLoan(
		address sender,
		IERC20 token,
		uint256 amount,
		uint256 fee,
		bytes calldata data
	) external override {
		require(msg.sender == address(sushiBentoBox), "FLW: invalid caller");
		require(sender == address(this), "FLW: invalid sender");

		FinishRoute memory fr = abi.decode(data[68:132], (FinishRoute));
		fr.target.call(data);
	}

	function repayFlashLoan(IERC20 token, uint256 amount) external override {
		token.safeTransferFrom(msg.sender, address(sushiBentoBox), amount);
		// emit FlashLoanRepaid(address(sushiBentoBox), amount);
	}

	function _authorizeUpgrade(address) internal override onlyOwner {}
}