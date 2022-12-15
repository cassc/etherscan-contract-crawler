// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ICurvePool.sol";
import "../interfaces/IFeeDistributor.sol";
import "../interfaces/ISdFraxVault.sol";
import "../interfaces/IUniswapRouter.sol";

contract VeSDTFeeCurveProxyV2 is Ownable {
	using SafeERC20 for IERC20;

	address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant USDC_FRAX_CURVE_POOL = 0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2;
	address public constant FEE_D = 0x29f3dd38dB24d3935CF1bf841e6b2B461A3E5D92;
	address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
	address public constant FRAX_3CRV = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
	address public constant SD_FRAX_3CRV = 0x5af15DA84A4a6EDf2d9FA6720De921E1026E37b7;
    address public constant SUSHI_ROUTER = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
	
	uint256 public constant BASE_FEE = 10000;
    uint256 public claimerFee = 100;
    address[] public crvToUsdcPath;

	constructor(
        address[] memory _crvToUsdcPath
    ) {
        crvToUsdcPath = _crvToUsdcPath;
        require(crvToUsdcPath[0] == CRV, "!crv");
        require(crvToUsdcPath[crvToUsdcPath.length - 1] == USDC, "!usdc");
        IERC20(CRV).safeApprove(SUSHI_ROUTER, type(uint256).max);
        IERC20(USDC).safeApprove(USDC_FRAX_CURVE_POOL, type(uint256).max);
	}

    /// @notice function to send reward
	function sendRewards() external {
		uint256 crvBalance = IERC20(CRV).balanceOf(address(this));
        if (crvBalance != 0) {
            // swap CRV <-> USDC on sushiswap
            _swapOnSushi(crvBalance);
            uint256 usdcBalance = IERC20(USDC).balanceOf(address(this));
            //require(usdcBalance > 0, "zero usdc");
            // swap USDC <-> FRAX on curve
            _swapOnCurve(usdcBalance);
		    uint256 fraxBalance = IERC20(FRAX).balanceOf(address(this));
		    uint256 claimerPart = (fraxBalance * claimerFee) / BASE_FEE;
		    IERC20(FRAX).transfer(msg.sender, claimerPart);
		    IERC20(FRAX).approve(FRAX_3CRV, fraxBalance - claimerPart);
		    ICurvePool(FRAX_3CRV).add_liquidity([fraxBalance - claimerPart, 0], 0);
		    uint256 frax3CrvBalance = IERC20(FRAX_3CRV).balanceOf(address(this));
		    IERC20(FRAX_3CRV).approve(SD_FRAX_3CRV, fraxBalance - claimerPart);
		    ISdFraxVault(SD_FRAX_3CRV).deposit(frax3CrvBalance);
		    IERC20(SD_FRAX_3CRV).transfer(FEE_D, IERC20(SD_FRAX_3CRV).balanceOf(address(this)));
        } 
	}

    /// @notice internal function to swap  to agEUR on sushi
	/// @dev slippageCRV = 100 for 1% max slippage
	/// @param _amount amount to swap
	function _swapOnSushi(uint256 _amount) internal {
		IUniswapRouter(SUSHI_ROUTER).swapExactTokensForTokens(
			_amount,
			0,
			crvToUsdcPath,
			address(this),
			block.timestamp + 1800
		);
	}

    /// @notice internal function to swap CRV to FRAX on curve
	/// @param _amount amount to swap
    function _swapOnCurve(uint256 _amount) internal {
        ICurvePool(USDC_FRAX_CURVE_POOL).exchange(
            1,
            0,
            _amount,
            0
        );
    }

    /// @notice function to calculate the amount reserved for keepers
	function claimableByKeeper() public view returns (uint256) {
		uint256 crvBalance = IERC20(CRV).balanceOf(address(this));
		if (crvBalance == 0) {
			return 0;
		}
		uint256[] memory amounts = IUniswapRouter(SUSHI_ROUTER).getAmountsOut(crvBalance, crvToUsdcPath);

        uint256 fraxAmount = ICurvePool(USDC_FRAX_CURVE_POOL).get_dy(
            1, 
            0, 
            amounts[crvToUsdcPath.length - 1]
        );
		return (fraxAmount * claimerFee) / BASE_FEE;
	}

    /// @notice function to set a new claimer fee 
	/// @param _claimerFee claimer fee
	function setClaimerFee(uint256 _claimerFee) external onlyOwner {
        require(_claimerFee <= BASE_FEE, ">100%");
		claimerFee = _claimerFee;
	}

    /// @notice function to set the sushiswap Crv <-> Usdc swap path  (CRV <-> .. <-> USDC)
	/// @param _path swap path
	function setCrvUsdcPathOnSushi(address[] calldata _path) external onlyOwner {
        require(_path[0] == CRV, "wrong initial pair");
        require(_path[_path.length - 1] == USDC, "wrong final pair");
		crvToUsdcPath = _path;
	}
    
    /// @notice function to recover any ERC20 and send them to the owner
	/// @param _token token address
	/// @param _amount amount to recover
	function recoverERC20(address _token, uint256 _amount) external onlyOwner {
		IERC20(_token).transfer(owner(), _amount);
	}
}