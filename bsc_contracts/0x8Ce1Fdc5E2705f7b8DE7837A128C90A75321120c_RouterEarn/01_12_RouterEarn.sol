// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IEarn.sol";
import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/Context.sol";
import "./libraries/Auth.sol";

contract RouterEarn is Context, Auth {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public percentReflection = 1500;
    uint256 public percentStaking = 3500;
    uint256 public percentFarming = 5000;
    uint256 public percentTaxDenominator = 10000;

    address public addressReflection;
    address public addressStaking;
    address public addressFarming;

    uint256 public pendingReflection = 0;
    uint256 public pendingFarming = 0;
    uint256 public pendingStaking = 0;

    uint public currentIndex = 1;

    constructor() Auth(msg.sender) {}

    function deposit(uint256 txAmount) external payable {
        uint256 baseAmount = msg.value;
        uint256 loop = 1;
        pendingReflection += getAmountPercent(baseAmount, percentReflection);
        pendingFarming += getAmountPercent(baseAmount, percentFarming);
        pendingStaking += getAmountPercent(baseAmount, percentStaking);
        if(currentIndex == 1){
            if(addressReflection != address(0)) {
                IEarn(addressReflection).deposit{value:pendingReflection}(loop);
                pendingReflection = 0;
                
            }
            currentIndex += 1;
        } else if(currentIndex == 2){
            if(addressStaking != address(0)) {
                IEarn(addressStaking).deposit{value:pendingStaking}(loop);
                pendingStaking = 0;
                
            }
            currentIndex += 1;
        } else {
            if(addressFarming != address(0)) {
                IEarn(addressFarming).deposit{value:pendingFarming}(loop);
                pendingFarming = 0;
                
            }
            currentIndex = 1;
        }
    }

    function distributeAll(uint256 loop) external {
        if(addressReflection != address(0)) {
            IEarn(addressReflection).deposit{value:pendingReflection}(loop);
            pendingReflection = 0;
        }
        if(addressStaking != address(0)) {
            IEarn(addressStaking).deposit{value:pendingStaking}(loop);
            pendingStaking = 0;
        }
        if(addressFarming != address(0)) {
            IEarn(addressFarming).deposit{value:pendingFarming}(loop);
            pendingFarming = 0;
        }
    }

    function getAmountPercent(uint256 baseAmount, uint256 taxAmount) internal view returns (uint256){
        return baseAmount.mul(taxAmount).div(percentTaxDenominator);
    }

    function claimWeth(address to, uint256 amount) external onlyOwner {
        payable(to).transfer(amount);
    }

    function claimFromContract(address _tokenAddress, address to, uint256 amount) external onlyOwner {
        IERC20(_tokenAddress).safeTransfer(to, amount);
    }

    function setPercent(uint256 reflection, uint256 staking, uint256 farming) external onlyOwner {
        percentReflection = reflection;
        percentStaking = staking;
        percentFarming = farming;
        require(percentReflection+percentFarming+percentStaking == percentTaxDenominator,"Total Percent Should Be 10000");
    }

    function setAddress(address reflection, address staking, address farming) external onlyOwner {
        addressReflection = reflection;
        addressStaking = staking;
        addressFarming = farming;
    }

}