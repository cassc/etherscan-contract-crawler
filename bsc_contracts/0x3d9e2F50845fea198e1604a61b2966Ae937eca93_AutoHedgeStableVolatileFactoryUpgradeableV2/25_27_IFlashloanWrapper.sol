pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IBentoBox.sol";

enum FlashloanType {
	Deposit,
	Withdraw
}

interface IFlashloanWrapper {
	event Flashloan(
		address indexed receiver,
		IERC20 token,
		uint256 amount,
		uint256 fee,
		uint256 loanType
	);

	event FlashloanRepaid(address indexed to, uint256 amount);

	struct FinishRoute {
		address flwCaller;
		address target;
	}

	function takeOutFlashLoan(
		IERC20 token,
		uint256 amount,
		bytes calldata data
	) external;

	function repayFlashLoan(IERC20 token, uint256 amount) external;

	function getFeeFactor() external view returns (uint256);

	function sushiBentoBox() external view returns (IBentoBox);

	function FLASH_LOAN_FEE() external view returns (uint256);

	function FLASH_LOAN_FEE_PRECISION() external view returns (uint256);
}