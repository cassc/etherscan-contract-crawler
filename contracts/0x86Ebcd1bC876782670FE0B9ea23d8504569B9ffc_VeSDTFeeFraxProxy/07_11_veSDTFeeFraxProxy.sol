// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "../interfaces/IFeeDistributor.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ICurvePool.sol";
import "../interfaces/IUniswapRouter.sol";
import "../interfaces/ISdFraxVault.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VeSDTFeeFraxProxy is Ownable {
	using SafeERC20 for IERC20;

	address public constant SD_FRAX_3CRV = 0x5af15DA84A4a6EDf2d9FA6720De921E1026E37b7;
	address public constant FRAX_3CRV = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
	address public constant FXS = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;
	address public constant FEE_DISTRIBUTOR = 0x29f3dd38dB24d3935CF1bf841e6b2B461A3E5D92;
	address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
	address public constant SUSHI_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;

	uint256 public claimerFee = 100;
	uint256 public constant BASE_FEE = 10000;
	uint256 public maxSlippage = 100;
	address[] public fxsToFraxPath;

	constructor(address[] memory _fxsToFraxPath) {
		fxsToFraxPath = _fxsToFraxPath;
		IERC20(FXS).safeApprove(SUSHI_ROUTER, type(uint256).max);
	}

	/// @notice function to send reward
	function sendRewards() external {
		uint256 fxsBalance = IERC20(FXS).balanceOf(address(this));
		_swapOnSushi(fxsBalance);
		uint256 fraxBalance = IERC20(FRAX).balanceOf(address(this));
		uint256 claimerPart = (fraxBalance * claimerFee) / BASE_FEE;
		IERC20(FRAX).transfer(msg.sender, claimerPart);
		IERC20(FRAX).approve(FRAX_3CRV, fraxBalance - claimerPart);
		ICurvePool(FRAX_3CRV).add_liquidity([fraxBalance - claimerPart, 0], 0);
		uint256 frax3CrvBalance = IERC20(FRAX_3CRV).balanceOf(address(this));
		IERC20(FRAX_3CRV).approve(SD_FRAX_3CRV, fraxBalance - claimerPart);
		ISdFraxVault(SD_FRAX_3CRV).deposit(frax3CrvBalance);
		IERC20(SD_FRAX_3CRV).transfer(FEE_DISTRIBUTOR, IERC20(SD_FRAX_3CRV).balanceOf(address(this)));
	}

	/// @notice internal function to swap CRV to FRAX
	/// @dev slippageCRV = 100 for 1% max slippage
	/// @param _amount amount to swap
	function _swapOnSushi(uint256 _amount) internal returns (uint256) {
		uint256[] memory amounts = IUniswapRouter(SUSHI_ROUTER).getAmountsOut(_amount, fxsToFraxPath);

		uint256 minAmount = (amounts[fxsToFraxPath.length - 1] * (10000 - maxSlippage)) / (10000);

		uint256[] memory outputs = IUniswapRouter(SUSHI_ROUTER).swapExactTokensForTokens(
			_amount,
			minAmount,
			fxsToFraxPath,
			address(this),
			block.timestamp + 1800
		);

		return outputs[1];
	}

	/// @notice function to calculate the amount reserved for keepers
	function claimableByKeeper() public view returns (uint256) {
		uint256 fxsBalance = IERC20(FXS).balanceOf(address(this));
		uint256[] memory amounts = IUniswapRouter(SUSHI_ROUTER).getAmountsOut(fxsBalance, fxsToFraxPath);
		uint256 minAmount = (amounts[fxsToFraxPath.length - 1] * (10000 - maxSlippage)) / (10000);
		return (minAmount * claimerFee) / BASE_FEE;
	}

	/// @notice function to set a new max slippage
	/// @param _newSlippage new slippage to set
	function setSlippage(uint256 _newSlippage) external onlyOwner {
		maxSlippage = _newSlippage;
	}

    /// @notice function to set a new claier fee 
	/// @param _newClaimerFee claimer fee
	function setClaimerFe(uint256 _newClaimerFee) external onlyOwner {
		claimerFee = _newClaimerFee;
	}

    /// @notice function to set the sushiswap swap path  (FXS <-> .. <-> FRAX)
	/// @param _newPath swap path
	function setSwapPath(address[] memory _newPath) external onlyOwner {
		fxsToFraxPath = _newPath;
	}

    /// @notice function to recover any ERC20 and send them to the owner
	/// @param _token token address
	/// @param _amount amount to recover
	function recoverERC20(address _token, uint256 _amount) external onlyOwner {
		IERC20(_token).transfer(owner(), _amount);
	}
}