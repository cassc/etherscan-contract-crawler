// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "../interfaces/IHypervisor.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

contract AutoRebal {
    using SafeMath for uint256;

    address public admin;
    address public advisor;
    address public feeRecipient;
    IUniswapV3Pool public pool;
    IHypervisor public hypervisor;
    int24 public limitWidth = 1;

    modifier onlyAdvisor {
        require(msg.sender == advisor, "only advisor");
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "only admin");
        _;
    }

    constructor(address _admin, address _advisor, address _hypervisor) {
        require(_admin != address(0), "_admin should be non-zero");
        require(_advisor != address(0), "_advisor should be non-zero");
        require(_hypervisor != address(0), "_hypervisor should be non-zero");
        admin = _admin;
        advisor = _advisor;
        hypervisor = IHypervisor(_hypervisor);
    }

    function liquidityOptions() public view returns(bool, int24 currentTick) {

        (uint256 total0, uint256 total1) = hypervisor.getTotalAmounts();

        uint160 sqrtRatioX96;
        (sqrtRatioX96, currentTick, , , , , ) = hypervisor.pool().slot0();

        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(hypervisor.baseLower()),
            TickMath.getSqrtRatioAtTick(hypervisor.baseUpper()),
            total0,
            total1 
        );
  
        (uint256 amount0, uint256 amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtRatioX96,
            TickMath.getSqrtRatioAtTick(hypervisor.baseLower()),
            TickMath.getSqrtRatioAtTick(hypervisor.baseUpper()),
            liquidity
        );

        uint256 price = FullMath.mulDiv(uint256(sqrtRatioX96), (uint256(sqrtRatioX96)), 2**(96 * 2));
        return ((total0-amount0) * price > (total1-amount1), currentTick);

    }

    /// @param  outMin min amount0,1 returned for shares of liq 
    function autoRebalance(
        uint256[4] memory outMin
    ) external onlyAdvisor returns(int24 limitLower, int24 limitUpper) {
      
        (bool token0Limit, int24 currentTick) = liquidityOptions(); 

        if(!token0Limit) {
            // extra token1 in limit position = limit below
            limitUpper = (currentTick / hypervisor.tickSpacing()) * hypervisor.tickSpacing() - hypervisor.tickSpacing();
            if(limitUpper == currentTick) limitUpper = limitUpper - hypervisor.tickSpacing();

            limitLower = limitUpper - hypervisor.tickSpacing() * limitWidth; 
        }
        else {
            // extra token0 in limit position = limit above
            limitLower = (currentTick / hypervisor.tickSpacing()) * hypervisor.tickSpacing() + hypervisor.tickSpacing();
            if(limitLower == currentTick) limitLower = limitLower + hypervisor.tickSpacing();

            limitUpper = limitLower + hypervisor.tickSpacing() * limitWidth; 
        } 

        uint256[4] memory inMin;
        hypervisor.rebalance(
            hypervisor.baseLower(),
            hypervisor.baseUpper(),
            limitLower,
            limitUpper,
            feeRecipient,
            inMin,
            outMin 
        ); 
    }

    /// @notice compound pending fees 
    function compound() external onlyAdvisor returns(
        uint128 baseToken0Owed,
        uint128 baseToken1Owed,
        uint128 limitToken0Owed,
        uint128 limitToken1Owed,
        uint256[4] memory inMin
    ) {
        hypervisor.compound();
    }

    /// @param newAdmin New Admin Address
    function transferAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "newAdmin should be non-zero");
        admin = newAdmin;
    }

    /// @notice Transfer tokens to recipient from the contract
    /// @param token Address of token
    /// @param recipient Recipient Address
    function rescueERC20(IERC20 token, address recipient) external onlyAdmin {
        require(recipient != address(0), "recipient should be non-zero");
        require(token.transfer(recipient, token.balanceOf(address(this))));
    }

    /// @param _recipient fee recipient 
    function setRecipient(address _recipient) external onlyAdmin {
        require(feeRecipient == address(0), "fee recipient already set");
        feeRecipient = _recipient;
    }

}