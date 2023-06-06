// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ISdFraxVault.sol";
import "../interfaces/ICurvePool.sol";
import "../interfaces/IFraxSwapRouter.sol";

interface IFraxLP {
    function getAmountOut(uint256 amount, address tokenIn) external view returns(uint256);
}

contract VeSDTFeePendleProxy is Ownable {
    using SafeERC20 for IERC20;

    error FEE_TOO_HIGH();

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant FEE_D = 0x29f3dd38dB24d3935CF1bf841e6b2B461A3E5D92;
    address public constant FRAX = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address public constant FRAX_3CRV = 0xd632f22692FaC7611d2AA1C0D552930D43CAEd3B;
    address public constant SD_FRAX_3CRV = 0x5af15DA84A4a6EDf2d9FA6720De921E1026E37b7;
    address public constant FRAX_SWAP_ROUTER = 0xC14d550632db8592D1243Edc8B95b0Ad06703867;
    address public constant WETH_FRAX_LP = 0x31351Bf3fba544863FBff44DDC27bA880916A199; 

    uint256 public constant BASE_FEE = 10_000;
    uint256 public claimerFee = 100;
    address[] public wethToFraxPath = new address[](2);

    constructor() {
        wethToFraxPath[0] = WETH;
        wethToFraxPath[1] = FRAX;
        IERC20(WETH).safeApprove(FRAX_SWAP_ROUTER, type(uint256).max);
    }

    /// @notice function to send reward
    /// @param _amountOutMin min amount to receive
    function sendRewards(uint256 _amountOutMin) external {
        uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
        if (wethBalance != 0) {
            // swap WETH <-> FRAX on frax swap
            _swapOnFrax(wethBalance, _amountOutMin);
            uint256 fraxBalance = IERC20(FRAX).balanceOf(address(this));
            uint256 claimerPart = (fraxBalance * claimerFee) / BASE_FEE;
            // send FRAX to the claimer
            IERC20(FRAX).transfer(msg.sender, claimerPart);
            IERC20(FRAX).approve(FRAX_3CRV, fraxBalance - claimerPart);
            // provide liquidity on frax3crv pool on curve
            ICurvePool(FRAX_3CRV).add_liquidity([fraxBalance - claimerPart, 0], 0);
            uint256 frax3CrvBalance = IERC20(FRAX_3CRV).balanceOf(address(this));
            IERC20(FRAX_3CRV).approve(SD_FRAX_3CRV, fraxBalance - claimerPart);
            // deposit curve LP on stake dao
            ISdFraxVault(SD_FRAX_3CRV).deposit(frax3CrvBalance);
            // send all sdfrax3crv to the veSDT fee distributor 
            IERC20(SD_FRAX_3CRV).transfer(FEE_D, IERC20(SD_FRAX_3CRV).balanceOf(address(this)));
        }
    }

    /// @notice internal function to swap Weth to Frax on frax swap
    /// @param _amount amount to swap
    /// @param _amountOutMin min amount to receive
    function _swapOnFrax(uint256 _amount, uint256 _amountOutMin) internal {
        // swap weth to frax
        IFraxSwapRouter(FRAX_SWAP_ROUTER).swapExactTokensForTokens(
            _amount, 
            _amountOutMin, 
            wethToFraxPath, 
            address(this), 
            block.timestamp + 1800
        );
    }

    /// @notice function to calculate the amount reserved for keepers
    function claimableByKeeper() public view returns (uint256) {
        uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
        if (wethBalance == 0) {
            return 0;
        }
        uint256 amount = IFraxLP(WETH_FRAX_LP).getAmountOut(wethBalance, WETH);
        return amount * claimerFee / BASE_FEE;
    }

    /// @notice function to set a new claimer fee
    /// @param _claimerFee claimer fee
    function setClaimerFee(uint256 _claimerFee) external onlyOwner {
        if (_claimerFee > BASE_FEE) revert FEE_TOO_HIGH();
        claimerFee = _claimerFee;
    }

    /// @notice function to recover any ERC20 and send them to the owner
    /// @param _token token address
    /// @param _amount amount to recover
    function recoverERC20(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(owner(), _amount);
    }
}